## Shared lightweight GUI for three independent microgames.
extends Control

@export_enum("Spanish Tricks", "French Melds", "Resource Duel") var scenario: int = 0

var match_state: RefCounted
var cards_list: ItemList
var card_images: HFlowContainer
var chosen_ids: Array[StringName] = []
var status: Label
var stats: Label


func _ready() -> void:
	var names: Array[String] = ["Spanish Tricks", "French Melds", "Resource Duel"]
	var page := DeckitLabUI.page(self, "Playable • " + names[scenario],
		"Original small ruleset using generic Deckit components. Click cards, make a move, and reset to repeat.")
	var controls := DeckitLabUI.controls(page)
	if scenario == 1:
		DeckitLabUI.button(controls, "Submit 3 selected cards", _play)
	else:
		DeckitLabUI.button(controls, "Play selected", _play)
	if scenario == 2:
		DeckitLabUI.button(controls, "End turn", _end_turn)
	DeckitLabUI.button(controls, "Restart", _reset)
	DeckitLabUI.heading(page, "Available cards")
	DeckitLabUI.heading(page, "Cards (click to select)")
	card_images = DeckitLabCardArt.zone_row(page)
	cards_list = ItemList.new()
	cards_list.custom_minimum_size = Vector2(500, 100)
	cards_list.select_mode = ItemList.SELECT_MULTI if scenario == 1 else ItemList.SELECT_SINGLE
	cards_list.item_selected.connect(_selected_index)
	cards_list.multi_selected.connect(_multi_selected)
	cards_list.tooltip_text = "Select a card using the mouse or keyboard. For French Melds select three."
	page.add_child(cards_list)
	stats = DeckitLabUI.info(page, "")
	status = DeckitLabUI.info(page, "")
	_reset()


func _reset() -> void:
	match scenario:
		0:
			match_state = DeckitDemoSpanishTricks.new()
		1:
			match_state = DeckitDemoFrenchMelds.new()
		2:
			match_state = DeckitDemoResourceDuel.new()
	if not match_state.setup():
		status.text = "Could not initialize this example. Check Godot Output."
	else:
		_refresh()


func _cards() -> Array[DeckitCardInstance]:
	match scenario:
		0:
			if match_state.finished:
				return []
			return match_state.get_hand(match_state.turns.current_participant())
		1:
			return match_state.get_hand()
		2:
			return match_state.hand_cards()
	return []


func _selected_index(index: int) -> void:
	if scenario != 1:
		chosen_ids.clear()
		var cards: Array[DeckitCardInstance] = _cards()
		if index >= 0 and index < cards.size():
			chosen_ids.append(cards[index].instance_id)


func _multi_selected(index: int, selected: bool) -> void:
	if scenario != 1:
		return
	var cards: Array[DeckitCardInstance] = _cards()
	if index >= 0 and index < cards.size():
		if selected and not chosen_ids.has(cards[index].instance_id):
			chosen_ids.append(cards[index].instance_id)
		elif not selected:
			chosen_ids.erase(cards[index].instance_id)


func _play() -> void:
	var cards: Array[DeckitCardInstance] = _cards()
	var selected: PackedInt32Array = cards_list.get_selected_items()
	var ok: bool = false
	if scenario == 1:
		if selected.size() == 3:
			var ids: Array[StringName] = []
			for index: int in selected:
				if index >= 0 and index < cards.size():
					ids.append(cards[index].instance_id)
			ok = match_state.submit(ids) if ids.size() == 3 else false
	else:
		if selected.size() == 1 and selected[0] < cards.size():
			ok = match_state.play(cards[selected[0]].instance_id)
	if not ok and not match_state.finished:
		status.text = "Move unavailable. Select a valid card or combination. " + match_state.last_message
	_refresh()


func _end_turn() -> void:
	if scenario == 2:
		match_state.end_turn()
		_refresh()


func _refresh() -> void:
	chosen_ids.clear()
	for child in card_images.get_children():
		card_images.remove_child(child)
		child.queue_free()
	cards_list.clear()
	for card: DeckitCardInstance in _cards():
		DeckitLabCardArt.decorate(card.definition)
		var view := DeckitLabCardArt.card_button(card_images, card, true)
		view.card_requested.connect(_on_card_requested)
		var extra: String = ""
		if scenario == 2:
			extra = " (cost: %d)" % int(card.get_attribute(&"cost", 0))
		cards_list.add_item(card.definition.display_name + extra)
	status.text = match_state.last_message
	match scenario:
		0:
			stats.text = "Turn: %s | Trump: %s | Tricks: %d / 3 | P1: %d | P2: %d%s" % [
				match_state.turns.current_participant(), match_state.trump_suit,
				match_state.tricks_played, match_state.ledger.get_value(&"p1", &"tricks"),
				match_state.ledger.get_value(&"p2", &"tricks"),
				" | FINISHED" if match_state.finished else ""
			]
		1:
			stats.text = "Attempts: %d / 3 | Score: %d%s" % [
				match_state.attempts, match_state.ledger.get_value(&"solo", &"score"),
				" | FINISHED" if match_state.finished else ""
			]
		2:
			stats.text = "Turn: %d | Energy: %d | Health: %d | Shield: %d | Rival: %d%s" % [
				match_state.turns.turn_number,
				match_state.ledger.get_value(&"pilot", &"energy"),
				match_state.ledger.get_value(&"pilot", &"health"),
				match_state.ledger.get_value(&"pilot", &"shield"),
				match_state.ledger.get_value(&"rival", &"health"),
				" | FINISHED" if match_state.finished else ""
			]


func _on_card_requested(instance_id: StringName) -> void:
	var cards: Array[DeckitCardInstance] = _cards()
	for index in range(cards.size()):
		if cards[index].instance_id == instance_id:
			if scenario == 1:
				var is_selected: bool = cards_list.is_selected(index)
				if is_selected:
					cards_list.deselect(index)
				else:
					cards_list.select(index, false)
				_multi_selected(index, not is_selected)
			else:
				cards_list.select(index)
				_selected_index(index)
			return
