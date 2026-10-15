## Plain JSON import/export; no textures, gameplay state or file I/O.
## Strict decoding prevents malformed recipes from partially mutating an editor.
class_name DeckitDeckCodec extends RefCounted

const FORMAT_VERSION: int = 1


static func encode(deck: DeckitDeckList) -> String:
	if deck == null:
		return ""
	var encoded_entries: Array[Dictionary] = []
	for entry in deck.entries:
		if entry == null:
			continue
		encoded_entries.append({
			"id": String(entry.card_id),
			"section": String(entry.section_id),
			"count": entry.quantity
		})
	return JSON.stringify({
		"format": "deckit.deck",
		"version": FORMAT_VERSION,
		"name": deck.deck_name,
		"author": deck.author,
		"notes": deck.notes,
		"cards": encoded_entries
	}, "\t")


static func decode(json_text: String) -> DeckitDeckList:
	var parser := JSON.new()
	if parser.parse(json_text) != OK:
		return null
	var parsed: Variant = parser.data
	if not (parsed is Dictionary):
		return null
	var doc: Dictionary = parsed
	if doc.get("format") != "deckit.deck" or doc.get("version") != FORMAT_VERSION:
		return null
	if not (doc.get("name") is String) or not (doc.get("author") is String) \
			or not (doc.get("notes") is String) or not (doc.get("cards") is Array):
		return null
	var deck := DeckitDeckList.new()
	deck.deck_name = doc["name"]
	deck.author = doc["author"]
	deck.notes = doc["notes"]
	var seen: Dictionary = {}
	var data: Array = doc["cards"]
	if data.size() > 10000:
		return null
	for value in data:
		if not (value is Dictionary):
			return null
		var item: Dictionary = value
		var raw_id: Variant = item.get("id")
		var raw_section: Variant = item.get("section")
		var raw_count: Variant = item.get("count")
		if not (raw_id is String) or not (raw_section is String):
			return null
		if not (raw_count is int or raw_count is float):
			return null
		if raw_count < 1 or raw_count > 9999 or float(raw_count) != float(int(raw_count)):
			return null
		if String(raw_id).is_empty() or String(raw_section).is_empty():
			return null
		var key: String = "%s\u001f%s" % [raw_section, raw_id]
		if seen.has(key):
			return null
		seen[key] = true
		if not deck.add(StringName(raw_id), int(raw_count), StringName(raw_section)):
			return null
	return deck
