@icon("res://addons/ninetailsrabbit.deckit/assets/deckit.svg")
class_name DeckitPlayingCardUI extends Control

const GroupName: StringName = &"playing-cards"

signal faced_up
signal faced_down


@export var card: DeckitPlayingCard


@onready var front_texture: TextureRect = $FrontTexture

@onready var orientation: DeckitPlayingCard.Orientation = card.default_orientation:
	set(value):
		if orientation != value:
			orientation = value
			
			if is_face_up():
				faced_up.emit()
			else:
				faced_down.emit()


func _enter_tree() -> void:
	add_to_group(GroupName)


func _ready() -> void:
	front_texture.pivot_offset = (front_texture.texture.get_size() / 2).ceil()


func is_face_up() -> bool:
	return orientation == DeckitPlayingCard.Orientation.FaceUp
	
	
func is_face_down() -> bool:
	return orientation == DeckitPlayingCard.Orientation.FaceDown
	
