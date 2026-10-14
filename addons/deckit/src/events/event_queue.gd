## Opt-in, synchronous resolution engine. Responders propose actions that must
## pass GameState.perform(). This is NOT a transaction or a gameplay turn stack.
class_name DeckitEventQueue extends RefCounted

signal event_queued(event: DeckitGameEvent)
signal event_processed(event: DeckitGameEvent, applied_actions: int, rejected_actions: int)
signal event_dropped(event: DeckitGameEvent)
signal event_cancelled(event: DeckitGameEvent)
signal response_limit_reached(event: DeckitGameEvent)

enum RejectionPolicy { CONTINUE, STOP_EVENT, STOP_DRAIN }

var max_pending_events: int = 256
var max_events_per_drain: int = 128
var max_actions_per_event: int = 32
## Maximum causal depth (root = 0). Guards responder-generated cascades.
var max_chain_depth: int = 8
## Suppress repeating event signatures within a single causal chain.
## Increase or disable with 0 when a game intentionally repeats an effect.
var max_similar_events_per_chain: int = 3
## A bounded in-memory diagnostic timeline. Set 0 to disable tracing.
var max_trace_entries: int = 128
var rejection_policy: RejectionPolicy = RejectionPolicy.CONTINUE

var _game: DeckitGameState
var _pending: Array[DeckitGameEvent] = []
var _responders: Array[DeckitEventResponder] = []
var _trace: Array[Dictionary] = []
var _busy: bool = false
var _stop_requested: bool = false
var _active_event: DeckitGameEvent
var _next_event_id: int = 1
var _next_chain_id: int = 1
## chain_id -> signature -> count. Pruned when the chain finishes.
var _chain_signatures: Dictionary = {}


## A queue is optional: no global hook is installed by default.
func bind(game: DeckitGameState) -> bool:
	if _busy:
		return false
	if _game == game:
		return game != null
	unbind()
	if game == null:
		return false
	_game = game
	_game.action_applied.connect(_on_applied)
	_game.action_rejected.connect(_on_rejected)
	return true


func unbind() -> void:
	if _busy:
		return
	if _game != null:
		if _game.action_applied.is_connected(_on_applied):
			_game.action_applied.disconnect(_on_applied)
		if _game.action_rejected.is_connected(_on_rejected):
			_game.action_rejected.disconnect(_on_rejected)
	_game = null


func register_responder(responder: DeckitEventResponder) -> bool:
	if _busy or responder == null or _responders.has(responder):
		return false
	_responders.append(responder)
	return true


func unregister_responder(responder: DeckitEventResponder) -> bool:
	if _busy or not _responders.has(responder):
		return false
	_responders.erase(responder)
	return true


func pending_count() -> int:
	return _pending.size()


func responder_count() -> int:
	return _responders.size()


## A copy: consumers cannot edit the resolver's stored history.
func get_trace() -> Array[Dictionary]:
	return _trace.duplicate(true)


func clear_trace() -> void:
	if not _busy:
		_trace.clear()


func clear_pending() -> void:
	if _busy:
		return
	while not _pending.is_empty():
		_cancel_at(_pending.size() - 1)


## Cancellation applies ONLY to unresolved events. It cannot undo actions.
func cancel_event(event_id: int) -> bool:
	if _busy or event_id <= 0:
		return false
	for index in range(_pending.size()):
		if _pending[index].event_id == event_id:
			_cancel_at(index)
			return true
	return false


func cancel_chain(chain_id: int) -> int:
	if _busy or chain_id <= 0:
		return 0
	var count: int = 0
	for index in range(_pending.size() - 1, -1, -1):
		if _pending[index].chain_id == chain_id:
			_cancel_at(index)
			count += 1
	return count


## Stop AFTER the current event; no cancellation/rollback of active actions.
func request_stop() -> void:
	if _busy:
		_stop_requested = true


## Higher event priority first, FIFO for equal priority.
## Reusing an event object is rejected: create a fresh notification.
func publish(event: DeckitGameEvent) -> bool:
	if event == null:
		return false
	if event.event_id != 0 or event.event_type == &"":
		_log(event, "dropped", "invalid_or_reused")
		event_dropped.emit(event)
		return false
	if _pending.size() >= maxi(1, max_pending_events):
		_log(event, "dropped", "queue_full")
		event_dropped.emit(event)
		return false

	var causal_chain: int = _next_chain_id
	var causal_depth: int = 0
	if _active_event != null:
		causal_chain = _active_event.chain_id
		causal_depth = _active_event.depth + 1
	if causal_depth > maxi(0, max_chain_depth):
		_log(event, "dropped", "chain_depth")
		event_dropped.emit(event)
		return false

	var signature: String = _signature(event)
	var counts: Dictionary = _chain_signatures.get(causal_chain, {})
	var previous_count: int = int(counts.get(signature, 0))
	if max_similar_events_per_chain > 0 and previous_count >= max_similar_events_per_chain:
		_log(event, "dropped", "cycle_guard")
		event_dropped.emit(event)
		return false

	event.event_id = _next_event_id
	_next_event_id += 1
	if _active_event == null:
		_next_chain_id += 1
	event.chain_id = causal_chain
	event.depth = causal_depth
	counts[signature] = previous_count + 1
	_chain_signatures[causal_chain] = counts
	_pending.append(event)
	_log(event, "queued", "")
	event_queued.emit(event)
	return true


