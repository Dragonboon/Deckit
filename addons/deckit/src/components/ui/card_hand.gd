@icon("res://addons/deckit/assets/card_hand.svg")
@tool
class_name DeckitCardHand extends Control

const GroupName: StringName = &"card-hands"

signal added_card(card: DeckitPlayingCardUI)
signal added_cards(cards: Array[DeckitPlayingCardUI])
signal removed_card(card: DeckitPlayingCardUI)
signal add_card_request_denied(card: DeckitPlayingCardUI)
signal sorted_cards(previous: Array[DeckitPlayingCardUI], current: Array[DeckitPlayingCardUI])
signal selected_card(card: DeckitPlayingCardUI)
signal selected_cards(cards: Array[DeckitPlayingCardUI])
signal unselected_card(card: DeckitPlayingCardUI)

enum Layouts {
	Horizontal,
	IrregularFan,
	PerfectArcFan
}

enum SelectionMode {
	Drag,
	Click
}

@export_category("Debug")
@export var preview_cards_to_display: int = 4:
	set(value):
		if value != preview_cards_to_display:
			preview_cards_to_display = value
			draw_preview_cards()
@export var preview_display_texture: Texture2D:
	set(value):
		if value != preview_display_texture:
			preview_display_texture = value
			draw_preview_cards()
@export var preview_texture_size: Vector2 = Vector2(37, 52):
	set(value):
		if value != preview_texture_size:
			preview_texture_size = value
			draw_preview_cards()
@export var preview_texture_scale: float = 1.0:
	set(value):
		if value != preview_texture_scale:
			preview_texture_scale = value
			draw_preview_cards()
			
@export_category("Display")
@export var id: StringName
## Set to 0 to allow infinite amount of cards
@export var maximum_cards: int = 4:
	set(value):
		maximum_cards = maxi(0, value)
## Set to 0 to allow select all the cards
@export var maximum_selected_cards: int = 4:
	set(value):
		maximum_selected_cards = maxi(0, value)

@export var display_layout_mode: Layouts = Layouts.Horizontal:
	set(value):
		if display_layout_mode != value:
			display_layout_mode = value
			update_hand_display_layout()
			
			#if is_inside_tree():
				#adjust_hand_position()
@export var selection_mode: SelectionMode = SelectionMode.Drag

@export_category("Horizontal Layout")
@export var horizontal_separation: Vector2 = Vector2(20, 0):
	set(new_separation):
		if horizontal_separation != new_separation:
			horizontal_separation = new_separation
			update_hand_display_layout()
@export var horizontal_direction: Vector2 = Vector2.RIGHT:
	set(new_direction):
		if horizontal_direction != new_direction:
			horizontal_direction = new_direction.normalized()
			update_hand_display_layout()
@export_range(-360.0, 360.0, 0.01, "degrees") var horizontal_min_rotation_angle: float = 0.0:
	set(new_angle):
		if horizontal_min_rotation_angle != new_angle:
			horizontal_min_rotation_angle = new_angle
			update_hand_display_layout()
@export_range(-360.0, 360.0, 0.01, "degrees") var horizontal_max_rotation_angle: float = 0.0:
	set(new_angle):
		if horizontal_max_rotation_angle != new_angle:
			horizontal_max_rotation_angle = new_angle
			update_hand_display_layout()
			
@export_category("Irregular Fan Layout")
@export var irregular_fan_card_offset_x: float = 20.0:
	set(new_offset):
		if irregular_fan_card_offset_x != new_offset:
			irregular_fan_card_offset_x = new_offset
			update_hand_display_layout()
@export_range(0, 360.0, 0.01, "degrees") var irregular_fan_max_rotation: float = 10.0:
	set(new_rotation):
		if irregular_fan_max_rotation != new_rotation:
			irregular_fan_max_rotation = new_rotation
			update_hand_display_layout()
			
@export_category("Perfect Arc Fan layout")
## The distance of the cards aligned, more the radius, more the arc range
@export var perfect_arc_hand_radius: float = 250.0:
	set(new_radius):
		if perfect_arc_hand_radius != new_radius:
			perfect_arc_hand_radius = new_radius
			update_hand_display_layout()
@export_range(0, 360.0, 0.01, "degrees") var perfect_arc_angle_limit: float = 45.0:
	set(new_angle_limit):
		if perfect_arc_angle_limit != new_angle_limit:
			perfect_arc_angle_limit = new_angle_limit
			update_hand_display_layout()
