@icon("res://addons/ninetailsrabbit.deckit/assets/card_pile.svg")
@tool
class_name CardPile extends Control

const GroupName: StringName = &"deck-piles"

enum StackMode {
	VerticalUp,
	VerticalDown,
	InPlaceFaceUp,
	InPlaceFaceDown,
}

## A layer value between 0 and 32
@export var pieces_collision_layer: int = 8:
	set(value):
		pieces_collision_layer = clampi(value, 0, 32)
@export var detection_area_size: Vector2:
	set(value):
		if detection_area_size != value:
			detection_area_size = value
			change_detection_area_size(detection_area_size)
@export_category("Stack")
## Set the stack mode to display the cards as they are dropped
@export var stack_mode: StackMode = StackMode.InPlaceFaceUp
## Select a direction in which the cards will be accumulated, the vectors are normalized.
@export var stack_direction: Vector2i = Vector2i.ZERO
## The amount of space between cards as the stack grows.
@export var stack_separation: Vector2 = Vector2.ONE
## Set the min angle in degrees to apply in a card when is dropped
@export var min_rotation_on_card_dropped: float = -5.0
## Set the max angle in degrees to apply in a card when is dropped
@export var max_rotation_on_card_dropped: float = 5.0

@export_category("Rules")
## Set to zero to allow an infinite amount of cards
@export var maximum_cards_in_pile: int = 0
@export var allowed_spanish_suits: Array[DeckitPlayingCard.Suits] = [
	DeckitPlayingCard.Suits.Cup,
	DeckitPlayingCard.Suits.Gold,
	DeckitPlayingCard.Suits.Club,
	DeckitPlayingCard.Suits.Sword,
]
@export var allowed_french_suits: Array[DeckitPlayingCard.Suits] = [
	DeckitPlayingCard.Suits.Diamond,
	DeckitPlayingCard.Suits.Heart,
	DeckitPlayingCard.Suits.Club,
	DeckitPlayingCard.Suits.Spade,
]


@onready var card_detection_area: Area2D = $CardDetectionArea
@onready var card_detection_collision: CollisionShape2D = $CardDetectionArea/CollisionShape2D

var current_cards: Array[DeckitPlayingCardUI] = []


func _ready() -> void:
	_prepare_card_detection_area()
	
	
func add_card(card: DeckitPlayingCardUI) -> void:
	if card_can_be_added_to_pile(card):
		card.lock()
		current_cards.append(card)
		
		
func card_can_be_added_to_pile(playing_card: DeckitPlayingCardUI) -> bool:
	var is_allowed_spanish_card: bool = playing_card.card.is_spanish() and playing_card.card.suit in allowed_spanish_suits
	var is_allowed_french_card: bool = playing_card.card.is_french() and playing_card.card.suit in allowed_french_suits
	
	return (maximum_cards_in_pile == 0 or (maximum_cards_in_pile > 0 and current_cards.size() < maximum_cards_in_pile)) \
		and (is_allowed_spanish_card or is_allowed_french_card)
	

func change_detection_area_size(new_size: Vector2) -> void:
	if card_detection_area:
		card_detection_collision.shape.size = new_size


func _prepare_card_detection_area() -> void:
	card_detection_area.monitorable = true
	card_detection_area.monitoring = false
	card_detection_area.collision_layer = DeckitUtils.collision_layer_to_value(pieces_collision_layer)
	card_detection_area.collision_mask = 0
	card_detection_area.priority = 2
	change_detection_area_size(detection_area_size)
