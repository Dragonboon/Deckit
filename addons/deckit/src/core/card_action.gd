## First gameplay action: transfer an instance between two registered zones.
## Specialized games may subclass and override can_apply/apply.
class_name DeckitCardAction extends RefCounted

var actor_id: StringName = &""
var source_zone_id: StringName = &""
var destination_zone_id: StringName = &""
var card_instance_id: StringName = &""


func _init(source_id: StringName = &"", destination_id: StringName = &"", instance_id: StringName = &"", player_id: StringName = &"") -> void:
	source_zone_id = source_id
	destination_zone_id = destination_id
	card_instance_id = instance_id
	actor_id = player_id


func can_apply(game: DeckitGameState) -> bool:
	if game == null or card_instance_id == &"" or source_zone_id == destination_zone_id:
		return false
	var source: DeckitCardZone = game.get_zone(source_zone_id)
	var destination: DeckitCardZone = game.get_zone(destination_zone_id)
	if source == null or destination == null:
		return false
	var card: DeckitCardInstance = source.find_by_id(card_instance_id)
	return card != null and destination.can_accept(card)


func apply(game: DeckitGameState) -> bool:
	if not can_apply(game):
		return false
	var source: DeckitCardZone = game.get_zone(source_zone_id)
	var destination: DeckitCardZone = game.get_zone(destination_zone_id)
	return source.move_card_to(destination, source.find_by_id(card_instance_id))
