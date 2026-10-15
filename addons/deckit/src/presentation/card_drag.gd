## In-process drag proposal, not a serialized/network message or authorization token.
## Captures the actual instance so a reset during dragging cannot move its replacement.
class_name DeckitCardDrag extends RefCounted

var game_state: DeckitGameState
var source_zone_id: StringName
var instance: DeckitCardInstance
var actor_id: StringName
var grab_offset: Vector2


func _init(game: DeckitGameState, source: StringName, card: DeckitCardInstance,
	actor: StringName, offset: Vector2 = Vector2.ZERO) -> void:
	game_state = game
	source_zone_id = source
	instance = card
	actor_id = actor
	grab_offset = offset


func is_current(game: DeckitGameState) -> bool:
	if game == null or game != game_state or instance == null:
		return false
	var zone := game.get_zone(source_zone_id)
	return zone != null and zone.find_by_id(instance.instance_id) == instance


func action_to(destination: StringName) -> DeckitCardAction:
	return DeckitCardAction.new(source_zone_id, destination, instance.instance_id, actor_id)
