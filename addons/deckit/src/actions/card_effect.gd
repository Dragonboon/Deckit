## Base for opt-in, synchronous card effects.
## Implementations must return false BEFORE mutating any game state on failure.
## The host owns rollback/persistence for effect types with complex side effects.
@tool
class_name DeckitCardEffect extends Resource


func can_apply(_game: DeckitGameState, _target: DeckitCardTarget) -> bool:
	return false


func apply(_game: DeckitGameState, _target: DeckitCardTarget) -> bool:
	return false
