## Optional adapter: publishes timeline lifecycle events to an existing queue.
## Turn progression is NEVER driven by the queue and does not drain it.
class_name DeckitTurnEventBridge extends RefCounted

const TURN_STARTED: StringName = &"turn.started"
const TURN_ENDED: StringName = &"turn.ended"
const PHASE_STARTED: StringName = &"phase.started"
const PHASE_ENDED: StringName = &"phase.ended"

var priority: int = 0

var _timeline: DeckitTurnManager
var _queue: DeckitEventQueue


func bind(timeline: DeckitTurnManager, queue: DeckitEventQueue) -> bool:
	if timeline == null or queue == null:
		return false
	unbind()
	_timeline = timeline
	_queue = queue
	_timeline.turn_started.connect(_on_turn_started)
	_timeline.turn_ended.connect(_on_turn_ended)
	_timeline.phase_started.connect(_on_phase_started)
	_timeline.phase_ended.connect(_on_phase_ended)
	return true


func unbind() -> void:
	if _timeline != null:
		if _timeline.turn_started.is_connected(_on_turn_started):
			_timeline.turn_started.disconnect(_on_turn_started)
		if _timeline.turn_ended.is_connected(_on_turn_ended):
			_timeline.turn_ended.disconnect(_on_turn_ended)
		if _timeline.phase_started.is_connected(_on_phase_started):
			_timeline.phase_started.disconnect(_on_phase_started)
		if _timeline.phase_ended.is_connected(_on_phase_ended):
			_timeline.phase_ended.disconnect(_on_phase_ended)
	_timeline = null
	_queue = null


func _on_turn_started(participant_id: StringName, number: int, round: int) -> void:
	_publish(TURN_STARTED, participant_id, number, &"", round)


func _on_turn_ended(participant_id: StringName, number: int, round: int) -> void:
	_publish(TURN_ENDED, participant_id, number, &"", round)


func _on_phase_started(participant_id: StringName, phase_id: StringName, number: int) -> void:
	_publish(PHASE_STARTED, participant_id, number, phase_id, _timeline.round_number)


func _on_phase_ended(participant_id: StringName, phase_id: StringName, number: int) -> void:
	_publish(PHASE_ENDED, participant_id, number, phase_id, _timeline.round_number)


func _publish(kind: StringName, participant_id: StringName, number: int, phase_id: StringName, round: int) -> void:
	if _queue == null:
		return
	var event := DeckitGameEvent.new(kind, priority, {
		"participant_id": participant_id,
		"turn_number": number,
		"round_number": round,
		"phase_id": phase_id
	})
	event.actor_id = participant_id
	_queue.publish(event)
