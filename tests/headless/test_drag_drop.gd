extends SceneTree

var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	call_deferred("_run")


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func _run() -> void:
	var game := DeckitGameState.new()
	var hand := DeckitCardZone.new(&"hand")
	var table := DeckitCardZone.new(&"table")
	game.register_zone(hand)
	game.register_zone(table)
	var definition := DeckitCardDefinition.new()
	definition.card_id = &"test"
	definition.display_name = "Visible front"
	DeckitLabCardArt.decorate(definition)
	var card := DeckitCardInstance.new(definition, &"one")
	card.face_up = true
	hand.add_card(card)
	var panel := DeckitZoneView.new()
	panel.free_layout = true
	panel.drag_enabled = true
	panel.drop_enabled = true
	panel.size = Vector2(700, 350)
	root.add_child(panel)
	panel.bind(game, &"table")
	await process_frame
	var data := DeckitCardDrag.new(game, &"hand", card, &"player", Vector2(10, 10))
	check(panel._can_drop_data(Vector2.ZERO, data), "Valid transfer hover")
	check(hand.size() == 1 and table.is_empty(), "Hover never mutates zones")
	check(not panel._can_drop_data(Vector2.ZERO, {}), "Ignore unrelated payload")
	var foreign := DeckitGameState.new()
	check(not data.is_current(foreign), "Reject foreign game")
	panel._drop_on_surface(Vector2(170, 45), data)
	check(hand.is_empty() and table.size() == 1, "Drop transfers exactly once")
	check(not data.is_current(game), "Old drag invalid after movement")
	panel._drop_on_surface(Vector2(200, 50), data)
	check(table.size() == 1, "Duplicate/stale drop cannot duplicate a card")
	await process_frame
	var visual := panel.get_card_view(&"one")
	check(visual != null and visual.icon == definition.front_texture, "Transferred card rendered")
	check(visual._caption.text.contains("Visible front") and visual._side.text.contains("FRONT"), "Separate face label and readable caption")
	var local := DeckitCardDrag.new(game, &"table", card, &"player", Vector2(10, 10))
	panel._drop_on_surface(Vector2(230, 60), local)
	check(panel.card_positions[&"one"].is_equal_approx(Vector2(220, 50)), "Free placement preserves grab offset")
	check(table.size() == 1 and table.peek_top() == card, "Reposition does not change game state")
	panel.set_card_position(&"one", Vector2(-999, 9999))
	check(visual.position.x == 0 and visual.position.y <= 280, "Placement clamped to surface")
	panel.refresh()
	check(panel.get_card_view(&"one") == visual, "Refresh preserves card view")
	var before: Vector2 = visual.position
	panel.drop_enabled = false
	panel._drop_on_surface(Vector2.ZERO, local)
	check(visual.position == before, "Disabled drop preserves position")
	panel.drop_enabled = true
	# A reset may reuse the same ID but creates a different instance.
	table.cards.clear()
	table.add_card(DeckitCardInstance.new(definition, &"one"))
	check(not panel._can_drop_data(Vector2.ZERO, local), "Reset invalidates old instance payload")
	table.capacity = 1
	hand.add_card(card)
	data = DeckitCardDrag.new(game, &"hand", card, &"player")
	check(not panel._can_drop_data(Vector2.ZERO, data), "Full destination refuses hover")
	table.cards.clear()
	var rule := preload("res://tests/headless/deny_all_rule.gd").new()
	game.register_rule(rule)
	check(not panel._can_drop_data(Vector2.ZERO, data), "Game rules govern drop eligibility")
	panel._drop_on_surface(Vector2.ZERO, data)
	check(hand.size() == 1 and table.is_empty(), "Rejected release does not transfer")
	game.rules.clear()
	table.visibility = DeckitCardZone.Visibility.HIDDEN
	panel._drop_on_surface(Vector2.ZERO, data)
	visual = panel.get_card_view(&"one")
	check(not visual.front_revealed and visual.icon == definition.back_texture, "Hidden destination conceals front")
	check(visual._caption.text == "Face down" and visual._side.text.contains("BACK"), "Hidden caption does not leak title")
	panel.free()
	print("[Deckit drag/drop] %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
