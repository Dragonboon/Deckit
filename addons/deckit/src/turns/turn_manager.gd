## Opt-in, UI-independent turn/phase coordinator.
## Provides only an ordered clock: no combat, resource, action or player rules.
## All mutations are explicit and transitions are guarded against reentry.
class_name DeckitTurnManager extends RefCounted

signal timeline_started
signal timeline_stopped
signal pause_changed(paused: bool)
signal transition_denied(next_participant: StringName, next_phase: StringName)
signal phase_started(participant_id: StringName, phase_id: StringName, turn_number: int)
signal phase_ended(participant_id: StringName, phase_id: StringName, turn_number: int)
signal turn_started(participant_id: StringName, turn_number: int, round_number: int)
signal turn_ended(participant_id: StringName, turn_number: int, round_number: int)

## Configured only while stopped; definitions are copied to avoid external edits.
var participants: Array[StringName] = []
var phases: Array[StringName] = []
var transition_rules: Array[DeckitTurnTransitionRule] = []

var is_running: bool = false
var is_paused: bool = false
var turn_number: int = 0
var round_number: int = 0

var _participant_index: int = -1
var _phase_index: int = -1
var _transitioning: bool = false


func configure(player_ids: Array[StringName], phase_ids: Array[StringName]) -> bool:
	if is_running or _transitioning:
		return false
	if not _valid_ids(player_ids) or not _valid_ids(phase_ids):
		return false
	participants = player_ids.duplicate()
	phases = phase_ids.duplicate()
	return true


func _valid_ids(ids: Array[StringName]) -> bool:
	if ids.is_empty():
		return false
	var seen: Dictionary = {}
	for id in ids:
		if id == &"" or seen.has(id):
			return false
		seen[id] = true
	return true


func add_rule(rule: DeckitTurnTransitionRule) -> bool:
	if _transitioning or rule == null or transition_rules.has(rule):
		return false
	transition_rules.append(rule)
	return true


func remove_rule(rule: DeckitTurnTransitionRule) -> bool:
	if _transitioning or not transition_rules.has(rule):
		return false
	transition_rules.erase(rule)
	return true


func current_participant() -> StringName:
	if not is_running or _participant_index < 0:
		return &""
	return participants[_participant_index]


func current_phase() -> StringName:
	if not is_running or _phase_index < 0:
		return &""
	return phases[_phase_index]


func current_participant_index() -> int:
	return _participant_index


func current_phase_index() -> int:
	return _phase_index


func start(first_participant: StringName = &"") -> bool:
	if is_running or _transitioning or not _valid_ids(participants) or not _valid_ids(phases):
		return false
	var first_index: int = 0
	if first_participant != &"":
		first_index = participants.find(first_participant)
		if first_index < 0:
			return false
	var participant: StringName = participants[first_index]
	if not _allowed(participant, phases[0]):
		transition_denied.emit(participant, phases[0])
		return false
	_transitioning = true
	_participant_index = first_index
	_phase_index = 0
	turn_number = 1
	round_number = 1
	is_paused = false
	is_running = true
	timeline_started.emit()
	turn_started.emit(current_participant(), turn_number, round_number)
	phase_started.emit(current_participant(), current_phase(), turn_number)
	_transitioning = false
	return true


## Advance one phase; crossing its end begins the next participant's turn.
func next_phase() -> bool:
	if not _can_transition():
		return false
	if _phase_index + 1 >= phases.size():
		return _advance_turn()
	var next_phase_id: StringName = phases[_phase_index + 1]
	if not _allowed(current_participant(), next_phase_id):
		transition_denied.emit(current_participant(), next_phase_id)
		return false
	_transitioning = true
	var old_phase: StringName = current_phase()
	var old_participant: StringName = current_participant()
	var old_turn: int = turn_number
	phase_ended.emit(old_participant, old_phase, old_turn)
	_phase_index += 1
	phase_started.emit(current_participant(), current_phase(), turn_number)
	_transitioning = false
	return true


## Explicitly leave remaining phases and advance to the next participant.
func end_turn() -> bool:
	if not _can_transition():
		return false
	return _advance_turn()


func _advance_turn() -> bool:
	var next_index: int = (_participant_index + 1) % participants.size()
	var next_participant: StringName = participants[next_index]
	if not _allowed(next_participant, phases[0]):
		transition_denied.emit(next_participant, phases[0])
		return false
	_transitioning = true
	var old_participant: StringName = current_participant()
	var old_phase: StringName = current_phase()
	var old_turn: int = turn_number
	var old_round: int = round_number
	_phase_index = 0
	_participant_index = next_index
	turn_number += 1
	if next_index == 0:
		round_number += 1
	phase_ended.emit(old_participant, old_phase, old_turn)
	turn_ended.emit(old_participant, old_turn, old_round)
	turn_started.emit(current_participant(), turn_number, round_number)
	phase_started.emit(current_participant(), current_phase(), turn_number)
	_transitioning = false
	return true


func _can_transition() -> bool:
	return is_running and not is_paused and not _transitioning


func _allowed(participant_id: StringName, phase_id: StringName) -> bool:
	for rule in transition_rules:
		if rule == null or not rule.allows(self, participant_id, phase_id):
			return false
	return true


func pause() -> bool:
	if not is_running or is_paused or _transitioning:
		return false
	is_paused = true
	pause_changed.emit(true)
	return true


func resume() -> bool:
	if not is_running or not is_paused or _transitioning:
		return false
	is_paused = false
	pause_changed.emit(false)
	return true


## Stop clears progress, not configured phases/participants or rules.
func stop() -> bool:
	if not is_running or _transitioning:
		return false
	_transitioning = true
	is_running = false
	is_paused = false
	_participant_index = -1
	_phase_index = -1
	turn_number = 0
	round_number = 0
	timeline_stopped.emit()
	_transitioning = false
	return true
