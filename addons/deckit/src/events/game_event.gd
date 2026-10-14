## Snapshot of a notification. Once published, treat its fields as read-only.
## The resolver assigns event_id, chain_id and depth on acceptance.
class_name DeckitGameEvent extends RefCounted

const ACTION_APPLIED: StringName = &"action.applied"
const ACTION_REJECTED: StringName = &"action.rejected"

var event_type: StringName = &""
var priority: int = 0
var actor_id: StringName = &""
var card_instance_id: StringName = &""
var source_zone_id: StringName = &""
var destination_zone_id: StringName = &""
var payload: Dictionary = {}

## Resolver-owned identifiers: 0 denotes an unpublished event.
var event_id: int = 0
var chain_id: int = 0
var depth: int = 0


func _init(kind: StringName = &"", event_priority: int = 0, details: Dictionary = {}) -> void:
	event_type = kind
	priority = event_priority
	payload = details.duplicate(true)


static func from_action(kind: StringName, action: DeckitCardAction) -> DeckitGameEvent:
	var result := DeckitGameEvent.new(kind)
	if action != null:
		result.actor_id = action.actor_id
		result.card_instance_id = action.card_instance_id
		result.source_zone_id = action.source_zone_id
		result.destination_zone_id = action.destination_zone_id
	return result
