## Materialize a DeckitDeckList into independent runtime copies.
## IDs are unique within this factory's lifetime; use distinct prefixes or
## an authoritative ID allocator across factories, sessions and peers.
class_name DeckitDeckFactory extends RefCounted

var next_serial: int = 1
var last_errors: PackedStringArray = PackedStringArray()


## Empty section_id builds all sections. All deck constraints are checked
## before allocating instances. Invalid input never consumes serial numbers.
func build(
	deck: DeckitDeckList,
	catalog: DeckitCardCatalog,
	section_id: StringName = &"",
	owner_id: StringName = &"",
	id_prefix: String = "card",
	rules: DeckitDeckRules = null
) -> Array[DeckitCardInstance]:
	last_errors.clear()
	var built: Array[DeckitCardInstance] = []
	if deck == null or catalog == null or id_prefix.is_empty() or next_serial < 1:
		last_errors.append("Deck, catalog, nonempty prefix and positive serial are required.")
		return built
	for issue: DeckitDeckIssue in DeckitDeckValidator.validate(deck, catalog, rules):
		if issue == null or issue.severity == DeckitDeckIssue.Severity.ERROR:
			last_errors.append("Invalid deck: %s" % (issue.message if issue != null else "null issue"))
	if not last_errors.is_empty():
		return built
	var definitions: Array[DeckitCardDefinition] = []
	for entry: DeckitDeckEntry in deck.entries:
		if entry.section_id != section_id and section_id != &"":
			continue
		var definition: DeckitCardDefinition = catalog.find_card(entry.card_id)
		for i in range(entry.quantity):
			definitions.append(definition)
	if definitions.is_empty():
		last_errors.append("No cards in the selected section.")
		return built
	if next_serial > 2147483647 - definitions.size():
		last_errors.append("Factory serial range exhausted.")
		return built
	for definition: DeckitCardDefinition in definitions:
		var card := DeckitCardInstance.new(
			definition, StringName("%s-%d" % [id_prefix, next_serial])
		)
		card.owner_id = owner_id
		card.controller_id = owner_id
		built.append(card)
		next_serial += 1
	return built
