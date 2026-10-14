extends SceneTree

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("[Deckit decks] " + label)


func _run() -> void:
	var catalog := DeckitCardCatalog.new()
	var a := DeckitCardDefinition.new()
	a.card_id = &"a"
	a.display_name = "Alpha"
	a.tags = PackedStringArray(["unit"])
	a.deck_limit = 2
	var b := DeckitCardDefinition.new()
	b.card_id = &"b"
	b.display_name = "Beta"
	b.tags = PackedStringArray(["item"])
	_check(catalog.add_card(a) and catalog.add_card(b), "Populate catalog")
	_check(not catalog.add_card(a), "Reject duplicate catalog ID")
	_check(catalog.search("alp").size() == 1, "Search title")
	_check(catalog.search("", "unit").size() == 1, "Search tag")
	var deck := DeckitDeckList.new()
	_check(deck.add(&"a", 2), "Add copies")
	_check(deck.add(&"b", 1, &"side"), "Arbitrary sections")
	_check(deck.count(&"a") == 2 and deck.total_cards() == 3, "Count entries")
	var rules := DeckitDeckRules.new()
	rules.minimum_cards = 3
	rules.default_copy_limit = 4
	_check(DeckitDeckValidator.is_valid(deck, catalog, rules), "Valid recipe")
	_check(deck.add(&"a", 1, &"side"), "Editor permits draft exceeding limit")
	_check(not DeckitDeckValidator.is_valid(deck, catalog, rules), "Combined copy limit")
	_check(deck.remove(&"a", 1, &"side"), "Remove copy")
	_check(DeckitDeckValidator.is_valid(deck, catalog, rules), "Corrected draft")
	var copy := deck.copy_deck()
	_check(copy.set_count(&"a", 1), "Edit copy")
	_check(deck.count(&"a") == 2 and copy.count(&"a") == 1, "Independent copy")
	var json := DeckitDeckCodec.encode(deck)
	var imported := DeckitDeckCodec.decode(json)
	_check(imported != null, "Decode JSON")
	if imported != null:
		_check(imported.total_cards() == 3 and imported.count(&"b", &"side") == 1, "Roundtrip")
	_check(DeckitDeckCodec.decode("{bad") == null, "Reject broken JSON")
	_check(DeckitDeckCodec.decode('{"format":"deckit.deck","version":99,"name":"","author":"","notes":"","cards":[]}') == null, "Reject unsupported format")
	rules.allowed_tags = PackedStringArray(["unit"])
	_check(not DeckitDeckValidator.is_valid(deck, catalog, rules), "Tag requirement")
	rules.allowed_tags = PackedStringArray()
	_check(deck.add(&"missing", 1), "Allow incomplete draft")
	_check(not DeckitDeckValidator.is_valid(deck, catalog, rules), "Missing catalog card")
	print("[Deckit decks] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
