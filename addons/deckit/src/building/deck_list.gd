## A portable deck recipe, not a runtime collection of card instances.
## Resource can be authored in the Inspector, the visual builder, or code.
@tool
class_name DeckitDeckList extends Resource

@export var deck_name: String = "New Deck"
@export var author: String = ""
@export_multiline var notes: String = ""
@export var entries: Array[DeckitDeckEntry] = []


func count(card_id: StringName, section_id: StringName = &"main") -> int:
	for entry in entries:
		if entry != null and entry.card_id == card_id and entry.section_id == section_id:
			return entry.quantity
	return 0


func total_cards(section_id: StringName = &"") -> int:
	var result: int = 0
	for entry in entries:
		if entry != null and (section_id == &"" or entry.section_id == section_id):
			result += maxi(0, entry.quantity)
	return result


## Editing deliberately does not enforce game-specific limits.
## Call DeckitDeckValidator.validate() before treating a deck as legal.
func add(card_id: StringName, quantity: int = 1, section_id: StringName = &"main") -> bool:
	if card_id == &"" or section_id == &"" or quantity <= 0:
		return false
	for entry in entries:
		if entry != null and entry.card_id == card_id and entry.section_id == section_id:
			if entry.quantity > 9999 - quantity:
				return false
			entry.quantity += quantity
			emit_changed()
			return true
	if quantity > 9999:
		return false
	var entry := DeckitDeckEntry.new()
	entry.card_id = card_id
	entry.section_id = section_id
	entry.quantity = quantity
	entries.append(entry)
	emit_changed()
	return true


func remove(card_id: StringName, quantity: int = 1, section_id: StringName = &"main") -> bool:
	if quantity <= 0:
		return false
	for entry in entries:
		if entry != null and entry.card_id == card_id and entry.section_id == section_id:
			if quantity >= entry.quantity:
				entries.erase(entry)
			else:
				entry.quantity -= quantity
			emit_changed()
			return true
	return false


func set_count(card_id: StringName, quantity: int, section_id: StringName = &"main") -> bool:
	if card_id == &"" or section_id == &"" or quantity < 0 or quantity > 9999:
		return false
	for entry in entries:
		if entry != null and entry.card_id == card_id and entry.section_id == section_id:
			if quantity == 0:
				entries.erase(entry)
			else:
				entry.quantity = quantity
			emit_changed()
			return true
	if quantity == 0:
		return true
	return add(card_id, quantity, section_id)


func clear() -> void:
	entries.clear()
	emit_changed()


func copy_deck() -> DeckitDeckList:
	var result := DeckitDeckList.new()
	result.deck_name = deck_name
	result.author = author
	result.notes = notes
	for entry in entries:
		if entry == null:
			continue
		var copy := DeckitDeckEntry.new()
		copy.card_id = entry.card_id
		copy.quantity = entry.quantity
		copy.section_id = entry.section_id
		result.entries.append(copy)
	return result
