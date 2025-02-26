@icon("res://addons/ninetailsrabbit.deckit/assets/deckit.svg")
class_name DeckitPlayingCardUI extends Control

const GroupName: StringName = &"playing-cards"

signal faced_up
signal faced_down
signal orientation_changed(from: DeckitPlayingCard.Orientation, to: DeckitPlayingCard.Orientation)


@export var card: DeckitPlayingCard
@export_category("Shadow")
@export var shadow_color: Color = Color("080808a8")
@export var shadow_vertical_depth: float = 2.0:
	set(value):
		if shadow_vertical_depth != value:
			shadow_vertical_depth = maxf(0.01, value)
		
		if is_inside_tree() and shadow:
			shadow.position.y = card.position.y + shadow_vertical_depth
		
@export var shadow_horizontal_depth: float = 1.5:
	set(value):
		if shadow_horizontal_depth != value:
			shadow_horizontal_depth = maxf(0.01, value)
			
			if is_inside_tree() and shadow:
				shadow.position.x = card.position.x + shadow_horizontal_depth


@onready var card_texture: TextureRect = $CardTexture
@onready var shadow: TextureRect = $Shadow
@onready var draggable_2d: DeckitDraggable2D = $CardTexture/Draggable2D

@onready var orientation: DeckitPlayingCard.Orientation = card.default_orientation:
	set(value):
		if orientation != value:
			var previuos_orientation: DeckitPlayingCard.Orientation = orientation
			orientation = value
			
			if is_face_up():
				faced_up.emit()
			else:
				faced_down.emit()
				
			orientation_changed.emit(previuos_orientation, orientation)


var is_locked: bool = false:
	set(value):
		if is_locked != value:
			is_locked = value
			
			if is_locked:
				draggable_2d.lock()
			else:
				draggable_2d.unlock()
			

func _enter_tree() -> void:
	add_to_group(GroupName)
	

func _ready() -> void:
	_prepare_card_texture()
	_prepare_shadow()
	_center_pivot()
	
	draggable_2d.is_locked = is_locked
	draggable_2d.dragged.connect(on_drag)
	draggable_2d.released.connect(on_drag_released)

	
func _prepare_card_texture() -> void:
	card_texture.texture = card.front_texture
	
	card_texture.mouse_filter = Control.MOUSE_FILTER_PASS
	card_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_texture.custom_minimum_size = card.front_texture.get_size() if card.texture_size.is_zero_approx() else card.texture_size
	card_texture.set_deferred("size", card_texture.custom_minimum_size )
	card_texture.position = Vector2.ZERO


func _prepare_shadow() -> void:
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.custom_minimum_size = card.front_texture.get_size() if card.texture_size.is_zero_approx() else card.texture_size
	shadow.set_deferred("size", shadow.custom_minimum_size)
	shadow.texture = card_texture.texture
	shadow.scale = card_texture.scale
	shadow.show_behind_parent = true
	shadow.self_modulate = shadow_color
	shadow.position = Vector2.ZERO
	
	shadow.position.x = card_texture.position.x + shadow_horizontal_depth
	shadow.position.y = card_texture.position.y + shadow_vertical_depth
	shadow.hide()


func _center_pivot() -> void:
	card_texture.pivot_offset = (card_texture.texture.get_size() / 2).ceil()


func is_face_up() -> bool:
	return orientation == DeckitPlayingCard.Orientation.FaceUp
	
	
func is_face_down() -> bool:
	return orientation == DeckitPlayingCard.Orientation.FaceDown
	

#region Signal callbacks
func on_drag() -> void:
	shadow.show()
	

func on_drag_released() -> void:
	shadow.hide()
