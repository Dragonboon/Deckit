## Override is_met() to opt into game-specific activation constraints.
## The default condition is intentionally permissive.
@tool
class_name DeckitCardCondition extends Resource


func is_met(_game: DeckitGameState, _action: DeckitCardAction, _target: DeckitCardTarget) -> bool:
	return true
