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

@export var id: StringName
@export var maximum_cards: int = 4:
	set(value):
		maximum_cards = maxi(1, value)
@export var display_layout_mode: Layouts = Layouts.Horizontal:
	set(value):
		if display_layout_mode != value:
			display_layout_mode = value
			
			#if is_inside_tree():
				#adjust_hand_position()


func _enter_tree() -> void:
	add_to_group(GroupName)
