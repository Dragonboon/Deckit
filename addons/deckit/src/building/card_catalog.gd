## Collection of reusable card definitions, editable in the Godot Inspector.
## Catalog IDs must be unique; validate() reports conflicts before deck use.
@tool
class_name DeckitCardCatalog extends Resource

@export var cards: Array[DeckitCardDefinition] = []


func find_card(id: StringName) -> DeckitCardDefinition:
	if id == &"":
		return null
	for card in cards:
		if card != null and card.card_id == id:
			return card
	return null


func add_card(card: DeckitCardDefinition) -> bool:
	if card == null or card.card_id == &"" or find_card(card.card_id) != null:
		return false
	cards.append(card)
	emit_changed()
	return true


func remove_card(id: StringName) -> bool:
	for card in cards:
		if card != null and card.card_id == id:
			cards.erase(card)
			emit_changed()
			return true
	return false


## Useful for search boxes: matches ID, title and tags case-insensitively.
func search(query: String = "", tag: String = "") -> Array[DeckitCardDefinition]:
	var matches: Array[DeckitCardDefinition] = []
	var needle: String = query.strip_edges().to_lower()
	for card in cards:
		if card == null or card.card_id == &"":
			continue
		if not tag.is_empty() and not card.has_tag(tag):
			continue
		var found: bool = needle.is_empty() or String(card.card_id).to_lower().contains(needle) \
			or card.display_name.to_lower().contains(needle)
		if not found:
			for label in card.tags:
				if label.to_lower().contains(needle):
					found = true
					break
		if found:
			matches.append(card)
	return matches


## List of duplicate/empty IDs, suitable for editor diagnostics.
func invalid_ids() -> PackedStringArray:
	var messages := PackedStringArray()
	var seen: Dictionary = {}
	for index in range(cards.size()):
		var card: DeckitCardDefinition = cards[index]
		if card == null or card.card_id == &"":
			messages.append("Card at index %d has no ID or is null" % index)
		elif seen.has(card.card_id):
			messages.append("Duplicate ID: %s" % card.card_id)
		else:
			seen[card.card_id] = true
	return messages
