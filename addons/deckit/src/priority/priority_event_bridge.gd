## Optional event adapter. Publishes priority lifecycle notifications only.
## It does not drain the queue, resolve actions or advance any turns.
class_name DeckitPriorityEventBridge extends RefCounted

const WINDOW_OPENED: StringName = &"priority.window_opened"
const PRIORITY_CHANGED: StringName = &"priority.changed"
const PRIORITY_PASSED: StringName = &"priority.passed"
const ACTION_STAGED: StringName = &"priority.action_staged"
const RESOLUTION_READY: StringName = &"priority.resolution_ready"
const ACTION_RESOLVED: StringName = &"priority.action_resolved"
const ACTION_CANCELLED: StringName = &"priority.action_cancelled"
const WINDOW_CLOSED: StringName = &"priority.window_closed"

var event_priority: int = 0

var _window: DeckitPriorityWindow
var _queue: DeckitEventQueue
var _current_window_id: StringName = &""


func bind(window: DeckitPriorityWindow, queue: DeckitEventQueue) -> bool:
	if window == null or queue == null:
		return false
	unbind()
	_window = window
	_queue = queue
	_window.window_opened.connect(_on_opened)
	_window.priority_changed.connect(_on_changed)
	_window.priority_passed.connect(_on_passed)
	_window.action_staged.connect(_on_staged)
	_window.resolution_ready.connect(_on_ready)
	_window.action_resolved.connect(_on_resolved)
	_window.action_cancelled.connect(_on_cancelled)
	_window.window_closed.connect(_on_closed)
	return true


func unbind() -> void:
	if _window != null:
		if _window.window_opened.is_connected(_on_opened):
			_window.window_opened.disconnect(_on_opened)
		if _window.priority_changed.is_connected(_on_changed):
			_window.priority_changed.disconnect(_on_changed)
		if _window.priority_passed.is_connected(_on_passed):
			_window.priority_passed.disconnect(_on_passed)
		if _window.action_staged.is_connected(_on_staged):
			_window.action_staged.disconnect(_on_staged)
		if _window.resolution_ready.is_connected(_on_ready):
			_window.resolution_ready.disconnect(_on_ready)
		if _window.action_resolved.is_connected(_on_resolved):
			_window.action_resolved.disconnect(_on_resolved)
		if _window.action_cancelled.is_connected(_on_cancelled):
			_window.action_cancelled.disconnect(_on_cancelled)
		if _window.window_closed.is_connected(_on_closed):
			_window.window_closed.disconnect(_on_closed)
	_window = null
	_queue = null
	_current_window_id = &""


func _on_opened(id: StringName, first: StringName) -> void:
	_current_window_id = id
	_publish(WINDOW_OPENED, first)


func _on_changed(participant_id: StringName, passes: int) -> void:
	_publish(PRIORITY_CHANGED, participant_id, null, {"passes": passes})


func _on_passed(participant_id: StringName, passes: int) -> void:
	_publish(PRIORITY_PASSED, participant_id, null, {"passes": passes})


func _on_staged(participant_id: StringName, action: DeckitCardAction) -> void:
	_publish(ACTION_STAGED, participant_id, action)


func _on_ready(pending: int) -> void:
	_publish(RESOLUTION_READY, &"", null, {"pending": pending})


func _on_resolved(action: DeckitCardAction, success: bool) -> void:
	_publish(ACTION_RESOLVED, action.actor_id, action, {"success": success})


func _on_cancelled(action: DeckitCardAction) -> void:
	_publish(ACTION_CANCELLED, action.actor_id, action)


func _on_closed(id: StringName) -> void:
	_publish(WINDOW_CLOSED, &"", null, {"window_id": id})
	_current_window_id = &""


func _publish(
	kind: StringName,
	participant_id: StringName,
	action: DeckitCardAction = null,
	extra: Dictionary = {}
) -> void:
	if _queue == null:
		return
	var details: Dictionary = {"window_id": _current_window_id}
	for key in extra:
		details[key] = extra[key]
	var event := DeckitGameEvent.new(kind, event_priority, details)
	event.actor_id = participant_id
	if action != null:
		event.card_instance_id = action.card_instance_id
		event.source_zone_id = action.source_zone_id
		event.destination_zone_id = action.destination_zone_id
	_queue.publish(event)
