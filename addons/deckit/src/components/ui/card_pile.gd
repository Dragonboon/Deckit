@tool
class_name DeckitCardPile extends Control

const GroupName: StringName = &"deck-piles"

signal added_card(card: DeckitPlayingCardUI)
signal removed_card(card: DeckitPlayingCardUI)
signal removed_cards(cards: Array[DeckitPlayingCardUI])
signal add_card_request_denied(card: DeckitPlayingCardUI)
signal add_cards_request_denied(card: Array[DeckitPlayingCardUI])
signal emptied(cards: Array[DeckitPlayingCardUI])
signal filled


enum StackMode {
	VerticalUp,
	VerticalDown,
	HorizontalRight,
	HorizontalLeft,
	InPlaceFaceUp,
	InPlaceFaceDown,
	CustomDirection
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

@export_category("Visuals")
@export var empty_pile_texture: Texture2D:
	set(value):
		if value != empty_pile_texture:
			empty_pile_texture = value
			
			if empty_pile_texture_rect:
				empty_pile_texture_rect.texture = empty_pile_texture
				change_empty_texture_size(detection_area_size)
					
@export_category("Stack")
## Set the stack mode to display the cards as they are dropped
@export var stack_mode: StackMode = StackMode.InPlaceFaceUp:
	set(new_mode):
		if new_mode != stack_mode:
			stack_mode = new_mode
			adjust_cards_to_stack()
## Only used when CustomDirection is selected. Choose a direction in which the cards will be accumulated, the vectors are normalized.
@export var stack_direction: Vector2 = Vector2.ONE:
	set(new_direction):
		if new_direction != stack_direction:
			stack_direction = new_direction.normalized()
			adjust_cards_to_stack()
## The amount of space between cards as the stack grows.
@export var stack_separation: Vector2 = Vector2.ONE:
	set(new_separation):
		if new_separation != stack_separation:
			stack_separation = new_separation
			adjust_cards_to_stack()
## Set the min angle in degrees to apply in a card when is dropped
@export_range(-360.0, 360.0, 0.01, "degrees") var min_rotation_on_card_dropped: float = -5.0
## Set the max angle in degrees to apply in a card when is dropped
@export_range(-360.0, 360.0, 0.01, "degrees") var max_rotation_on_card_dropped: float = 5.0

@export_category("Rules")
## When enabled the last card can be moved from the pile
@export var top_card_can_be_dragged: bool = false
## Set to zero to allow an infinite amount of cards
@export var maximum_cards_in_pile: int = 0
@export var figure_cards_allowed: bool = true
@export var number_cards_allowed: bool = true
@export var spanish_suits_allowed: Array[DeckitPlayingCard.Suits] = [
	DeckitPlayingCard.Suits.Cup,
	DeckitPlayingCard.Suits.Gold,
	DeckitPlayingCard.Suits.Club,
	DeckitPlayingCard.Suits.Sword,
]
@export var french_suits_allowed: Array[DeckitPlayingCard.Suits] = [
	DeckitPlayingCard.Suits.Diamond,
	DeckitPlayingCard.Suits.Heart,
	DeckitPlayingCard.Suits.Club,
	DeckitPlayingCard.Suits.Spade,
]

@onready var empty_pile_texture_rect: TextureRect = $EmptyPileTexture
@onready var card_detection_area: Area2D = $CardDetectionArea
@onready var card_detection_collision: CollisionShape2D = $CardDetectionArea/CollisionShape2D

var current_cards: Array[DeckitPlayingCardUI] = []


func _ready() -> void:
	_prepare_card_detection_area()
	_prepare_empty_pile_texture()
	
	added_card.connect(on_added_card)
	removed_card.connect(on_removed_card)


#region Size
func change_detection_area_size(new_size: Vector2) -> void:
	if card_detection_area:
		card_detection_collision.shape.size = new_size
	
		change_empty_texture_size(new_size)


func change_empty_texture_size(new_size: Vector2) -> void:
	DeckitUtils.center_texture_rect_pivot(empty_pile_texture_rect)
	
	empty_pile_texture_rect.z_index = 0
	empty_pile_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	empty_pile_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	empty_pile_texture_rect.custom_minimum_size = new_size
	empty_pile_texture_rect.set_deferred("size", empty_pile_texture_rect.custom_minimum_size)
	empty_pile_texture_rect.set_deferred("anchors_preset", Control.PRESET_CENTER)
	empty_pile_texture_rect.position = Vector2.ZERO
	
#endregion

#region Features
func card_can_be_added_to_pile(playing_card: DeckitPlayingCardUI) -> bool:
	if has_card(playing_card):
		return false
		
	var is_allowed_spanish_card: bool = playing_card.card.is_spanish() and playing_card.card.suit in spanish_suits_allowed
	var is_allowed_french_card: bool = playing_card.card.is_french() and playing_card.card.suit in french_suits_allowed
	var is_allowed_figure_card: bool = playing_card.card.is_figure() and figure_cards_allowed
	var is_allowed_number_card: bool = playing_card.card.is_number() and number_cards_allowed
	
	return (maximum_cards_in_pile == 0 or (maximum_cards_in_pile > 0 and current_cards.size() < maximum_cards_in_pile)) \
		and ( (is_allowed_spanish_card or is_allowed_french_card) and (is_allowed_figure_card or is_allowed_number_card))
	
	
func add_card(card: DeckitPlayingCardUI) -> void:
	if card_can_be_added_to_pile(card):
		current_cards.append(card)
		
		if card.is_inside_tree():
			card.reparent(self, false)
		else:
			add_child(card)
		
		card.position = Vector2.ZERO
		card.z_as_relative = true
		move_child(card, get_child_count() - 1)
		
