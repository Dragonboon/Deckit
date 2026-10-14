## Explicit, opt-in, synchronous dispatcher with deterministic priority order.
## Attach to a game state to observe applied/rejected actions, or publish custom
## events. Nothing is automatically resolved until resolve_next()/drain().
class_name DeckitEventQueue extends RefCounted

signal event_queued(event: DeckitGameEvent)
signal event_processed(event: DeckitGameEvent, applied_actions: int, rejected_actions: int)
signal event_dropped(event: DeckitGameEvent)
signal response_limit_reached(event: DeckitGameEvent)

var max_pending_events: int = 256
var max_events_per_drain: int = 128
var max_actions_per_event: int = 32

var _game: DeckitGameState
var _pending: Array[DeckitGameEvent] = []
var _responders: Array[DeckitEventResponder] = []
var _busy: bool = false


## Binding only records action outcome notifications. Existing GameState
## users and visual views are unaffected unless a queue is explicitly bound.
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


func clear_pending() -> void:
	if not _busy:
		_pending.clear()


## Higher priority events first; equal priority is FIFO by publication order.
func publish(event: DeckitGameEvent) -> bool:
	if event == null or event.event_type == &"" or _pending.size() >= maxi(1, max_pending_events):
		if event != null:
			event_dropped.emit(event)
		return false
	_pending.append(event)
	event_queued.emit(event)
	return true


func resolve_next() -> bool:
	if _busy or _game == null or _pending.is_empty():
		return false
	_busy = true
	_resolve_one()
	_busy = false
	return true


## Returns events actually processed. Further events remain pending on limits.
## No rollback: successfully applied responses persist if later ones fail.
func drain(maximum: int = 0) -> int:
	if _busy or _game == null:
		return 0
	_busy = true
	var budget: int = mini(maxi(1, max_events_per_drain), maximum) if maximum > 0 else maxi(1, max_events_per_drain)
	var processed: int = 0
	while processed < budget and not _pending.is_empty():
		_resolve_one()
		processed += 1
	_busy = false
	return processed


func _resolve_one() -> void:
	var selected_index: int = 0
	for index in range(1, _pending.size()):
		if _pending[index].priority > _pending[selected_index].priority:
			selected_index = index
	var event: DeckitGameEvent = _pending[selected_index]
	_pending.remove_at(selected_index)

	var ordered: Array[DeckitEventResponder] = []
	for responder in _responders:
		var insertion: int = ordered.size()
		for index in range(ordered.size()):
			if responder.priority > ordered[index].priority:
				insertion = index
				break
		ordered.insert(insertion, responder)

	var applied: int = 0
	var rejected: int = 0
	var attempted: int = 0
	var capacity: int = maxi(1, max_actions_per_event)
	var truncated: bool = false
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
		if truncated:
			break
	if truncated:
		response_limit_reached.emit(event)
	event_processed.emit(event, applied, rejected)


func _on_applied(action: DeckitCardAction) -> void:
	publish(DeckitGameEvent.from_action(DeckitGameEvent.ACTION_APPLIED, action))


func _on_rejected(action: DeckitCardAction) -> void:
	publish(DeckitGameEvent.from_action(DeckitGameEvent.ACTION_REJECTED, action))
