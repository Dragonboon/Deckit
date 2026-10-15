## Representative reusable mechanics, NOT complete game rules.
## Godot 4.7: godot --headless --path . --script res://tests/headless/test_game_families.gd
extends SceneTree

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, description: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("[Deckit families] " + description)


func _make_definition(id: StringName, suit: String, value: int) -> DeckitCardDefinition:
	var definition := DeckitCardDefinition.new()
	definition.card_id = id
	definition.display_name = String(id)
	definition.tags = PackedStringArray([suit])
	definition.attributes = {"suit": suit, "rank": value}
	return definition


func _run() -> void:
	_spanish_and_french()
	_traditional_turns()
	_tcg_lcg()
	_integrity_checks()
	print("[Deckit families] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _spanish_and_french() -> void:
	for format in ["spanish_40", "french_52"]:
		var catalog := DeckitCardCatalog.new()
		var deck := DeckitDeckList.new()
		var suits: Array = ["oros", "copas", "espadas", "bastos"] if format == "spanish_40" else ["clubs", "diamonds", "hearts", "spades"]
		var ranks: Array = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12] if format == "spanish_40" else [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
		for suit in suits:
			for rank in ranks:
				var id := StringName("%s-%d" % [suit, rank])
				_check(catalog.add_card(_make_definition(id, suit, rank)), "Catalog insert %s" % id)
				_check(deck.add(id), "Recipe add %s" % id)
		_check(deck.total_cards() == (40 if format == "spanish_40" else 52), "Deck size %s" % format)
		var rules := DeckitDeckRules.new()
		rules.minimum_cards = deck.total_cards()
		rules.maximum_cards = deck.total_cards()
		rules.default_copy_limit = 1
		_check(DeckitDeckValidator.is_valid(deck, catalog, rules), "Legal catalog recipe %s" % format)
		var game := DeckitGameState.new()
		var draw := DeckitCardZone.new(&"draw")
		var hand_a := DeckitCardZone.new(&"hand-a")
		var hand_b := DeckitCardZone.new(&"hand-b")
		var table := DeckitCardZone.new(&"table")
		for zone in [draw, hand_a, hand_b, table]:
			_check(game.register_zone(zone), "Register %s zone" % format)
		var number: int = 0
		for entry in deck.entries:
			number += 1
			_check(draw.add_card(DeckitCardInstance.new(catalog.find_card(entry.card_id), StringName("%s-%d" % [format, number]))), "Materialize %s" % format)
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261014
		draw.shuffle_with_rng(rng)
		for i in range(5):
			var destination: StringName = &"hand-a" if i % 2 == 0 else &"hand-b"
			var top := draw.peek_top()
			_check(game.perform(DeckitCardAction.new(&"draw", destination, top.instance_id)), "Deal card %s" % format)
		_check(draw.size() == deck.total_cards() - 5 and hand_a.size() == 3 and hand_b.size() == 2, "Deal totals %s" % format)
		var played := hand_a.peek_top()
		_check(game.perform(DeckitCardAction.new(&"hand-a", &"table", played.instance_id)), "Play card %s" % format)
		_check(table.size() == 1 and game.inspect_integrity().is_empty(), "No duplicate copies %s" % format)
		_check(DeckitDeckCodec.decode(DeckitDeckCodec.encode(deck)).total_cards() == deck.total_cards(), "Recipe JSON roundtrip %s" % format)


func _traditional_turns() -> void:
	var turns := DeckitTurnManager.new()
	_check(turns.configure([&"p1", &"p2", &"p3", &"p4"], [&"deal", &"play", &"score"]), "Traditional turn configuration")
	_check(turns.start(), "Start turn order")
	_check(turns.next_phase() and turns.current_phase() == &"play", "Advance to play")
	_check(turns.end_turn() and turns.current_participant() == &"p2", "Advance participant")
	_check(turns.end_turn() and turns.end_turn() and turns.end_turn(), "Complete four-player cycle")
	_check(turns.round_number == 2 and turns.current_participant() == &"p1", "Traditional rounds")


func _tcg_lcg() -> void:
	var catalog := DeckitCardCatalog.new()
	var definition := _make_definition(&"unit", "unit", 2)
	definition.deck_limit = 3
	_check(catalog.add_card(definition), "Add generic customizable card")
	var recipe := DeckitDeckList.new()
	_check(recipe.add(&"unit", 2, &"main"), "Main deck copies")
	_check(recipe.add(&"unit", 1, &"side"), "Secondary section copy")
	var rules := DeckitDeckRules.new()
	rules.default_copy_limit = 3
	_check(DeckitDeckValidator.is_valid(recipe, catalog, rules), "TCG/LCG generic constraints")
	_check(recipe.add(&"unit", 1, &"side"), "Allow invalid draft")
	_check(not DeckitDeckValidator.is_valid(recipe, catalog, rules), "Cross-section copy cap")
	var game := DeckitGameState.new()
	var hand := DeckitCardZone.new(&"hand")
	var table := DeckitCardZone.new(&"table")
	game.register_zone(hand)
	game.register_zone(table)
	var card := DeckitCardInstance.new(definition, &"unique-unit")
	card.owner_id = &"p1"
	card.controller_id = &"p1"
	_check(hand.add_card(card), "Add instance")
	var target := DeckitCardTarget.new(&"hand", &"unique-unit")
	var counter := DeckitCounterEffect.new()
	counter.counter_key = &"resource"
	counter.delta = 2
	_check(game.perform(DeckitEffectAction.new().configure(counter, target, &"p1")), "Apply generic effect")
	_check(card.get_counter(&"resource") == 2, "Independent effect state")
	_check(game.perform(DeckitCardAction.new(&"hand", &"table", &"unique-unit", &"p1")), "Play through rules gateway")
	_check(target.resolve(game) == null, "Stale target no longer resolves")


func _integrity_checks() -> void:
	var game := DeckitGameState.new()
	var a := DeckitCardZone.new(&"a")
	var b := DeckitCardZone.new(&"b")
	game.register_zone(a)
	game.register_zone(b)
	var definition := _make_definition(&"x", "neutral", 1)
	var first := DeckitCardInstance.new(definition, &"id1")
	var second := DeckitCardInstance.new(definition, &"id1")
	a.add_card(first)
	b.add_card(second)
	_check(not game.inspect_integrity().is_empty(), "Detect ID collision across zones")
	second.instance_id = &"id2"
	_check(game.inspect_integrity().is_empty(), "Integrity restored")
