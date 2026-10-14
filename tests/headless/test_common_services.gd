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
		push_error("[Deckit services] " + label)

func _run() -> void:
	var catalog := DeckitCardCatalog.new()
	var recipe := DeckitDeckList.new()
	for number in range(1, 5):
		var definition := DeckitCardDefinition.new()
		definition.card_id = StringName("c%d" % number)
		definition.attributes = {"rank": number, "suit": "cups"}
		_check(catalog.add_card(definition) and recipe.add(definition.card_id, 2), "Catalog and recipe")
	var rules := DeckitDeckRules.new()
	rules.default_copy_limit = 2
	var factory := DeckitDeckFactory.new()
	var copies := factory.build(recipe, catalog, &"main", &"alice", "a", rules)
	_check(copies.size() == 8 and factory.last_errors.is_empty(), "Materialize valid recipe")
	var known: Dictionary = {}
	for card in copies:
		known[card.instance_id] = true
		_check(card.owner_id == &"alice" and card.controller_id == &"alice", "Owner/controller")
	_check(known.size() == 8, "Unique instance IDs")
	_check(factory.build(recipe, catalog, &"missing").is_empty(), "Missing section rejected")
	_check(not factory.last_errors.is_empty(), "Factory error reported")
	var game := DeckitGameState.new()
	var draw := DeckitCardZone.new(&"draw")
	var first := DeckitCardZone.new(&"first")
	var second := DeckitCardZone.new(&"second")
	first.capacity = 3
	second.capacity = 3
	_check(game.register_zone(draw) and game.register_zone(first) and game.register_zone(second), "Register zones")
	for card in copies:
		_check(draw.add_card(card), "Insert materialized instance")
	var destination_ids: Array[StringName] = [&"first", &"second"]
	_check(DeckitDealer.deal_round_robin(game, &"draw", destination_ids, 3) == 6, "Deal round-robin")
	_check(first.size() == 3 and second.size() == 3 and draw.size() == 2, "Deal distribution")
	_check(DeckitDealer.deal_round_robin(game, &"draw", destination_ids, 1) == 0, "Capacity denial")
	_check(game.inspect_integrity().is_empty(), "No integrity violations")
	var order := PackedInt32Array([1, 3, 4, 2])
	var c1 := DeckitCardInstance.new(catalog.find_card(&"c1"), &"r1")
	var c2 := DeckitCardInstance.new(catalog.find_card(&"c2"), &"r2")
	var c3 := DeckitCardInstance.new(catalog.find_card(&"c3"), &"r3")
	_check(DeckitCardRanking.compare(c1, c2, "cups", "", order) > 0, "Configurable ranking")
	var trick: Array[DeckitCardInstance] = [c2, c1, c3]
	_check(DeckitCardRanking.trick_winner(trick, "", order) == 1, "Configurable trick winner")
	var run: Array[DeckitCardInstance] = [c1, c2, c3]
	_check(DeckitCardPatterns.is_run(run), "Numerical consecutive ranks")
	_check(DeckitCardPatterns.all_share(run, &"suit"), "Matching suits")
	_check(DeckitCardPatterns.attribute_counts(run, &"suit").get("cups", 0) == 3, "Attribute counts")
	var ledger := DeckitValueLedger.new()
	_check(ledger.grant(&"alice", {&"coins": 4, &"energy": 2}), "Grant tracks")
	_check(not ledger.pay(&"alice", {&"coins": 2, &"energy": 3}), "Atomic denial")
	_check(ledger.get_value(&"alice", &"coins") == 4, "Failed payment unchanged")
	_check(ledger.pay(&"alice", {&"coins": 2, &"energy": 2}), "Atomic payment")
	_check(ledger.get_value(&"alice", &"coins") == 2, "Paid balance")
	_check(ledger.add_value(&"alice", &"score", 7), "Grant score")
	var goal := DeckitThresholdGoal.new()
	goal.threshold = 7
	_check(goal.is_met(ledger, &"alice"), "Configurable threshold")
	_check(not goal.is_met(ledger, &"bob"), "Distinct participants")
	print("[Deckit services] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
