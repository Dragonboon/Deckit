## Optional numeric outcome check for a single participant and track.
## A custom game determines when and for whom to evaluate this predicate.
@tool
class_name DeckitThresholdGoal extends Resource

enum Comparison { AT_LEAST, AT_MOST, EQUALS }

@export var track_id: StringName = &"score"
@export var threshold: int = 10
@export var comparison: Comparison = Comparison.AT_LEAST


func is_met(ledger: DeckitValueLedger, participant_id: StringName) -> bool:
	if ledger == null or participant_id == &"" or track_id == &"":
		return false
	var amount: int = ledger.get_value(participant_id, track_id)
	match comparison:
		Comparison.AT_LEAST:
			return amount >= threshold
		Comparison.AT_MOST:
			return amount <= threshold
		Comparison.EQUALS:
			return amount == threshold
	return false
