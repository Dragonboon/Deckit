extends Control

const ZONE_IDS: Array[StringName] = [&"draw", &"hand", &"table", &"discard"]

var game := DeckitGameState.new()
var randomizer := RandomNumberGenerator.new()
var lists: Dictionary[StringName, ItemList] = {}
var counts: Dictionary[StringName, Label] = {}
var selection: Dictionary[StringName, StringName] = {}
var status: Label
var visual_zones: Array[DeckitZoneView] = []


func _ready() -> void:
	randomizer.seed = 314159
	var page := DeckitLabUI.page(
		self, "01 • Zone Flow",
		"Move instance IDs between four independent zones. Select a card in a list or use its top card. No turn, suit or combat rules are imposed."
	)
	var actions := DeckitLabUI.controls(page)
	DeckitLabUI.button(actions, "Draw to hand", _transfer.bind(&"draw", &"hand"))
	DeckitLabUI.button(actions, "Move to table", _transfer.bind(&"hand", &"table"))
	DeckitLabUI.button(actions, "Discard from table", _transfer.bind(&"table", &"discard"))
	DeckitLabUI.button(actions, "Recycle discard", _transfer.bind(&"discard", &"draw"))
	DeckitLabUI.button(actions, "Shuffle draw", _shuffle)
	DeckitLabUI.button(actions, "Flip selected", _flip)
	DeckitLabUI.button(actions, "+1 counter", _add_counter)
	DeckitLabUI.button(actions, "Reset", _reset)

	var zones_row := HBoxContainer.new()
	zones_row.add_theme_constant_override("separation", 12)
	page.add_child(zones_row)
	for zone_id in ZONE_IDS:
		var panel := VBoxContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		zones_row.add_child(panel)
		var label := DeckitLabUI.heading(panel, String(zone_id).capitalize())
		counts[zone_id] = label
		var item_list := ItemList.new()
		item_list.custom_minimum_size = Vector2(170, 230)
		item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_list.item_selected.connect(_on_selected.bind(zone_id))
		panel.add_child(item_list)
		lists[zone_id] = item_list
	var visual_row := DeckitLabCardArt.zone_row(page)
	for id in ZONE_IDS:
		var view := DeckitLabCardArt.zone_panel(visual_row, game, id, &"demo", 2)
		visual_zones.append(view)
	status = DeckitLabUI.info(page, "")
	game.action_applied.connect(_on_applied)
	game.action_rejected.connect(_on_rejected)
	_reset()


func _reset() -> void:
	game.zones.clear()
	selection.clear()
	for id in ZONE_IDS:
		game.register_zone(DeckitCardZone.new(id, &"demo"))
	game.get_zone(&"hand").capacity = 5
	var definitions: Array[DeckitCardDefinition] = []
	for index in range(3):
		var definition := DeckitCardDefinition.new()
		definition.card_id = StringName("sample-%d" % index)
		definition.display_name = "Sample %s" % char(65 + index)
		definition.tags = PackedStringArray(["demo", "group-%d" % index])
		definition.attributes = {"cost": index, "power": index + 1}
		DeckitLabCardArt.decorate(definition)
		definitions.append(definition)
	for index in range(9):
		var card := DeckitCardInstance.new(
			definitions[index % definitions.size()],
			StringName("instance-%02d" % (index + 1))
		)
		card.face_up = true
		card.owner_id = &"demo"
		card.controller_id = &"demo"
		game.get_zone(&"draw").add_card(card)
	status.text = "Reset: 9 unique card instances share 3 definitions. Hand capacity: 5."
	for index in range(visual_zones.size()):
		visual_zones[index].bind(game, ZONE_IDS[index], &"demo")
	_refresh()


func _on_selected(index: int, zone_id: StringName) -> void:
	var zone := game.get_zone(zone_id)
	if index >= 0 and index < zone.cards.size():
		selection[zone_id] = zone.cards[index].instance_id


func _chosen(zone_id: StringName) -> DeckitCardInstance:
	var zone := game.get_zone(zone_id)
	var card: DeckitCardInstance = zone.find_by_id(selection.get(zone_id, &""))
	return card if card != null else zone.peek_top()


func _transfer(source: StringName, destination: StringName) -> void:
	var card := _chosen(source)
	if card == null:
		status.text = "Nothing to move from %s." % source
		return
	var action := DeckitCardAction.new(source, destination, card.instance_id, &"demo")
	if game.perform(action):
		selection.erase(source)
		selection[destination] = card.instance_id
	_refresh()


func _shuffle() -> void:
	game.get_zone(&"draw").shuffle_with_rng(randomizer)
	selection.erase(&"draw")
	status.text = "Shuffled with caller-owned RNG seed 314159 (no global randomizer)."
	_refresh()


func _flip() -> void:
	var card := _first_chosen()
	if card == null:
		status.text = "Select a card in a zone to flip it."
		return
	card.face_up = not card.face_up
	status.text = "Toggled face for %s." % card.instance_id
	_refresh()


func _add_counter() -> void:
	var card := _first_chosen()
	if card == null:
		status.text = "Select a card in a zone to add a counter."
		return
	card.change_counter(&"marker", 1)
	status.text = "Marker added to %s." % card.instance_id
	_refresh()


func _first_chosen() -> DeckitCardInstance:
	for zone_id in [&"hand", &"table", &"discard", &"draw"]:
		var zone := game.get_zone(zone_id)
		var card: DeckitCardInstance = zone.find_by_id(selection.get(zone_id, &""))
		if card != null:
			return card
	return null


func _on_applied(action: DeckitCardAction) -> void:
	status.text = "OK: %s moved %s → %s." % [
		action.card_instance_id, action.source_zone_id, action.destination_zone_id
	]


func _on_rejected(action: DeckitCardAction) -> void:
	status.text = "REJECTED: %s → %s (missing card, duplicate or destination full)." % [
		action.source_zone_id, action.destination_zone_id
	]


func _refresh() -> void:
	for view in visual_zones:
		view.refresh()
	for zone_id in ZONE_IDS:
		var zone := game.get_zone(zone_id)
		var display := lists[zone_id]
		display.clear()
		counts[zone_id].text = "%s (%d)" % [String(zone_id).capitalize(), zone.size()]
		for index in range(zone.cards.size()):
			var card: DeckitCardInstance = zone.cards[index]
			display.add_item("%s %s • %s • markers:%d" % [
				card.definition.display_name,
				card.instance_id,
				"up" if card.face_up else "down",
				card.get_counter(&"marker")
			])
			if card.instance_id == selection.get(zone_id, &""):
				display.select(index)
