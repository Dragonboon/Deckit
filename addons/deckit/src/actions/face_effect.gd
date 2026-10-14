## Change a card's face state. Games decide when this operation is legal.
@tool
class_name DeckitFaceEffect extends DeckitCardEffect

enum Mode { FACE_UP, FACE_DOWN, TOGGLE }

@export var mode: Mode = Mode.TOGGLE


func can_apply(game: DeckitGameState, target: DeckitCardTarget) -> bool:
	return target != null and target.resolve(game) != null


func apply(game: DeckitGameState, target: DeckitCardTarget) -> bool:
	if not can_apply(game, target):
		return false
	var card: DeckitCardInstance = target.resolve(game)
	match mode:
		Mode.FACE_UP:
			card.face_up = true
		Mode.FACE_DOWN:
			card.face_up = false
		Mode.TOGGLE:
			card.face_up = not card.face_up
		_:
			return false
	return true
