## Optional, rule-neutral action opportunity window.
## Participants may stage responses. All must pass before one action resolves.
## LIFO models nested responses; FIFO supports other game designs.
## Does not own a turn order, a game phase, animation or a network protocol.
class_name DeckitPriorityWindow extends RefCounted

signal window_opened(window_id: StringName, first_participant: StringName)
signal priority_changed(participant_id: StringName, consecutive_passes: int)
signal priority_passed(participant_id: StringName, consecutive_passes: int)
signal action_staged(participant_id: StringName, action: DeckitCardAction)
signal resolution_ready(pending_actions: int)
signal action_resolved(action: DeckitCardAction, success: bool)
signal action_cancelled(action: DeckitCardAction)
signal window_closed(window_id: StringName)

enum ResolutionOrder { LIFO, FIFO }

var resolution_order: ResolutionOrder = ResolutionOrder.LIFO
## If false, an empty window stays open after everyone passes until close().
var auto_close_when_empty: bool = true
var max_pending_actions: int = 64

var window_id: StringName = &""
var participants: Array[StringName] = []
var is_open: bool = false
var ready_to_resolve: bool = false
var consecutive_passes: int = 0

var _game: DeckitGameState
var _start_index: int = -1
var _priority_index: int = -1
var _pending: Array[DeckitCardAction] = []
var _busy: bool = false


func open(
	game: DeckitGameState,
	player_ids: Array[StringName],
	first_participant: StringName = &"",
	id: StringName = &"priority"
) -> bool:
	if is_open or _busy or game == null or id == &"" or not _valid_ids(player_ids):
		return false
	var starting_index: int = 0
	if first_participant != &"":
		starting_index = player_ids.find(first_participant)
		if starting_index < 0:
			return false

	_busy = true
	_game = game
	window_id = id
	participants = player_ids.duplicate()
	_start_index = starting_index
	_priority_index = starting_index
	_pending.clear()
	consecutive_passes = 0
	ready_to_resolve = false
	is_open = true
	window_opened.emit(window_id, current_participant())
	priority_changed.emit(current_participant(), consecutive_passes)
	_busy = false
	return true


## Optional convenience: use the timeline's active participant as the starter.
## The timeline is not automatically advanced when this window closes.
func open_from_turn(
	game: DeckitGameState,
	timeline: DeckitTurnManager,
	id: StringName = &"priority"
) -> bool:
	if timeline == null or not timeline.is_running or timeline.is_paused:
		return false
	return open(game, timeline.participants, timeline.current_participant(), id)


func current_participant() -> StringName:
	if not is_open or _priority_index < 0:
		return &""
	return participants[_priority_index]


func pending_count() -> int:
	return _pending.size()


## The action's actor_id must match the actual priority holder.
## Proposing an action does NOT run rules or mutate game state.
func submit_action(participant_id: StringName, action: DeckitCardAction) -> bool:
	if not _can_act(participant_id) or action == null:
		return false
	if action.actor_id != participant_id or _pending.size() >= maxi(1, max_pending_actions):
		return false
	_busy = true
	_pending.append(action)
	consecutive_passes = 0
	action_staged.emit(participant_id, action)
	_rotate()
	_busy = false
	return true


## Passing all players with work pending allows exactly one resolution step.
## Further answers are possible after that step and before the next resolution.
func pass_priority(participant_id: StringName) -> bool:
	if not _can_act(participant_id):
		return false
	_busy = true
	consecutive_passes += 1
	priority_passed.emit(participant_id, consecutive_passes)
	if consecutive_passes >= participants.size():
		if _pending.is_empty() and auto_close_when_empty:
			_close_internal()
		else:
			ready_to_resolve = true
			resolution_ready.emit(_pending.size())
	else:
		_rotate()
	_busy = false
	return true


## A single pending action resolves via the existing GameState.perform()
## gateway. Its success/failure does not roll back earlier actions.
## Returns false for an invalid call OR for a rejected executed action;
## use action_resolved to distinguish the two cases.
func resolve_next() -> bool:
	if not is_open or not ready_to_resolve or _busy or _pending.is_empty() or _game == null:
		return false
	_busy = true
	var action: DeckitCardAction
	if resolution_order == ResolutionOrder.FIFO:
		action = _pending.pop_front()
	else:
		action = _pending.pop_back()
	var succeeded: bool = _game.perform(action)
	ready_to_resolve = false
	consecutive_passes = 0
	_priority_index = _start_index
	action_resolved.emit(action, succeeded)
	priority_changed.emit(current_participant(), consecutive_passes)
	_busy = false
	return succeeded


## Closing refuses to discard staged actions. Call cancel() deliberately.
func close() -> bool:
	if not is_open or _busy or not _pending.is_empty():
		return false
	_busy = true
	_close_internal()
	_busy = false
	return true


## Cancel remaining proposals without executing them. Does not undo actions
## previously resolved through GameState.
func cancel() -> bool:
	if not is_open or _busy:
		return false
	_busy = true
	while not _pending.is_empty():
		action_cancelled.emit(_pending.pop_back())
	_close_internal()
	_busy = false
	return true


func _can_act(participant_id: StringName) -> bool:
	return is_open and not _busy and not ready_to_resolve and participant_id != &"" \
		and current_participant() == participant_id


func _rotate() -> void:
	_priority_index = (_priority_index + 1) % participants.size()
	priority_changed.emit(current_participant(), consecutive_passes)


func _close_internal() -> void:
	var completed_id: StringName = window_id
	is_open = false
	ready_to_resolve = false
	consecutive_passes = 0
	_game = null
	_pending.clear()
	participants.clear()
	_start_index = -1
	_priority_index = -1
	window_id = &""
	window_closed.emit(completed_id)


func _valid_ids(ids: Array[StringName]) -> bool:
	if ids.is_empty():
		return false
	var seen: Dictionary = {}
	for participant_id in ids:
		if participant_id == &"" or seen.has(participant_id):
			return false
		seen[participant_id] = true
	return true
