## Generic tag predicate, useful for checking a targeted card's definition.
## No card family, faction or turn rules are built into the plugin.
@tool
class_name DeckitTagCondition extends DeckitCardCondition

@export var tag: String = ""
@export var inverted: bool = false


func is_met(game: DeckitGameState, _action: DeckitCardAction, target: DeckitCardTarget) -> bool:
	if target == null or tag.is_empty():
		return false
	var card: DeckitCardInstance = target.resolve(game)
	if card == null or card.definition == null:
		return false
	var matches: bool = card.definition.has_tag(tag)
	return not matches if inverted else matches
