extends Control

const CARD_SCENE: PackedScene = preload("res://addons/deckit/src/components/ui/playing_card_ui.tscn")



var hand: DeckitCardHand
var pile: DeckitCardPile
var info: Label
var cards_created: int = 0


func _ready() -> void:
	var page := DeckitLabUI.page(
		self, "03 • Legacy Visual Components",
		"Standalone presentation experiment: the original DeckitCardHand, DeckitCardPile and DeckitPlayingCardUI nodes. This is not yet bound to the headless zones."
	)
	var actions := DeckitLabUI.controls(page)
	DeckitLabUI.button(actions, "Add card to hand", _add_card)
	DeckitLabUI.button(actions, "Hand: horizontal", _set_layout.bind(DeckitCardHand.Layouts.Horizontal))
	DeckitLabUI.button(actions, "Hand: irregular fan", _set_layout.bind(DeckitCardHand.Layouts.IrregularFan))
	DeckitLabUI.button(actions, "Hand: arc", _set_layout.bind(DeckitCardHand.Layouts.PerfectArcFan))
	DeckitLabUI.button(actions, "Send last card to pile", _move_to_pile)
	DeckitLabUI.button(actions, "Remove top of pile", _remove_top)
	DeckitLabUI.button(actions, "Flip top of pile", _flip_top)
	DeckitLabUI.button(actions, "Reset", _reset)
	info = DeckitLabUI.info(page, "The visuals use bundled SVG artwork; no external assets or game-specific card set.")
	var surface := PanelContainer.new()
	surface.custom_minimum_size = Vector2(720, 280)
	page.add_child(surface)
	var field := Control.new()
	field.custom_minimum_size = Vector2(720, 280)
	surface.add_child(field)
	hand = DeckitCardHand.new()
	hand.position = Vector2(140, 175)
	hand.maximum_cards = 0
	hand.maximum_selected_cards = 0
	hand.horizontal_separation = Vector2(57, 0)
	hand.horizontal_min_rotation_angle = 0.0
	hand.horizontal_max_rotation_angle = 0.0
	field.add_child(hand)
	pile = preload("res://addons/deckit/src/components/ui/card_pile.tscn").instantiate()
	pile.position = Vector2(565, 130)
	pile.maximum_cards_in_pile = 0
	pile.min_rotation_on_card_dropped = 0.0
	pile.max_rotation_on_card_dropped = 0.0
	pile.top_card_can_be_dragged = false
	field.add_child(pile)
	var hand_label := Label.new()
	hand_label.text = "HAND"
	hand_label.position = Vector2(20, 20)
	field.add_child(hand_label)
	var pile_label := Label.new()
	pile_label.text = "PILE"
	pile_label.position = Vector2(530, 20)
	field.add_child(pile_label)
	call_deferred("_reset")


func _make_card() -> DeckitPlayingCardUI:
	cards_created += 1
	var data := DeckitPlayingCard.new()
	data.id = StringName("sample-%d" % cards_created)
	data.display_name = "Sample %d" % cards_created
	data.value = float(cards_created % 7 + 1)
	data.suit = DeckitPlayingCard.Suits.Heart
	data.front_texture = DeckitLabCardArt.front()
	data.back_texture = DeckitLabCardArt.back()
	data.texture_size = Vector2(72, 100)
	var visual: DeckitPlayingCardUI = CARD_SCENE.instantiate()
	visual.card = data
	return visual


func _add_card() -> void:
	if hand == null:
		return
	var card := _make_card()
	hand.add_card(card)
	call_deferred("_update_info")


func _set_layout(mode: DeckitCardHand.Layouts) -> void:
	hand.display_layout_mode = mode
	hand.update_hand_display_layout()
	_update_info()


func _move_to_pile() -> void:
	if hand.current_cards.is_empty():
		info.text = "Nothing left in the hand."
		return
	var card: DeckitPlayingCardUI = hand.current_cards.back()
	hand.remove_card(card)
	pile.add_card(card)
	call_deferred("_update_info")


func _remove_top() -> void:
	var card := pile.top_card()
	if card == null:
		info.text = "Pile is empty."
		return
	pile.remove_card(card)
	card.queue_free()
	call_deferred("_update_info")


func _flip_top() -> void:
	var card := pile.top_card()
	if card == null:
		info.text = "Pile is empty."
		return
	card.toggle_orientation()
	_update_info()


func _reset() -> void:
	if hand == null:
		return
	for card in hand.current_cards.duplicate():
		hand.remove_card(card)
		card.queue_free()
	for card in pile.current_cards.duplicate():
		pile.remove_card(card)
		card.queue_free()
	cards_created = 0
	for index in range(4):
		_add_card()
	call_deferred("_update_info")


func _update_info() -> void:
	info.text = "Hand: %d | Pile: %d | Layout: %s | Existing UI components are independent of the new core." % [
		hand.current_cards.size(), pile.current_cards.size(),
		["horizontal", "irregular fan", "arc"][hand.display_layout_mode]
	]
