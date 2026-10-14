## Scenario policy, intentionally outside the reusable Deckit plugin.
extends DeckitCardRule

@export var destination_id: StringName = &"play"
@export var required_tag: String = "allowed"
@export var required_actor: StringName = &"player-1"


func allows(action: DeckitCardAction, game: DeckitGameState) -> bool:
	if action.destination_zone_id != destination_id:
		return true
	if action.actor_id != required_actor:
		return false
	var source := game.get_zone(action.source_zone_id)
	if source == null:
		return false
	var card := source.find_by_id(action.card_instance_id)
	return card != null and card.definition != null and card.definition.has_tag(required_tag)