@export_range(0, 360.0, 0.01, "degrees")var perfect_arc_max_card_spread_angle: float = 15.0:
	set(new_spread_angle):
		if perfect_arc_max_card_spread_angle != new_spread_angle:
			perfect_arc_max_card_spread_angle = new_spread_angle
			update_hand_display_layout()


var current_cards: Array[DeckitPlayingCardUI] = []
var current_selected_cards: Array[DeckitPlayingCardUI] = []
## Dictionary[DeckitPlayingCardUI, {"position", "rotation"}
var hand_cards_position: Dictionary = {}

func _enter_tree() -> void:
	add_to_group(GroupName)
	mouse_filter = MOUSE_FILTER_PASS
	

func _ready() -> void:
	draw_preview_cards()
	
	added_card.connect(on_added_card)


func update_hand_display_layout() -> void:
	match display_layout_mode:
		Layouts.Horizontal:
			update_horizontal_preview_layout()
			update_horizontal_layout()
		Layouts.IrregularFan:
			update_irregular_fan_preview_layout()
			update_irregular_fan_layout()
		Layouts.PerfectArcFan:
			update_perfect_arc_fan_preview_layout()
			update_perfect_arc_fan_layout()
			

#region Cards
func has_card(card: DeckitPlayingCardUI) -> bool:
	return current_cards.has(card)


func add_cards(cards: Array[DeckitPlayingCardUI]) -> void:
	for card in cards:
		add_card(card)
		
	added_cards.emit(cards)


func add_card(card: DeckitPlayingCardUI) -> void:
	if card_can_be_added_to_hand(card):
		current_cards.append(card)
		
		if card.is_inside_tree():
			card.reparent(self, false)
		else:
			add_child(card)
			
		card.position = Vector2.ZERO
		card.z_as_relative = true
		card.z_index = current_cards.size() + 1
		call_deferred("update_hand_display_layout")
		
		added_card.emit(card)
	else:
		add_card_request_denied.emit(card)


func add_card_to_selected(card: DeckitPlayingCardUI) -> bool:
	if current_cards.has(card) \
		and not current_selected_cards.has(card) \
			and (maximum_selected_cards == 0 or current_selected_cards.size() < maximum_selected_cards):
		current_selected_cards.append(card)
		card.set_deferred("z_index", current_cards.size() + current_selected_cards.size() + 1)
		
		selected_card.emit(card)
		selected_cards.emit(current_selected_cards)
		
		return true
		
	return false


func remove_selected_card(card: DeckitPlayingCardUI) -> bool:
	if current_selected_cards.has(card):
		current_selected_cards.erase(card)
		card.set_deferred("z_index", current_cards.size())
		
		if maximum_selected_cards > 0 and current_selected_cards.size() == maximum_selected_cards:
			for non_selected_card: DeckitPlayingCardUI in unselected_cards():
				non_selected_card.lock()
				
		unselected_card.emit(card)
		
		return true
		
	return false


func remove_card(card: DeckitPlayingCardUI):
	if has_card(card):
		if card.draggable_2d.dragged.is_connected(on_card_dragged.bind(card)):
			card.draggable_2d.dragged.disconnect(on_card_dragged.bind(card))
			
		if card.draggable_2d.released.is_connected(on_card_released.bind(card)):
			card.draggable_2d.released.disconnect(on_card_released.bind(card))
			
		card.z_as_relative = false
		call_deferred("update_hand_display_layout")
		
		#card.reparent(get_tree().current_scene)
		
		hand_cards_position.erase(card)
		current_cards.erase(card)
		removed_card.emit(card)
		
		
func remove_cards(cards: Array[DeckitPlayingCardUI]):
	for card: DeckitPlayingCardUI in cards:
		remove_card(card)


func remove_random_card() -> DeckitPlayingCardUI:
	if current_cards.is_empty():
		return null
		
	var card: DeckitPlayingCardUI = current_cards.pick_random()
	remove_card(card)
	
	return card


func remove_current_cards() -> void:
	remove_cards(current_cards.duplicate())


func card_can_be_added_to_hand(card: DeckitPlayingCardUI) -> bool:
	return (maximum_cards == 0 or current_cards.size() < maximum_cards) and not has_card(card)


func unselected_cards() -> Array[DeckitPlayingCardUI]:
	return current_cards.filter(
		func(card: DeckitPlayingCardUI): return not current_selected_cards.has(card)
		)


