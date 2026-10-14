## Run: godot --headless --path . --script res://tests/headless/test_presentation.gd
extends SceneTree

var failed: int = 0
var passed: int = 0


func _check(value: bool, detail: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error("[Deckit presentation] " + detail)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var definition := DeckitCardDefinition.new()
	definition.display_name = "Example secret"
	var card := DeckitCardInstance.new(definition, &"unique-1")
	card.face_up = true
	var game := DeckitGameState.new()
	var source := DeckitCardZone.new(&"hand", &"owner")
	var destination := DeckitCardZone.new(&"table", &"owner")
	source.visibility = DeckitCardZone.Visibility.OWNER_ONLY
	destination.visibility = DeckitCardZone.Visibility.PUBLIC
	_check(game.register_zone(source), "Register source")
	_check(game.register_zone(destination), "Register destination")
	_check(source.add_card(card), "Insert card")
	var view := DeckitZoneView.new()
	root.add_child(view)
	view.bind(game, &"hand", &"spectator")
	_check(view.get_card_view(card.instance_id) != null, "Create card view")
	_check(view.get_card_view(card.instance_id).text == "Face down", "Conceal owner-only card")
	view.set_viewer(&"owner")
	_check(view.get_card_view(card.instance_id).text == "Example secret", "Reveal owner's card")
	view.set_viewer(&"spectator")
	_check(view.get_card_view(card.instance_id).text == "Face down", "Hide after viewer swap")
	var action := DeckitCardAction.new(&"hand", &"table", card.instance_id)
	_check(game.perform(action), "Move card via validated action")
	_check(view.get_card_view(card.instance_id) == null, "Presenter follows move out of zone")
	view.bind(game, &"table", &"spectator")
	_check(view.get_card_view(card.instance_id).text == "Example secret", "Public face-up card visible")
	card.face_up = false
	view.refresh()
	_check(view.get_card_view(card.instance_id).text == "Face down", "Public face-down card hidden")
	view.queue_free()
	print("[Deckit presentation] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
