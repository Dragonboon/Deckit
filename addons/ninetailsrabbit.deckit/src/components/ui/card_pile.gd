@icon("res://addons/ninetailsrabbit.deckit/assets/card_pile.svg")
@tool
class_name CardPile extends Control

const GroupName: StringName = &"deck-piles"

## A layer value between 0 and 32
@export var pieces_collision_layer: int = 8:
	set(value):
		pieces_collision_layer = clampi(value, 0, 32)
@export var detection_area_size: Vector2:
	set(value):
		if detection_area_size != value:
			detection_area_size = value
			change_detection_area_size(detection_area_size)
## Set to zero to allow an infinite amount of cards
@export var maximum_cards_in_pile: int = 0

@onready var card_detection_area: Area2D = $CardDetectionArea
@onready var card_detection_collision: CollisionShape2D = $CardDetectionArea/CollisionShape2D


func _ready() -> void:
	_prepare_card_detection_area()
	

func _prepare_card_detection_area() -> void:
	card_detection_area.monitorable = false
	card_detection_area.monitoring = true
	card_detection_area.collision_layer = 0
	card_detection_area.collision_mask = DeckitUtils.collision_layer_to_value(pieces_collision_layer)
	card_detection_area.priority = 2
	change_detection_area_size(detection_area_size)
	
	card_detection_area.area_entered.connect(on_card_entered)
	card_detection_area.area_exited.connect(on_card_exited)


func change_detection_area_size(new_size: Vector2) -> void:
	if card_detection_area:
		card_detection_collision.shape.size = new_size
	
	
func on_card_entered(other_area: Area2D) -> void:
	print("card entered ", other_area.get_parent())


func on_card_exited(other_area: Area2D) -> void:
	print("card exited ", other_area.get_parent())