func sort_cards_by_value_asc() -> void:
	if current_cards.size() > 1:
		var previous_sortered_cards: Array[DeckitPlayingCardUI] = current_cards.duplicate()
		
		current_cards.sort_custom(
			func(a: DeckitPlayingCardUI, b: DeckitPlayingCardUI): return a.card.value < b.card.value
			)
		
		update_hand_display_layout()
		sorted_cards.emit(previous_sortered_cards, current_cards)
		
		
func sort_cards_by_value_desc() -> void:
	if current_cards.size() > 1:
		var previous_sortered_cards: Array[DeckitPlayingCardUI] = current_cards.duplicate()
		
		current_cards.sort_custom(func(a: DeckitPlayingCardUI, b: DeckitPlayingCardUI): return a.card.value > b.card.value)
		update_hand_display_layout()
		
		sorted_cards.emit(previous_sortered_cards, current_cards)


func selection_mode_is_click() -> bool:
	return selection_mode == SelectionMode.Click
	

func selection_mode_is_drag() -> bool:
	return selection_mode == SelectionMode.Drag
	
	
#endregion

#region Layouts
func update_horizontal_layout() -> void:
	if current_cards.is_empty():
		return
		
	for card: DeckitPlayingCardUI in unselected_cards():
		card.position = Vector2.ZERO
		card.position += calculate_card_horizontal_layout_position(card)
		card.rotation = calculate_card_horizontal_layout_rotation(card)
		hand_cards_position.get_or_add(card, {"position": card.position, "rotation": card.rotation})


func calculate_card_horizontal_layout_position(card: DeckitPlayingCardUI) -> Vector2:
	if has_card(card):
		var index: int = current_cards.find(card)
		return card.position + (horizontal_direction * horizontal_separation) * index
		
	return Vector2.ZERO


func calculate_card_horizontal_layout_rotation(card: DeckitPlayingCardUI) -> float:
	if has_card(card):
		var min_rotation_angle: float = deg_to_rad(horizontal_min_rotation_angle)
		var max_rotation_angle: float = deg_to_rad(horizontal_max_rotation_angle)
		
		return randf_range(min_rotation_angle, max_rotation_angle)
	
	return 0.0
	

func update_irregular_fan_layout() -> void:
	for card: DeckitPlayingCardUI in current_cards:
		card.position = calculate_irregular_fan_layout_position(card)
		card.rotation = calculate_irregular_fan_layout_rotation(card)
		
		hand_cards_position.get_or_add(card, {"position": card.position, "rotation": card.rotation})


func calculate_irregular_fan_layout_position(card: DeckitPlayingCardUI) -> Vector2:
	if has_card(card):
		var index: int = current_cards.find(card)
		var cards_size: int = current_cards.size()
		
		var final_position: Vector2 = -( 
			(card.card.texture_size * card.card_texture.scale) / 2.0) - Vector2(irregular_fan_card_offset_x * (cards_size - index),
			 0
			)
			
		final_position.x += (irregular_fan_card_offset_x * cards_size) / 2.0
		final_position.y = 0
		
		return final_position
	
	return Vector2.ZERO


func calculate_irregular_fan_layout_rotation(card: DeckitPlayingCardUI) -> float:
	if has_card(card):
		return randf_range(deg_to_rad(-irregular_fan_max_rotation), deg_to_rad(irregular_fan_max_rotation))
		
	return 0.0


func update_perfect_arc_fan_layout() -> void:
	var cards_size: int = current_cards.size()
	if cards_size == 0:
		return
	var card_spread = min(perfect_arc_angle_limit / cards_size, perfect_arc_max_card_spread_angle)
	var current_angle = -(card_spread * (cards_size - 1)) / 2 - 90

	for card: DeckitPlayingCardUI in current_cards:
		card.position = calculate_perfect_arc_fan_position(card, current_angle)
		card.rotation = calculate_perfect_arc_fan_rotation(card, current_angle)
		current_angle += card_spread
		hand_cards_position.get_or_add(card, {"position": card.position, "rotation": card.rotation})


func calculate_perfect_arc_fan_position(card: DeckitPlayingCardUI, angle: float) -> Vector2:
	if has_card(card):
		var final_position: Vector2 = Vector2(
				perfect_arc_hand_radius * cos(deg_to_rad(angle)), 
				perfect_arc_hand_radius * sin(deg_to_rad(angle)
			))
		
		## This sum keeps the player hand control node in the same place
		final_position.y += perfect_arc_hand_radius
		
		return final_position
		
	return Vector2.ZERO
	
	
