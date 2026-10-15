## Routes actual GUI mouse events through Godot's Control drag-and-drop engine.
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


func mouse(point: Vector2, pressed: bool, motion: bool = false) -> void:
	var event: InputEventMouse
	if motion:
		var move := InputEventMouseMotion.new()
		move.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		move.relative = Vector2(30, 10)
		event = move
	else:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event = click
	event.position = point
	event.global_position = point
	root.push_input(event, true)
	await process_frame


func _run() -> void:
	var game := DeckitGameState.new()
	var hand := DeckitCardZone.new(&"hand")
	var table := DeckitCardZone.new(&"table")
	game.register_zone(hand)
	game.register_zone(table)
	var definition := DeckitCardDefinition.new()
	definition.card_id = &"test"
	definition.display_name = "Drag me"
	DeckitLabCardArt.decorate(definition)
	var card := DeckitCardInstance.new(definition, &"drag")
	card.face_up = true
	hand.add_card(card)
	var source := DeckitZoneView.new()
	source.drag_enabled = true
	source.position = Vector2(20, 20)
	source.size = Vector2(200, 260)
	root.add_child(source)
	source.bind(game, &"hand")
	var destination := DeckitZoneView.new()
	destination.free_layout = true
	destination.drag_enabled = true
	destination.drop_enabled = true
	destination.position = Vector2(300, 20)
	destination.size = Vector2(700, 350)
	root.add_child(destination)
	destination.bind(game, &"table")
	for i in range(5): await process_frame
	var view := source.get_card_view(&"drag")
	var start := view.global_position + Vector2(35, 40)
	await mouse(start, false, true)
	await mouse(start, true)
	await mouse(start + Vector2(35, 10), true, true)
	check(root.gui_is_dragging(), "Native drag begins after mouse threshold")
	var target := destination._cards_row.global_position + Vector2(170, 80)
	await mouse(target, true, true)
	await mouse(target, false)
	check(table.size() == 1 and hand.is_empty(), "Native release transfers into empty surface")
	if table.size() == 1:
		view = destination.get_card_view(&"drag")
		start = view.global_position + Vector2(35, 40)
		var before: Vector2 = view.position
		await mouse(start, false, true)
		await mouse(start, true)
		await mouse(start + Vector2(35, 10), true, true)
		await mouse(Vector2(1100, 700), true, true)
		await mouse(Vector2(1100, 700), false)
		check(view.position == before and table.size() == 1, "Drop outside leaves card in original position")
	source.free()
	destination.free()
	print("[Deckit native drag] %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