		added_card.emit(card)
		
		if not card.draggable_2d.dragged.is_connected(on_top_card_dragged.bind(card)):
			card.draggable_2d.dragged.connect(on_top_card_dragged.bind(card))
	else:
		add_card_request_denied.emit(card)


func add_cards(cards: Array[DeckitPlayingCardUI]) -> void:
	if is_full():
		add_cards_request_denied.emit(cards)
	else:
		for card: DeckitPlayingCardUI in cards:
			add_card(card)


func remove_card(card: DeckitPlayingCardUI) -> void:
	if has_card(card):
		card.z_as_relative = false
		card.reparent(get_tree().current_scene)
		
		current_cards.erase(card)
		removed_card.emit(card)
		update_card_locks()
		
		if card.draggable_2d.dragged.is_connected(on_top_card_dragged.bind(card)):
			card.draggable_2d.dragged.disconnect(on_top_card_dragged.bind(card))
		

func remove_cards(cards: Array[DeckitPlayingCardUI] = current_cards) -> void:
	var snapshot: Array[DeckitPlayingCardUI] = cards.duplicate()
	for card: DeckitPlayingCardUI in snapshot:
		remove_card(card)

	removed_cards.emit(cards)
	

func remove_card_at_position(idx: int) -> void:
	var card: DeckitPlayingCardUI = card_at_position(idx)
	
	if card != null:
		remove_card(card)
	
	
func remove_random_card() -> DeckitPlayingCardUI:
	if is_empty():
		return null
	
	var card: DeckitPlayingCardUI = current_cards.pick_random()
	remove_card(card)
	
	return card
	
	
func update_card_locks() -> void:
	if current_cards.is_empty():
		return
		
	for index in current_cards.size():
		var card: DeckitPlayingCardUI = current_cards[index]
		
		if index == current_cards.size() - 1 and top_card_can_be_dragged:
			card.unlock()
		else:
			card.lock()
			

func clear() -> void:
	if is_empty():
		return
	var snapshot: Array[DeckitPlayingCardUI] = current_cards.duplicate()
	emptied.emit(snapshot)
	remove_cards(snapshot)

#endregion

#region Accessors
func has_card(card: DeckitPlayingCardUI) -> bool:
	return current_cards.has(card)
	
	
func bottom_card() -> DeckitPlayingCardUI:
	if is_empty():
		return null
	 
	return current_cards.front()


func top_card() -> DeckitPlayingCardUI:
	if is_empty():
		return null
	 
	return current_cards.back()


func middle_card() -> DeckitPlayingCardUI:
	if current_cards.size() > 2:
		return current_cards[floor(current_cards.size() / 2.0)]
		
	return null


func card_at_position(idx: int) -> DeckitPlayingCardUI:
	var index: int = idx
	
	if index != -1:
		return current_cards[index]
		
	return null


func is_empty() -> bool:
	return current_cards.is_empty()


func is_full() -> bool:
	return maximum_cards_in_pile > 0 and current_cards.size() >= maximum_cards_in_pile


func total_card_value() -> float:
	return current_cards.reduce(
		func(accum: float, playing_card: DeckitPlayingCardUI): return playing_card.card.value + accum, 0.0)


func total_card_table_value() -> float:
	return current_cards.reduce(
		func(accum: float, playing_card: DeckitPlayingCardUI): return playing_card.card.table_value + accum, 0.0)

#endregion

#region Private 
func _prepare_card_detection_area() -> void:
	card_detection_area.monitorable = true
	card_detection_area.monitoring = false
	card_detection_area.collision_layer = DeckitUtils.collision_layer_to_value(pieces_collision_layer)
	card_detection_area.collision_mask = 0
	card_detection_area.priority = 2
	change_detection_area_size(detection_area_size)


func _prepare_empty_pile_texture() -> void:
	if empty_pile_texture_rect:
		empty_pile_texture_rect.texture = empty_pile_texture
		change_empty_texture_size(detection_area_size)

#endregion
	
#region Stack
func adjust_cards_to_stack() -> void:
	for card: DeckitPlayingCardUI in current_cards:
		adjust_card_to_stack(card)


func adjust_card_to_stack(new_card: DeckitPlayingCardUI) -> void:
	var index: int = current_cards.find(new_card)
	
	new_card.position = Vector2.ZERO
	new_card.rotation_degrees = randf_range(min_rotation_on_card_dropped, max_rotation_on_card_dropped)
	
	match stack_mode:
		StackMode.InPlaceFaceUp:
			new_card.face_up()
		StackMode.InPlaceFaceDown:
			new_card.face_down()
				
	if index > 0:
		match stack_mode:
			StackMode.VerticalDown:
				new_card.position += (stack_separation * Vector2.DOWN) * index
			StackMode.VerticalUp:
				new_card.position += (stack_separation * Vector2.UP) * index
			StackMode.HorizontalRight:
				new_card.position += (stack_separation * Vector2.RIGHT) * index
			StackMode.HorizontalLeft:
				new_card.position += (stack_separation * Vector2.LEFT) * index
			StackMode.CustomDirection:
				new_card.position += (stack_separation * stack_direction) * index
		
#endregion

#region Signal callbacks
func on_added_card(new_card: DeckitPlayingCardUI) -> void:
	if is_full():
		filled.emit()
	
	await get_tree().process_frame
	adjust_card_to_stack(new_card)
	update_card_locks()
	

func on_removed_card(_removed_card: DeckitPlayingCardUI) -> void:
	await get_tree().process_frame
	adjust_cards_to_stack()
	update_card_locks()


func on_top_card_dragged(card: DeckitPlayingCardUI) -> void:
	remove_card(card)

#endregion
