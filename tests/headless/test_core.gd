## Run after importing the project:
## godot --headless --path . --script res://tests/headless/test_core.gd
extends SceneTree

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("[Deckit test] " + message)


func _run() -> void:
	var definition := DeckitCardDefinition.new()
	definition.card_id = &"spark"
	definition.tags = PackedStringArray(["spell", "elemental"])
	definition.attributes = {"cost": 2}
	_check(definition.has_tag("spell"), "Definition tags")
	_check(definition.get_attribute(&"cost") == 2, "Custom attributes")
	_check(definition.get_attribute(&"unknown", 3) == 3, "Attribute fallback")

	var first := DeckitCardInstance.new(definition, &"copy-1")
	var second := DeckitCardInstance.new(definition, &"copy-2")
	first.change_counter(&"charge", 3)
	second.change_counter(&"charge", 1)
	_check(first.definition == second.definition, "Shared definition")
	_check(first.get_counter(&"charge") == 3 and second.get_counter(&"charge") == 1, "Independent state")
	first.change_counter(&"charge", -5)
	_check(first.get_counter(&"charge") == 0, "Counter floor")

	var deck := DeckitCardZone.new(&"deck", &"player-1")
	var hand := DeckitCardZone.new(&"hand", &"player-1")
	hand.capacity = 1
	_check(deck.add_card(first), "Insert card in deck")
	_check(not deck.add_card(first), "Reject duplicate card")
	_check(deck.add_card(second), "Insert second card")
	_check(deck.peek_top() == second, "Top-of-deck ordering")
	_check(not deck.move_card_to(deck, first), "Reject move to same zone")

	var game := DeckitGameState.new()
	_check(game.register_zone(deck), "Register deck")
	_check(game.register_zone(hand), "Register hand")
	_check(not game.register_zone(deck), "Reject duplicate zone")
	var first_move := DeckitCardAction.new(&"deck", &"hand", &"copy-1", &"player-1")
	_check(game.perform(first_move), "Transfer card")
	_check(deck.find_by_id(&"copy-1") == null and hand.find_by_id(&"copy-1") == first, "No duplicate after transfer")
	_check(not game.perform(DeckitCardAction.new(&"deck", &"hand", &"copy-2")), "Reject transfer into full zone")
	_check(deck.size() == 1 and hand.size() == 1, "Rejected move is atomic")
	_check(not game.perform(DeckitCardAction.new(&"missing", &"hand", &"copy-1")), "Reject unknown zone")

	var discard := DeckitCardZone.new(&"discard")
	_check(game.register_zone(discard), "Register discard")
	var deny_rule := preload("res://tests/headless/deny_all_rule.gd").new()
	_check(game.register_rule(deny_rule), "Register rule")
	_check(not game.register_rule(deny_rule), "Reject duplicate rule")
	_check(not game.perform(DeckitCardAction.new(&"hand", &"discard", &"copy-1")), "Custom rule denies action")
	_check(hand.size() == 1 and discard.is_empty(), "Denied action unchanged")
	game.rules.clear()
	_check(game.perform(DeckitCardAction.new(&"hand", &"discard", &"copy-1")), "Move after rule removal")

	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	deck.shuffle_with_rng(rng)
	_check(deck.size() == 1, "Shuffle preserves cards")
	_check(deck.take_top() == second and deck.is_empty(), "Draw the top card")
	_check(deck.take_top() == null, "Empty deck is safe")
	print("[Deckit] Core tests: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
