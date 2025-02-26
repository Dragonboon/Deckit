@icon("res://addons/ninetailsrabbit.deckit/assets/deckit.svg")
class_name DeckitPlayingCardUI extends Control

const GroupName: StringName = &"playing-cards"

signal faced_up
signal faced_down
signal orientation_changed(from: DeckitPlayingCard.Orientation, to: DeckitPlayingCard.Orientation)

enum DisplayShadowModes {
	Always,
	OnDrag,
	Never
}

@export var card: DeckitPlayingCard
@export_category("Shadow")
@export var display_shadow_mode: DisplayShadowModes = DisplayShadowModes.OnDrag
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


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("right_click"):
		toggle_orientation()


func _enter_tree() -> void:
	add_to_group(GroupName)
	

func _ready() -> void:
	_prepare_card_texture()
	_prepare_shadow()
	_prepare_draggable()
	_center_pivot()


func face_up() -> void:
	orientation = DeckitPlayingCard.Orientation.FaceUp 
	card_texture.texture = card.front_texture
	
	
func face_down() -> void:
	if card.back_texture:
		orientation = DeckitPlayingCard.Orientation.FaceDown 
		card_texture.texture = card.back_texture


func toggle_orientation() -> void:
	if is_face_up():
		face_down()
	else:
		face_up()


func is_face_up() -> bool:
	return orientation == DeckitPlayingCard.Orientation.FaceUp
	
	
func is_face_down() -> bool:
	return orientation == DeckitPlayingCard.Orientation.FaceDown
	
	
func lock() -> void:
	is_locked = true


func unlock() -> void:
	is_locked = false


func is_display_shadow_always() -> bool:
	return display_shadow_mode == DisplayShadowModes.Always


func is_display_shadow_on_drag() -> bool:
	return display_shadow_mode == DisplayShadowModes.OnDrag


func is_display_shadow_never() -> bool:
	return display_shadow_mode == DisplayShadowModes.Never


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
	
	if is_display_shadow_always():
		shadow.show()
	else:
		shadow.hide()
		
		
func _prepare_draggable() -> void:
	draggable_2d.is_locked = is_locked
	draggable_2d.dragged.connect(on_drag)
	draggable_2d.released.connect(on_drag_released)
	draggable_2d.mouse_entered.connect(on_draggable_2d_hover)
	draggable_2d.mouse_exited.connect(on_draggable_2d_hover_exited)
	draggable_2d.focus_entered.connect(on_draggable_2d_focus_entered)
	draggable_2d.focus_exited.connect(on_draggable_2d_focus_exited)
	

func _center_pivot() -> void:
	card_texture.pivot_offset = (card_texture.texture.get_size() / 2).ceil()


#region Signal callbacks
func on_drag() -> void:
	if is_display_shadow_on_drag():
		shadow.show()
	

func on_drag_released() -> void:
	if is_display_shadow_on_drag():
		shadow.hide()


func on_draggable_2d_hover() -> void:
	pass


func on_draggable_2d_hover_exited() -> void:
	pass
	

func on_draggable_2d_focus_entered() -> void:
	pass
	
	
func on_draggable_2d_focus_exited() -> void:
	pass