func resolve_next() -> bool:
	if _busy or _game == null or _pending.is_empty():
		return false
	_busy = true
	_stop_requested = false
	_resolve_one()
	_busy = false
	return true


## Returns number of processed notifications. If a policy stops resolution,
## remaining events are available for a later drain() or explicit cancel().
func drain(maximum: int = 0) -> int:
	if _busy or _game == null:
		return 0
	_busy = true
	_stop_requested = false
	var budget: int = maxi(1, max_events_per_drain)
	if maximum > 0:
		budget = mini(budget, maximum)
	var processed: int = 0
	while processed < budget and not _pending.is_empty() and not _stop_requested:
		_resolve_one()
		processed += 1
	_busy = false
	return processed


func _resolve_one() -> void:
	var selected: int = 0
	for index in range(1, _pending.size()):
		if _pending[index].priority > _pending[selected].priority:
			selected = index
	var event: DeckitGameEvent = _pending[selected]
	_pending.remove_at(selected)
	_active_event = event

	var ordered: Array[DeckitEventResponder] = []
	for responder in _responders:
		var insert_at: int = ordered.size()
		for index in range(ordered.size()):
			if responder.priority > ordered[index].priority:
				insert_at = index
				break
		ordered.insert(insert_at, responder)

	var applied: int = 0
	var rejected: int = 0
	var attempted: int = 0
	var truncated: bool = false
	var stopped_on_rejection: bool = false
	var capacity: int = maxi(1, max_actions_per_event)
	for responder in ordered:
		if not responder.matches(event, _game):
			continue
		var actions: Array[DeckitCardAction] = responder.make_actions(event, _game)
		for action in actions:
			if attempted >= capacity:
				truncated = true
				break
			attempted += 1
			if action != null and _game.perform(action):
				applied += 1
			else:
				rejected += 1
				if rejection_policy != RejectionPolicy.CONTINUE:
					stopped_on_rejection = true
					if rejection_policy == RejectionPolicy.STOP_DRAIN:
						_stop_requested = true
					break
		if truncated or stopped_on_rejection:
			break

	if truncated:
		response_limit_reached.emit(event)
	var reason: String = ""
	if truncated:
		reason = "action_budget"
	elif stopped_on_rejection:
		reason = "rejected_response"
	_log(event, "processed", reason, applied, rejected)
	event_processed.emit(event, applied, rejected)
	_active_event = null
	_prune_chain(event.chain_id)


func _cancel_at(index: int) -> void:
	var event: DeckitGameEvent = _pending[index]
	_pending.remove_at(index)
	_log(event, "cancelled", "user_request")
	event_cancelled.emit(event)
	_prune_chain(event.chain_id)


func _prune_chain(chain_id: int) -> void:
	if _active_event != null and _active_event.chain_id == chain_id:
		return
	for event in _pending:
		if event.chain_id == chain_id:
			return
	_chain_signatures.erase(chain_id)


func _signature(event: DeckitGameEvent) -> String:
	return "%s|%s|%s|%s|%s" % [
		event.event_type, event.actor_id, event.card_instance_id,
		event.source_zone_id, event.destination_zone_id
	]


func _log(
	event: DeckitGameEvent,
	status: String,
	reason: String,
	applied: int = 0,
	rejected: int = 0
) -> void:
	if max_trace_entries <= 0:
		return
	_trace.append({
		"event_id": event.event_id,
		"chain_id": event.chain_id,
		"depth": event.depth,
		"type": String(event.event_type),
		"priority": event.priority,
		"status": status,
		"reason": reason,
		"applied": applied,
		"rejected": rejected
	})
	while _trace.size() > max_trace_entries:
		_trace.pop_front()


func _on_applied(action: DeckitCardAction) -> void:
	publish(DeckitGameEvent.from_action(DeckitGameEvent.ACTION_APPLIED, action))


func _on_rejected(action: DeckitCardAction) -> void:
	publish(DeckitGameEvent.from_action(DeckitGameEvent.ACTION_REJECTED, action))
