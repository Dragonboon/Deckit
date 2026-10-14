extends SceneTree

var checks: int = 0
var errors: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		errors += 1
		push_error("[Deckit visual labs] " + message)


func _run() -> void:
	var front := DeckitLabCardArt.front()
	var back := DeckitLabCardArt.back()
	_check(front != null and back != null, "SVG placeholders load")
	if front != null and back != null:
		_check(front.get_size().x >= 100 and back.get_size().y >= 150, "Card art has useful dimensions")
	var definition := DeckitCardDefinition.new()
	definition.card_id = &"test"
	definition.display_name = "Test Card"
	DeckitLabCardArt.decorate(definition)
	_check(definition.front_texture == front and definition.back_texture == back, "Both card sides assigned")
	var game := DeckitGameState.new()
	var draw := DeckitCardZone.new(&"draw", &"owner")
	draw.visibility = DeckitCardZone.Visibility.HIDDEN
	game.register_zone(draw)
	for i in range(6):
		var instance := DeckitCardInstance.new(definition, StringName("copy-%d" % i))
		instance.face_up = true
		_check(draw.add_card(instance), "Add card")
	var view := DeckitZoneView.new()
	view.max_visible_cards = 2
	root.add_child(view)
	view.bind(game, &"draw", &"owner")
	_check(view.get_card_view(&"copy-0") == null, "Hidden earlier cards not rendered")
	var top_view := view.get_card_view(&"copy-5")
	_check(top_view != null, "Top card rendered")
	if top_view != null:
		_check(top_view.icon == back and top_view.text == "Face down", "Hidden zone uses back")
	draw.visibility = DeckitCardZone.Visibility.PUBLIC
	view.refresh()
	top_view = view.get_card_view(&"copy-5")
	if top_view != null:
		_check(top_view.icon == front and top_view.text == "Test Card", "Face-up zone uses front")
	view.queue_free()
	print("[Deckit visual labs] %d checks, %d failures" % [checks, errors])
	quit(0 if errors == 0 else 1)
