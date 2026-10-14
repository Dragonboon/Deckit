## Opt-in rule to block a DeckitTurnManager transition while a window is open.
## The game chooses whether or not to register it.
@tool
class_name DeckitPriorityTurnGate extends DeckitTurnTransitionRule

var priority_window: DeckitPriorityWindow


func allows(
	_timeline: DeckitTurnManager,
	_next_participant: StringName,
	_next_phase: StringName
) -> bool:
	return priority_window == null or not priority_window.is_open
