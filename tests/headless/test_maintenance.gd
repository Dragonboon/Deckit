## Regression smoke test for audit-driven changes, Godot 4.7.
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
		push_error("[Deckit maintenance] " + label)


func _run() -> void:
	var catalog := DeckitCardCatalog.new()
	var recipe := DeckitDeckList.new()
	for i in range(80):
		var definition := DeckitCardDefinition.new()
		definition.card_id = StringName("card-%d" % i)
		_check(catalog.add_card(definition) and recipe.add(definition.card_id), "Catalog population")
	_check(DeckitDeckValidator.is_valid(recipe, catalog), "Catalog validation")
	var game := DeckitGameState.new()
	var zone := DeckitCardZone.new(&"table")
	game.register_zone(zone)
	var definition := catalog.find_card(&"card-1")
	definition.display_name = "Shared card"
	var card := DeckitCardInstance.new(definition, &"instance-1")
	card.face_up = true
	_check(zone.add_card(card), "Add runtime card")
	var view := DeckitZoneView.new()
	root.add_child(view)
	view.bind(game, &"table")
	var original: DeckitCardView = view.get_card_view(&"instance-1")
	_check(original != null, "Initial card view")
	view.refresh()
	_check(view.get_card_view(&"instance-1") == original, "Refresh reuses card view")
	var other := DeckitCardInstance.new(catalog.find_card(&"card-2"), &"instance-2")
	_check(zone.add_card(other), "Add second card")
	view.refresh()
	_check(view.get_card_view(&"instance-1") == original and view.get_card_view(&"instance-2") != null, "Incremental views")
	zone.remove_card(card)
	view.refresh()
	_check(view.get_card_view(&"instance-1") == null, "Remove stale card view")
	var deck_pile := DeckitCardPile.new()
	_check(deck_pile.card_at_position(-1) == null and deck_pile.card_at_position(5) == null, "Safe pile indices")
	var original_array: Array = [{"list": [1, 2]}]
	var cloned: Array[Variant] = DeckitUtils.repeat(original_array, 2)
	_check(cloned.size() == 2, "Repeat remains available")
	view.queue_free()
	print("[Deckit maintenance] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
