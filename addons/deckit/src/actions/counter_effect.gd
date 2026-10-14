## Example of a reusable, game-neutral state operation.
@tool
class_name DeckitCounterEffect extends DeckitCardEffect

@export var counter_key: StringName = &"counter"
@export var delta: int = 1


func can_apply(game: DeckitGameState, target: DeckitCardTarget) -> bool:
	return target != null and counter_key != &"" and target.resolve(game) != null


func apply(game: DeckitGameState, target: DeckitCardTarget) -> bool:
	if not can_apply(game, target):
		return false
	target.resolve(game).change_counter(counter_key, delta)
	return true
