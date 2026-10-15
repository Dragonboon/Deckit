## A complete local tabletop: validated zone transfers and UI-only free positions.
extends Control

const IDS: Array[StringName] = [&"draw", &"hand", &"table", &"discard"]
var game := DeckitGameState.new()
var views: Dictionary[StringName, DeckitZoneView] = {}
var selected_zone: StringName = &""
var selected_id: StringName = &""
var status: Label
var selection_label: Label
var chosen_buttons: Array[Button] = []
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	var page := DeckitLabUI.page(self, "01 · Tabletop / Mesa",
		"Draw → play → discard. Drag cards between zones; on the table, place them anywhere. A cancelled or illegal drop changes nothing.")
	DeckitLabUI.info(page, "Try: draw two cards, drag one onto the table, move it again, then flip it. FRONT/FRENTE is light; BACK/DORSO is navy. Hand capacity is 5.")
	var controls := DeckitLabUI.controls(page)
	DeckitLabUI.button(controls, "Draw a card", _draw_card)
	for id in [&"hand", &"table", &"discard", &"draw"]:
		chosen_buttons.append(DeckitLabUI.button(controls, "Move selected → %s" % id, _move_selected.bind(id)))
	chosen_buttons.append(DeckitLabUI.button(controls, "Flip selected", _flip))
	chosen_buttons.append(DeckitLabUI.button(controls, "+1 marker", _counter))
	DeckitLabUI.button(controls, "Shuffle draw", _shuffle)
	DeckitLabUI.button(controls, "Reset", _reset)
	selection_label = DeckitLabUI.info(page, "")
	status = DeckitLabUI.info(page, "")
	var row := DeckitLabCardArt.zone_row(page)
	for id in [&"draw", &"hand", &"discard"]:
		var view := DeckitLabCardArt.zone_panel(row, game, id, &"demo", 0 if id == &"hand" else 1)
		_setup_view(view, id)
	DeckitLabUI.heading(page, "TABLE · Drag to arrange freely / Arrow keys move a selected card")
	var surface := PanelContainer.new()
	page.add_child(surface)
	var table := DeckitZoneView.new()
	table.free_layout = true
	table.table_height = 260
	surface.add_child(table)
	_setup_view(table, &"table")
	DeckitLabUI.info(page, "Keyboard: Tab to a card, Enter/Space to select, then use the move/flip buttons. Select a table card and use arrow keys to reposition it. Integration: docs/RECIPES.md (#1–3).")
	game.action_rejected.connect(func(_action: DeckitCardAction) -> void:
		status.text = "Move refused: card missing, same zone or destination full. Original position preserved.")
	_reset()


func _setup_view(view: DeckitZoneView, id: StringName) -> void:
	view.drag_enabled = true
	view.drop_enabled = true
	view.actor_id = &"demo"
	view.card_requested.connect(_select)
	view.drop_completed.connect(func(action: DeckitCardAction, accepted: bool) -> void:
		if accepted:
			_select(action.destination_zone_id, action.card_instance_id)
			status.text = "Placed in %s. Zone rules still apply; coordinates are presentation only." % action.destination_zone_id)
	views[id] = view


func _reset() -> void:
	game.zones.clear()
	for id in IDS:
		game.register_zone(DeckitCardZone.new(id, &"demo"))
	game.get_zone(&"draw").visibility = DeckitCardZone.Visibility.HIDDEN
	game.get_zone(&"hand").capacity = 5
	for i in range(8):
		var definition := DeckitCardDefinition.new()
		definition.card_id = StringName("sample-%d" % i)
		definition.display_name = "Card %s" % char(65 + i)
		DeckitLabCardArt.decorate(definition)
		var card := DeckitCardInstance.new(definition, StringName("copy-%d" % i))
		card.face_up = true
		card.owner_id = &"demo"
		game.get_zone(&"draw").add_card(card)
	for id in views:
		views[id].card_positions.clear()
		views[id].bind(game, id, &"demo")
	selected_zone = &""
	selected_id = &""
	rng.seed = 314159
	_sync()
	status.text = "Ready: draw or drag the top card. Hidden draw pile deliberately shows the back."


func _select(zone: StringName, id: StringName) -> void:
	selected_zone = zone
	selected_id = id
	_sync()
	var card_view := views[zone].get_card_view(id)
	if card_view != null:
		card_view.grab_focus()


func _sync() -> void:
	for id in views:
		var chosen: Array[StringName] = []
		if id == selected_zone:
			chosen.append(selected_id)
		views[id].set_selected_cards(chosen)
	var valid: bool = game.get_zone(selected_zone) != null and game.get_zone(selected_zone).find_by_id(selected_id) != null
	for button in chosen_buttons:
		button.disabled = not valid
	selection_label.text = "Selected: %s · %s" % [selected_id, selected_zone] if valid else "Select any card to use the buttons. Dragging does not require prior selection."


func _draw_card() -> void:
	var card := game.get_zone(&"draw").peek_top()
	if card == null:
		status.text = "Draw pile empty. Move cards from discard back to draw or reset."
		return
	_select(&"draw", card.instance_id)
	_move_selected(&"hand")


func _move_selected(destination: StringName) -> void:
	if game.perform(DeckitCardAction.new(selected_zone, destination, selected_id, &"demo")):
		_select(destination, selected_id)
		status.text = "Moved to %s." % destination


func _flip() -> void:
	var target := DeckitCardTarget.new(selected_zone, selected_id)
	game.perform(DeckitEffectAction.new().configure(DeckitFaceEffect.new(), target, &"demo"))
	status.text = "Face toggled. Hidden zones continue concealing the front."


func _counter() -> void:
	var effect := DeckitCounterEffect.new()
	effect.counter_key = &"marker"
	effect.delta = 1
	game.perform(DeckitEffectAction.new().configure(effect, DeckitCardTarget.new(selected_zone, selected_id), &"demo"))


func _shuffle() -> void:
	game.get_zone(&"draw").shuffle_with_rng(rng)
	views[&"draw"].refresh()
	status.text = "Draw pile shuffled with a caller-owned RNG."


func _input(event: InputEvent) -> void:
	if selected_zone != &"table" or not event is InputEventKey or not event.is_pressed():
		return
	if get_viewport().gui_get_focus_owner() != views[&"table"].get_card_view(selected_id):
		return
	var direction := Vector2.ZERO
	if event.is_action("ui_left"): direction.x = -1
	elif event.is_action("ui_right"): direction.x = 1
	elif event.is_action("ui_up"): direction.y = -1
	elif event.is_action("ui_down"): direction.y = 1
	if direction != Vector2.ZERO:
		var view: DeckitZoneView = views[&"table"]
		view.set_card_position(selected_id, view.card_positions.get(selected_id, Vector2.ZERO) + direction * 16)
		get_viewport().set_input_as_handled()
