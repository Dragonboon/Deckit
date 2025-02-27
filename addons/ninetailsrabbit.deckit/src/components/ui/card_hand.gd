@icon("res://addons/ninetailsrabbit.deckit/assets/card_hand.svg")
class_name CardHand extends Control

const GroupName: StringName = &"card-hands"

signal added_card(card: DeckitPlayingCardUI)
signal added_cards(cards: Array[DeckitPlayingCardUI])
signal removed_card(card: DeckitPlayingCardUI)
signal add_card_request_denied(card: DeckitPlayingCardUI)
signal add_cards_request_denied(card: Array[DeckitPlayingCardUI])
signal sorted_cards(previous: Array[DeckitPlayingCardUI], current: Array[DeckitPlayingCardUI])


enum Layouts {
	Horizontal,
	IrregularFan,
	PerfectArcFan
}

enum SelectionMode {
	Drag,
	Click
}

@export var id: StringName
## Set to 0 to allow infinite amount of cards
@export var maximum_cards: int = 4:
	set(value):
		maximum_cards = maxi(1, value)
@export var display_layout_mode: Layouts = Layouts.Horizontal:
	set(value):
		if display_layout_mode != value:
			display_layout_mode = value
			
			#if is_inside_tree():
				#adjust_hand_position()
@export var selection_mode: SelectionMode = SelectionMode.Drag

var current_cards: Array[DeckitPlayingCardUI] = []
var current_selected_cards: Array[DeckitPlayingCardUI] = []


func _enter_tree() -> void:
	add_to_group(GroupName)
	
	mouse_filter = MOUSE_FILTER_PASS
	
	
func has_card(card: DeckitPlayingCardUI) -> bool:
	return current_cards.has(card)


func add_card(card: DeckitPlayingCardUI) -> void:
	if not card_can_be_added_to_hand(card):
		add_card_request_denied.emit(card)
	else:
		current_cards.append(card)
		added_card.emit(card)


func remove_card(card: DeckitPlayingCardUI):
	if has_card(card):
		if card.draggable_2d.dragged.is_connected(on_card_dragged.bind(card)):
			card.draggable_2d.dragged.disconnect(on_card_dragged.bind(card))
			
		#if card.draggable_2d.released.is_connected(on_card_released.bind(card)):
			#card.draggable_2d.released.disconnect(on_card_released.bind(card))
		
		current_cards.erase(card)
		removed_card.emit(card)
		

func card_can_be_added_to_hand(card: DeckitPlayingCardUI) -> bool:
	return current_cards.size() == maximum_cards or has_card(card)


func selection_mode_is_click() -> bool:
	return selection_mode == SelectionMode.Click
	

func selection_mode_is_drag() -> bool:
	return selection_mode == SelectionMode.Drag
	

func on_added_card(card: DeckitPlayingCardUI) -> void:
	if selection_mode_is_drag():
		if not card.draggable_2d.dragged.is_connected(on_card_dragged.bind(card)):
			card.draggable_2d.dragged.connect(on_card_dragged.bind(card))
	
	elif selection_mode_is_click():
		if not card.draggable_2d.pressed.is_connected(on_card_pressed.bind(card)):
			card.draggable_2d.pressed.connect(on_card_pressed.bind(card))
	

func on_card_dragged(card: DeckitPlayingCardUI) -> void:
	remove_card(card)
	

func on_card_pressed(card: DeckitPlayingCardUI) -> void:
	if current_selected_cards.has(card):
		current_selected_cards.erase(card)
	else:
		current_selected_cards.append(card)
		
	print("pressed card ", card)
