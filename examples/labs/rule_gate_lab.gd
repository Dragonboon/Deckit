extends Control

const SAMPLE_RULE = preload("res://examples/labs/sample_access_rule.gd")

var game := DeckitGameState.new()
var custom_rule: DeckitCardRule
var current_actor: StringName = &"player-1"
var rule_enabled: bool = true
var status: Label
var state_view: Label
var source_list: ItemList
var selected_id: StringName = &""


func _ready() -> void:
	var page := DeckitLabUI.page(
		self, "02 • Rule Gates",
		"Demonstrate optional policies outside the plugin: card tags, actor eligibility, and zone capacity. Selecting a card does not bypass GameState.perform()."
	)
	var buttons := DeckitLabUI.controls(page)
	DeckitLabUI.button(buttons, "Attempt transfer", _attempt)
	DeckitLabUI.button(buttons, "Toggle custom rule", _toggle_rule)
	DeckitLabUI.button(buttons, "Switch acting player", _toggle_actor)
	DeckitLabUI.button(buttons, "Return top card", _return_card)
	DeckitLabUI.button(buttons, "Reset", _reset)
	DeckitLabUI.heading(page, "Source cards (select one)")
	source_list = ItemList.new()
	source_list.custom_minimum_size = Vector2(600, 158)
	source_list.item_selected.connect(_on_select)
	page.add_child(source_list)
	state_view = DeckitLabUI.info(page, "")
	status = DeckitLabUI.info(page, "")
	custom_rule = SAMPLE_RULE.new()
	game.action_applied.connect(_applied)
	game.action_rejected.connect(_rejected)
	_reset()


func _reset() -> void:
	game.zones.clear()
	game.rules.clear()
	rule_enabled = true
	current_actor = &"player-1"
	selected_id = &""
	var source := DeckitCardZone.new(&"collection", &"player-1")
	var destination := DeckitCardZone.new(&"play", &"player-1")
	destination.capacity = 2
	game.register_zone(source)
	game.register_zone(destination)
	for entry in [
		{"id": "allowed-a", "tag": "allowed", "name": "Approved A"},
		{"id": "blocked-b", "tag": "blocked", "name": "Restricted B"},
		{"id": "allowed-c", "tag": "allowed", "name": "Approved C"},
		{"id": "allowed-d", "tag": "allowed", "name": "Approved D"}
	]:
		var definition := DeckitCardDefinition.new()
		definition.card_id = StringName(entry["id"])
		definition.display_name = entry["name"]
		definition.tags = PackedStringArray([entry["tag"]])
		source.add_card(DeckitCardInstance.new(definition, StringName(entry["id"])))
	game.register_rule(custom_rule)
	status.text = "Try a restricted card, an unauthorized actor, or filling the destination."
	_refresh()


func _on_select(index: int) -> void:
	var cards := game.get_zone(&"collection").cards
	if index >= 0 and index < cards.size():
		selected_id = cards[index].instance_id


func _attempt() -> void:
	var source := game.get_zone(&"collection")
	var card := source.find_by_id(selected_id)
	if card == null:
		card = source.peek_top()
	if card == null:
		status.text = "Collection is empty."
		return
	game.perform(DeckitCardAction.new(
		&"collection", &"play", card.instance_id, current_actor
	))
	_refresh()


func _return_card() -> void:
	var destination := game.get_zone(&"play")
	var card := destination.peek_top()
	if card == null:
		status.text = "The play zone is empty."
		return
	game.perform(DeckitCardAction.new(&"play", &"collection", card.instance_id, current_actor))
	_refresh()


func _toggle_rule() -> void:
	rule_enabled = not rule_enabled
	if rule_enabled:
		game.register_rule(custom_rule)
	else:
		game.rules.erase(custom_rule)
	status.text = "Custom policy %s. Destination capacity is always enforced by the core." % [
		"enabled" if rule_enabled else "disabled"
	]
	_refresh()


func _toggle_actor() -> void:
	current_actor = &"player-2" if current_actor == &"player-1" else &"player-1"
	status.text = "Acting player changed."
	_refresh()


func _applied(action: DeckitCardAction) -> void:
	status.text = "ALLOWED: %s moved into %s." % [
		action.card_instance_id, action.destination_zone_id
	]


func _rejected(action: DeckitCardAction) -> void:
	status.text = "DENIED: %s → %s. Check tag, actor or zone capacity." % [
		action.card_instance_id, action.destination_zone_id
	]


func _refresh() -> void:
	source_list.clear()
	for index in range(game.get_zone(&"collection").cards.size()):
		var card := game.get_zone(&"collection").cards[index]
		source_list.add_item("%s — tag:%s" % [card.definition.display_name, card.definition.tags[0]])
		if card.instance_id == selected_id:
			source_list.select(index)
	state_view.text = "Actor: %s | Policy: %s | Collection: %d | Play: %d / %d\nCards in play: %s" % [
		current_actor,
		"enabled" if rule_enabled else "disabled",
		game.get_zone(&"collection").size(),
		game.get_zone(&"play").size(),
		game.get_zone(&"play").capacity,
		_str_cards(game.get_zone(&"play"))
	]


func _str_cards(zone: DeckitCardZone) -> String:
	var names: PackedStringArray = []
	for card in zone.cards:
		names.append(card.definition.display_name)
	return ", ".join(names) if not names.is_empty() else "(empty)"
