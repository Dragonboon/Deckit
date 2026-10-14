## Override allows() in a custom Resource to implement game-specific rules.
## For example: ownership, costs, zones, turn timing or deck limits.
@tool
class_name DeckitCardRule extends Resource


func allows(_action: DeckitCardAction, _game: DeckitGameState) -> bool:
	return true
