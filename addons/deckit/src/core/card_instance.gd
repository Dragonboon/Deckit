## Mutable runtime state of one physical/logical copy of a card.
## IDs are supplied by the host game for deterministic saves and networking.
class_name DeckitCardInstance extends RefCounted

var definition: DeckitCardDefinition
var instance_id: StringName = &""
var owner_id: StringName = &""
var controller_id: StringName = &""
var face_up: bool = false
var exhausted: bool = false
var counters: Dictionary = {}
var state: Dictionary = {}


func _init(card_definition: DeckitCardDefinition = null, id: StringName = &"") -> void:
	definition = card_definition
	instance_id = id


func get_attribute(key: StringName, fallback: Variant = null) -> Variant:
	if definition == null:
		return fallback
	return definition.get_attribute(key, fallback)


func get_counter(key: StringName) -> int:
	return int(counters.get(key, 0))


func set_counter(key: StringName, amount: int) -> void:
	if amount <= 0:
		counters.erase(key)
	else:
		counters[key] = amount


func change_counter(key: StringName, amount: int) -> void:
	set_counter(key, maxi(0, get_counter(key) + amount))
