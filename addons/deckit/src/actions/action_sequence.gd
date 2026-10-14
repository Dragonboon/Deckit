## Executes ordinary DeckitCardAction steps through the standard rule gateway.
## Explicitly non-transactional: successful earlier steps remain if a later
## step fails. Use an authoritative host-managed transaction for rollback.
class_name DeckitActionSequence extends RefCounted

signal finished(success: bool, executed_count: int, failed_step: int)

var steps: Array[DeckitCardAction] = []
var executed_count: int = 0
var failed_step: int = -1
var maximum_steps: int = 64

var _running: bool = false


func add_step(action: DeckitCardAction) -> bool:
	if _running or action == null or steps.size() >= maximum_steps:
		return false
	steps.append(action)
	return true


func clear() -> void:
	if not _running:
		steps.clear()
		executed_count = 0
		failed_step = -1


func execute(game: DeckitGameState) -> bool:
	if _running or game == null:
		return false
	_running = true
	executed_count = 0
	failed_step = -1
	var successful: bool = not steps.is_empty() and steps.size() <= maximum_steps
	if successful:
		for index in range(steps.size()):
			if not game.perform(steps[index]):
				failed_step = index
				successful = false
				break
			executed_count += 1
	_running = false
	finished.emit(successful, executed_count, failed_step)
	return successful
