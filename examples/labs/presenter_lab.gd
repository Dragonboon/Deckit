## End-to-end example of the UI-independent state and optional card renderer.
## All game setup and actions stay in this lab rather than in addons/deckit/.
extends Control

var game := DeckitGameState.new()
var draw_zone := DeckitCardZone.new(&"draw", &"player-1")
var hand_zone := DeckitCardZone.new(&"hand", &"player-1")
var table_zone := DeckitCardZone.new(&"table", &"player-1")
var discard_zone := DeckitCardZone.new(&"discard", &"player-1")

var views: Array[DeckitZoneView] = []
var selected_zone_id: StringName = &""
var selected_card_id: StringName = &""
var viewer_id: StringName = &"player-1"
var status: Label


func _ready() -> void:
	var page := DeckitLabUI.page(
		self, "04 • State ↔ Presentation",
		"Selectable card views reflect authoritative zones. Buttons request validated actions; renderers do not modify cards or bypass game rules."
	)
	var tools := DeckitLabUI.controls(page)
	DeckitLabUI.button(tools, "Draw", _move_top.bind(&"draw", &"hand"))
	DeckitLabUI.button(tools, "Play selected", _move_selection.bind(&"hand", &"table"))
	DeckitLabUI.button(tools, "Discard selected", _move_selection.bind(&"table", &"discard"))
	DeckitLabUI.button(tools, "Recycle discard", _move_top.bind(&"discard", &"draw"))
	DeckitLabUI.button(tools, "Flip selected", _flip_selected)
	DeckitLabUI.button(tools, "Add counter", _count_selected)
	DeckitLabUI.button(tools, "Swap viewer", _swap_viewer)
	DeckitLabUI.button(tools, "Reset", _reset)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	page.add_child(grid)
	for target_id in [&"draw", &"hand", &"table", &"discard"]:
		var surface := PanelContainer.new()
		surface.custom_minimum_size = Vector2(300, 170)
		grid.add_child(surface)
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 12)
		surface.add_child(margin)
		var view := DeckitZoneView.new()
		view.max_visible_cards = 3
		margin.add_child(view)
		view.card_requested.connect(_on_requested)
		views.append(view)

	status = DeckitLabUI.info(page, "")
	game.action_applied.connect(_applied)
	game.action_rejected.connect(_rejected)
	_reset()


func _reset() -> void:
	game.zones.clear()
	selected_zone_id = &""
	selected_card_id = &""
	viewer_id = &"player-1"
	draw_zone.cards.clear()
	hand_zone.cards.clear()
	table_zone.cards.clear()
	discard_zone.cards.clear()

	draw_zone.visibility = DeckitCardZone.Visibility.HIDDEN
	hand_zone.visibility = DeckitCardZone.Visibility.OWNER_ONLY
	hand_zone.capacity = 3
	table_zone.visibility = DeckitCardZone.Visibility.PUBLIC
	discard_zone.visibility = DeckitCardZone.Visibility.PUBLIC
	for zone in [draw_zone, hand_zone, table_zone, discard_zone]:
		game.register_zone(zone)

	for index in range(6):
		var definition := DeckitCardDefinition.new()
		definition.card_id = StringName("sample-%d" % (index % 3))
		definition.display_name = "Card %s" % char(65 + index % 3)
		definition.attributes = {"value": index % 3 + 1}
		DeckitLabCardArt.decorate(definition)
		var card := DeckitCardInstance.new(definition, StringName("copy-%02d" % (index + 1)))
		card.face_up = true
		card.owner_id = &"player-1"
		card.controller_id = &"player-1"
		draw_zone.add_card(card)

	var ids: Array[StringName] = [&"draw", &"hand", &"table", &"discard"]
	for index in range(views.size()):
		views[index].bind(game, ids[index], viewer_id)
	status.text = "Reset: 6 unique instances. Hand capacity is 3; its contents are visible only to player-1 in this lab."


func _on_requested(zone_id: StringName, instance_id: StringName) -> void:
	selected_zone_id = zone_id
	selected_card_id = instance_id
	status.text = "Selected %s in %s. Use a button to request an action." % [
		instance_id, zone_id
	]


func _move_top(source_id: StringName, destination_id: StringName) -> void:
	var source := game.get_zone(source_id)
	var card := source.peek_top()
	if card == null:
		status.text = "Nothing available in %s." % source_id
		return
	_move(source_id, destination_id, card.instance_id)


func _move_selection(source_id: StringName, destination_id: StringName) -> void:
	if selected_zone_id != source_id:
		status.text = "Select a card from %s first." % source_id
		return
	_move(source_id, destination_id, selected_card_id)


func _move(source_id: StringName, destination_id: StringName, instance_id: StringName) -> void:
	if game.perform(DeckitCardAction.new(source_id, destination_id, instance_id, &"player-1")):
		selected_zone_id = &""
		selected_card_id = &""


func _selected() -> DeckitCardInstance:
	var zone := game.get_zone(selected_zone_id)
	if zone == null:
		return null
	return zone.find_by_id(selected_card_id)


func _flip_selected() -> void:
	var card := _selected()
	if card == null:
		status.text = "Select a card first."
		return
	card.face_up = not card.face_up
	status.text = "Changed face state of %s (game-owned edit; refresh explicitly)." % selected_card_id
	_refresh_views()


func _count_selected() -> void:
	var card := _selected()
	if card == null:
		status.text = "Select a card first."
		return
	card.change_counter(&"marker", 1)
	status.text = "Counter incremented on %s." % selected_card_id
	_refresh_views()


func _swap_viewer() -> void:
	viewer_id = &"spectator" if viewer_id == &"player-1" else &"player-1"
	for view in views:
		view.set_viewer(viewer_id)
	status.text = "Viewer: %s. Hidden deck remains concealed; hand uses OWNER_ONLY policy." % viewer_id


func _refresh_views() -> void:
	for view in views:
		view.refresh()


func _applied(action: DeckitCardAction) -> void:
	status.text = "Accepted %s: %s → %s; visible zones refreshed by action_applied." % [
		action.card_instance_id, action.source_zone_id, action.destination_zone_id
	]


func _rejected(action: DeckitCardAction) -> void:
	status.text = "Rejected %s: %s → %s; views and state remain unchanged." % [
		action.card_instance_id, action.source_zone_id, action.destination_zone_id
	]
