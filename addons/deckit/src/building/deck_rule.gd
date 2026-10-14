## Extend for custom rules (allowed factions, leaders, singleton formats, etc.).
## Return issues only; validation must not mutate its input.
@tool
class_name DeckitDeckRule extends Resource


func validate(
	_deck: DeckitDeckList,
	_catalog: DeckitCardCatalog
) -> Array[DeckitDeckIssue]:
	return []
