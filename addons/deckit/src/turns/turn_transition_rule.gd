## Optional game-owned authorization of a proposed phase or turn transition.
## Returning false blocks a transition without changing the timeline.
@tool
class_name DeckitTurnTransitionRule extends Resource


func allows(
	_timeline: DeckitTurnManager,
	_next_participant: StringName,
	_next_phase: StringName
) -> bool:
	return true