func calculate_perfect_arc_fan_rotation(card: DeckitPlayingCardUI, angle: float) -> float:
	if has_card(card):
		return deg_to_rad(angle + 90.0)
			
	return 0.0
	
#endregion


#region Debug
func draw_preview_cards() -> void:
	if Engine.is_editor_hint() and is_inside_tree():
		DeckitUtils.remove_child_nodes(self)
			
		for index in preview_cards_to_display:
			var preview_card = TextureRect.new()
			preview_card.texture = preview_display_texture
			preview_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			preview_card.set_deferred("size", preview_texture_size * preview_texture_scale)
			preview_card.set_deferred("anchors_preset", Control.PRESET_CENTER)
			add_child(preview_card)
			
			DeckitUtils.set_owner_to_edited_scene_root(preview_card)
			DeckitUtils.center_texture_rect_pivot(preview_card)
		
		update_hand_display_layout()
	else:
		DeckitUtils.remove_child_nodes(self)
		
		
func update_horizontal_preview_layout() -> void:
	if Engine.is_editor_hint():
		var min_rotation_angle: float = deg_to_rad(horizontal_min_rotation_angle)
		var max_rotation_angle: float = deg_to_rad(horizontal_max_rotation_angle)
		var index: int = 0
		
		for preview_card in get_children():
			preview_card.position = Vector2.ZERO
			preview_card.position += (horizontal_direction * horizontal_separation) * index
			preview_card.rotation = randf_range(min_rotation_angle, max_rotation_angle)
			index += 1
			
			
func update_irregular_fan_preview_layout() -> void:
	if Engine.is_editor_hint():
		var index: int = 0
		var cards_size: int = get_child_count()
		
		for preview_card in get_children():
			index += 1
			
			var final_position: Vector2 = -( 
				(preview_texture_size * preview_texture_scale) / 2.0) - Vector2(irregular_fan_card_offset_x * (cards_size - index),
				 0
				)
			final_position.x += (irregular_fan_card_offset_x * cards_size) / 2.0
			final_position.y = 0
			
			var final_rotation: float = randf_range(
				deg_to_rad(-irregular_fan_max_rotation), 
				deg_to_rad(irregular_fan_max_rotation)
			)
			
			preview_card.position = final_position
			preview_card.rotation = final_rotation


func update_perfect_arc_fan_preview_layout() -> void:
	if Engine.is_editor_hint():
		var cards_size: int = get_child_count()
		if cards_size == 0:
			return
		var card_spread = min(perfect_arc_angle_limit / cards_size, perfect_arc_max_card_spread_angle)
		var current_angle = -(card_spread * (cards_size - 1)) / 2 - 90
	
		for preview_card in get_children():
			preview_card.position = Vector2(
				perfect_arc_hand_radius * cos(deg_to_rad(current_angle)), 
				perfect_arc_hand_radius * sin(deg_to_rad(current_angle)
			))
	
			## This sum keeps the player hand control node in the same place
			preview_card.position.y += perfect_arc_hand_radius
			preview_card.rotation = deg_to_rad(current_angle + 90.0)
			current_angle += card_spread

#endregion

#region Signal callbacks
func on_added_card(card: DeckitPlayingCardUI) -> void:
	if selection_mode_is_drag():
		if not card.draggable_2d.dragged.is_connected(on_card_dragged.bind(card)):
			card.draggable_2d.dragged.connect(on_card_dragged.bind(card))
		
		if not card.draggable_2d.released.is_connected(on_card_released.bind(card)):
			card.draggable_2d.released.connect(on_card_released.bind(card))
			
	elif selection_mode_is_click():
		card.draggable_2d.lock()
		
		if not card.draggable_2d.pressed.is_connected(on_card_pressed.bind(card)):
			card.draggable_2d.pressed.connect(on_card_pressed.bind(card))
	

func on_card_dragged(card: DeckitPlayingCardUI) -> void:
	if selection_mode_is_drag():
		add_card_to_selected(card)
		call_deferred("update_hand_display_layout")
		
	
func on_card_released(card: DeckitPlayingCardUI) -> void:
	if hand_cards_position.has(card):
		card.position = hand_cards_position[card].position
		card.rotation = hand_cards_position[card].rotation


func on_card_pressed(card: DeckitPlayingCardUI) -> void:
	if selection_mode_is_click():
		if not remove_selected_card(card):
			add_card_to_selected(card)
#endregion
