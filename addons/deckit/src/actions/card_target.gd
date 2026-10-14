## Identifies one card in one registered zone, without owning its state.
## A target can become stale after a move; resolve it before every action.
class_name DeckitCardTarget extends RefCounted

var zone_id: StringName = &""
var instance_id: StringName = &""


func _init(id: StringName = &"", card_id: StringName = &"") -> void:
	zone_id = id
	instance_id = card_id


func resolve(game: DeckitGameState) -> DeckitCardInstance:
	if game == null or zone_id == &"" or instance_id == &"":
		return null
	var zone: DeckitCardZone = game.get_zone(zone_id)
	if zone == null:
		return null
	return zone.find_by_id(instance_id)
