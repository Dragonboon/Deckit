@tool
class_name DeckitDeck extends Control

signal loaded_new_deck
signal added_card(card: DeckitPlayingCardUI)
signal added_cards(card: Array[DeckitPlayingCardUI])
signal picked_card(card: DeckitPlayingCardUI)
signal removed_card(card: DeckitPlayingCardUI)
signal added_to_discard_pile(card: DeckitPlayingCardUI)
signal recovered_card_from_discard_pile(card: DeckitPlayingCardUI)
signal emptied_deck
signal cleared_deck
signal filled
signal shuffled

## When enabled, this deck can contain duplicated cards
@export var allow_duplicate_cards: bool = false
@export var deck_type: DeckType = DeckType.French
@export var playing_card_scene: PackedScene = preload("res://addons/deckit/src/components/ui/playing_card_ui.tscn")
@export_category("Visuals")
@export var visual_pile_cards_amount: int = 5
@export var stack_direction: Vector2 = Vector2.ONE:
	set(new_direction):
		if new_direction != stack_direction:
			stack_direction = new_direction
			draw_preview_cards()
			draw_visual_pile(current_back_texture)
## The amount of space between cards as the stack grows.
@export var stack_separation: Vector2 = Vector2.ONE:
	set(new_separation):
		if new_separation != stack_separation:
			stack_separation = new_separation
			draw_preview_cards()
			draw_visual_pile(current_back_texture)
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
			
	
enum DeckType {
	Spanish,
	French
}

var jokers_count_for_empty_deck: bool = false

var visual_pile_counter: int:
	set(value):
		@warning_ignore("integer_division")
		visual_pile_counter = clampi(value, 0, _calculate_visual_pile_counter())

#region Card templates
var cards_by_suit: Dictionary[DeckitPlayingCard.Suits, Array] = {
	DeckitPlayingCard.Suits.Joker: [],
	DeckitPlayingCard.Suits.Heart: [],
	DeckitPlayingCard.Suits.Diamond: [],
	DeckitPlayingCard.Suits.Spade: [],
	DeckitPlayingCard.Suits.Club: [],
	DeckitPlayingCard.Suits.Gold: [],
	DeckitPlayingCard.Suits.Cup: [],
	DeckitPlayingCard.Suits.Sword: [],
}
var cards: Array[DeckitPlayingCardUI] = []
var jokers: Array[DeckitPlayingCardUI] = []
var backs: Array[DeckitPlayingCard] = []
#endregion

var current_cards_by_suit: Dictionary[DeckitPlayingCard.Suits, Array] = {
	DeckitPlayingCard.Suits.Joker: [],
	DeckitPlayingCard.Suits.Heart: [],
	DeckitPlayingCard.Suits.Diamond: [],
	DeckitPlayingCard.Suits.Spade: [],
	DeckitPlayingCard.Suits.Club: [],
	DeckitPlayingCard.Suits.Gold: [],
	DeckitPlayingCard.Suits.Cup: [],
	DeckitPlayingCard.Suits.Sword: []
}
var current_cards: Array[DeckitPlayingCardUI] = []
var discard_pile: Array[DeckitPlayingCardUI] = []
var current_back_texture: Texture2D


func _ready() -> void:
	DeckitUtils.remove_child_nodes(self)
	filled.connect(on_filled_deck)


func on_filled_deck() -> void:
	draw_visual_pile()
	

#region Preparation
func load_deck_record(deck_record: DeckitDeckPreloader.DeckRecord) -> DeckitDeck:
	clear_deck()
	
	deck_type = deck_record.type
	## Backs does not need to be instantiated as DeckitPlayingCardUI
	for back in deck_record.backs:
		backs.append(back) 
		
	if backs.size() > 0:
		current_back_texture = backs.pick_random().back_texture
	
	load_cards_from_record(deck_record.jokers, DeckitPlayingCard.Suits.Joker)
	load_cards_from_record(deck_record.clubs, DeckitPlayingCard.Suits.Club)

	if deck_record.is_french():
		load_cards_from_record(deck_record.hearts, DeckitPlayingCard.Suits.Heart)
		load_cards_from_record(deck_record.diamonds, DeckitPlayingCard.Suits.Diamond)
		load_cards_from_record(deck_record.spades, DeckitPlayingCard.Suits.Spade)
		
	elif deck_record.is_spanish():
		load_cards_from_record(deck_record.golds, DeckitPlayingCard.Suits.Gold)
		load_cards_from_record(deck_record.cups, DeckitPlayingCard.Suits.Cup)
		load_cards_from_record(deck_record.swords, DeckitPlayingCard.Suits.Sword)

	loaded_new_deck.emit()

	return self
	

func load_cards_from_record(deck_cards: Array[DeckitPlayingCard], suit: DeckitPlayingCard.Suits) -> void:
	for card in deck_cards:
		var playing_card: DeckitPlayingCardUI = playing_card_scene.instantiate() as DeckitPlayingCardUI
		playing_card.card = card
		
		cards.append(playing_card)
		cards_by_suit[suit].append(playing_card)
	

func fill() -> DeckitDeck:
	current_cards = cards.duplicate()
	current_cards_by_suit = cards_by_suit.duplicate(true)
	## The jokers can be only added by the function 'add_jokers'
	#current_cards_by_suit[DeckitPlayingCard.Suits.Joker].clear()
	
	filled.emit()
	
	return self


func shuffle() -> DeckitDeck:
	current_cards.shuffle()
	shuffled.emit()
	
	return self


func clear_deck() -> void:
	backs.clear()
	jokers.clear()
	discard_pile.clear()
	cards.clear()
	current_cards.clear()
	
	current_cards_by_suit = {
		DeckitPlayingCard.Suits.Joker: [],
		DeckitPlayingCard.Suits.Heart: [],
		DeckitPlayingCard.Suits.Diamond: [],
		DeckitPlayingCard.Suits.Spade: [],
		DeckitPlayingCard.Suits.Club: [],
		DeckitPlayingCard.Suits.Gold: [],
		DeckitPlayingCard.Suits.Cup: [],
		DeckitPlayingCard.Suits.Sword: [],
	}
	
	cards_by_suit = {
		DeckitPlayingCard.Suits.Joker: [],
		DeckitPlayingCard.Suits.Heart: [],
		DeckitPlayingCard.Suits.Diamond: [],
		DeckitPlayingCard.Suits.Spade: [],
		DeckitPlayingCard.Suits.Club: [],
		DeckitPlayingCard.Suits.Gold: [],
		DeckitPlayingCard.Suits.Cup: [],
		DeckitPlayingCard.Suits.Sword: [],
	}
	
	cleared_deck.emit()
#endregion


func change_back_texture(new_texture: Texture2D) -> void:
	current_back_texture = new_texture
	draw_visual_pile(current_back_texture)
	
	
func add_cards(new_cards: Array[DeckitPlayingCardUI], allow_duplicates: bool = allow_duplicate_cards) -> void:
	for card: DeckitPlayingCardUI in new_cards:
		add_card(card, allow_duplicates)
	
	added_cards.emit(new_cards)


func add_card(playing_card: DeckitPlayingCardUI, allow_duplicates: bool = allow_duplicate_cards) -> void:
	if allow_duplicates:
		current_cards.append(playing_card)
		current_cards_by_suit[playing_card.card.suit].append(playing_card)
	else:
		if not current_cards.has(playing_card):
			current_cards.append(playing_card)
			
		if not current_cards_by_suit[playing_card.card.suit].has(playing_card):
			current_cards_by_suit[playing_card.card.suit].append(playing_card)
	
	added_card.emit(playing_card)
	
	
func remove_card(playing_card: DeckitPlayingCardUI):
	current_cards.erase(playing_card)
	
	if current_cards_by_suit.has(playing_card.card.suit):
		current_cards_by_suit[playing_card.card.suit].erase(playing_card)
		removed_card.emit(playing_card)
	
	if is_empty():
		emptied_deck.emit()
	
	add_to_discard_pile(playing_card)
	

func add_jokers(amount: int, selected_card: DeckitPlayingCardUI = null) -> DeckitDeck:
	if amount > 0 and jokers.size() > 0:
		var new_jokers: Array[DeckitPlayingCardUI] = []
		var joker: DeckitPlayingCardUI = selected_card if selected_card != null and selected_card.card.is_joker() else jokers.pick_random()
		
		new_jokers.assign(DeckitUtils.repeat(joker, amount))
		
		add_cards(new_jokers)
		
	return self
	

#region Discard pile
func add_to_discard_pile(playing_card: DeckitPlayingCardUI) -> void:
	if not discard_pile.has(playing_card):
		discard_pile.append(playing_card)
		added_to_discard_pile.emit(playing_card)


func extract_from_discard_pile(playing_card: DeckitPlayingCardUI) -> DeckitPlayingCardUI:
	if discard_pile.has(playing_card):
		var selected_card: DeckitPlayingCardUI = discard_pile[discard_pile.find(playing_card)]
		discard_pile.erase(playing_card)
		
		return selected_card
	
	return null


func recover_from_discard_pile(playing_card: DeckitPlayingCardUI) -> DeckitPlayingCardUI:
	var card_to_recover: DeckitPlayingCardUI = extract_from_discard_pile(playing_card)
	
	if card_to_recover != null:
		add_card(card_to_recover)
		recovered_card_from_discard_pile.emit(playing_card)
	return null
#endregion


#region Pickers
func pick_cards(selected_cards: Array[DeckitPlayingCardUI]) -> Array[DeckitPlayingCardUI]:
	for card in selected_cards:
		pick_card(card)
		
	return selected_cards
	
	
func pick_card(card: DeckitPlayingCardUI) -> DeckitPlayingCardUI:
	remove_card(card)
	picked_card.emit(card)
	
	return card


func number_cards() -> Array[DeckitPlayingCardUI]:
	return extract_number_cards(current_cards)
	

func number_cards_from_suit(suit: DeckitPlayingCard.Suits) -> Array[DeckitPlayingCardUI]:
	return extract_number_cards(cards_from_suit(suit))


func figure_cards() -> Array[DeckitPlayingCardUI]:
	return extract_figure_cards(current_cards)
	

func figure_cards_from_suit(suit: DeckitPlayingCard.Suits) -> Array[DeckitPlayingCardUI]:
	return extract_figure_cards(cards_from_suit(suit))


func extract_number_cards(selected_cards: Array[DeckitPlayingCardUI]) -> Array[DeckitPlayingCardUI]:
	return selected_cards.filter(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_number())


func extract_figure_cards(selected_cards: Array[DeckitPlayingCardUI]) -> Array[DeckitPlayingCardUI]:
	return selected_cards.filter(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_figure())
	

func cards_from_suit(suit: DeckitPlayingCard.Suits) -> Array[DeckitPlayingCardUI]:
	if current_cards_by_suit.has(suit):
		return current_cards_by_suit[suit]
	
	return []

#endregion

#region Random pickers
func pick_random_card() -> DeckitPlayingCardUI:
	if current_cards.is_empty():
		return null
	
	return pick_card(current_cards.pick_random())
	

func pick_random_cards(amount: int) -> Array[DeckitPlayingCardUI]:
	if current_cards.is_empty():
		return []
	
	var selected_cards: Array[DeckitPlayingCardUI] = []
	amount = clamp(amount, 1, current_cards.size())
	
	for i in amount:
		selected_cards.append(pick_card(current_cards.pick_random()))
	
	return selected_cards


func pick_random_number_card() -> DeckitPlayingCardUI:
	var num_cards = number_cards()
	
	if num_cards.is_empty():
		return null
		
	return pick_card(num_cards.pick_random())


## The function parameter "suit" is not typed as the suits are separated into different enums
func pick_random_card_from_suit(suit: DeckitPlayingCard.Suits) -> DeckitPlayingCardUI:
	if current_cards_by_suit.has(suit) and current_cards_by_suit[suit].size() > 0:
		return pick_card(current_cards_by_suit[suit].pick_random())
	
	return null


func pick_random_card_of_value(value: int) -> DeckitPlayingCardUI:
	var selected_cards: Array[DeckitPlayingCardUI] = current_cards.filter(
		func(playing_card: DeckitPlayingCardUI): return playing_card.card.value == value
		)
	
	if selected_cards.size() > 0:
		return pick_card(selected_cards.pick_random())
	
	return null


func pick_random_card_of_suit_and_value(suit: DeckitPlayingCard.Suits, value: int) -> DeckitPlayingCardUI:
	var selected_cards: Array[DeckitPlayingCardUI] = cards_from_suit(suit).filter(
		func(playing_card: DeckitPlayingCardUI): return playing_card.card.value == value
		)
	
	if selected_cards.size() > 0:
		return pick_card(selected_cards.pick_random())
	
	return null


func pick_random_ace() -> DeckitPlayingCardUI:
	var aces: Array[DeckitPlayingCardUI] = current_cards.filter(
		func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_ace()
		)
	
	if aces.is_empty():
		return null
		
	return pick_card(aces.pick_random())


func pick_random_figure() -> DeckitPlayingCardUI:
	var figures: Array[DeckitPlayingCardUI] = current_cards.filter(
		func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_figure()
		)
	
	if figures.is_empty():
		return null
		
	return pick_card(figures.pick_random())


func pick_random_jack() -> DeckitPlayingCardUI:
	var jacks: Array[DeckitPlayingCardUI] = current_cards.filter(
		func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_jack()
		)
	
	if jacks.is_empty():
		return null
		
	return pick_card(jacks.pick_random())


func pick_random_queen() -> DeckitPlayingCardUI:
	var queens: Array[DeckitPlayingCardUI] = current_cards.filter(
		func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_queen()
		)
	
	if queens.is_empty():
		return null
		
	return pick_card(queens.pick_random())


func pick_random_knight() -> DeckitPlayingCardUI:
	var knights: Array[DeckitPlayingCardUI] = current_cards.filter(
		func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_knight()
		)
	
	if knights.is_empty():
		return null
		
	return pick_card(knights.pick_random())


func pick_random_king() -> DeckitPlayingCardUI:
	var kings: Array[DeckitPlayingCardUI] = current_cards.filter(
		func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_king()
		)
	
	if kings.is_empty():
		return null
		
	return pick_card(kings.pick_random())


func pick_random_joker() -> DeckitPlayingCardUI:
	var selected_jokers: Array[DeckitPlayingCardUI] = current_cards.filter(
		func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_joker()
		)
	
	if selected_jokers.is_empty():
		return null
		
	return pick_card(selected_jokers.pick_random())

#endregion

#region Information
func is_spanish() -> bool:
	return deck_type == DeckType.Spanish
	

func is_french() -> bool:
	return deck_type == DeckType.French
	
	
func has_aces() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_ace())


func has_number_cards() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_number())
	
	
func has_jokers() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_joker())
	

func has_only_jokers() -> bool:
	return current_cards.all(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_joker())
	
	
func has_figures() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_figure())
	

func has_jacks() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_jack())
	
	
func has_queens() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_queen())
	

func has_knights() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_knight())
	

func has_kings() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_king())
	
func has_clubs() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_club())
	
	
func has_hearts() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_heart())


func has_diamonds() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_diamond())


func has_spades() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_spade())


func has_cups() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_cup())


func has_golds() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_gold())


func has_swords() -> bool:
	return current_cards.any(func(playing_card: DeckitPlayingCardUI): return playing_card.card.is_sword())


func is_empty() -> bool:
	return (has_only_jokers() and not jokers_count_for_empty_deck) or current_cards.is_empty()


func deck_size() -> int:
	return current_cards.size()


func discard_pile_size() -> int:
	return discard_pile.size()
#endregion

#region Debug
func draw_visual_pile(card_texture: Texture2D = current_back_texture) -> void:
	if is_node_ready() and current_cards.size() > 0:
		DeckitUtils.remove_child_nodes(self)
		
		for index in visual_pile_cards_amount:
			var visual_placeholder_card = TextureRect.new()
			visual_placeholder_card.name = "VisualPileCard %d" % index
			visual_placeholder_card.position += (stack_separation * stack_direction) * index
			visual_placeholder_card.texture = card_texture
			visual_placeholder_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			visual_placeholder_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			visual_placeholder_card.set_deferred("size", current_cards[0].card.texture_size)
			visual_placeholder_card.set_deferred("anchors_preset", Control.PRESET_CENTER)
			
			add_child(visual_placeholder_card)


func draw_preview_cards() -> void:
	if Engine.is_editor_hint() and is_inside_tree():
		DeckitUtils.remove_child_nodes(self)
			
		for index in preview_cards_to_display:
			var preview_card = TextureRect.new()
			preview_card.name = "DebugVisualPileCard"
			preview_card.position += (stack_separation * stack_direction) * index
			preview_card.texture = preview_display_texture
			preview_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			preview_card.set_deferred("size", preview_texture_size * preview_texture_scale)
			preview_card.set_deferred("anchors_preset", Control.PRESET_CENTER)
			add_child(preview_card)
			
			DeckitUtils.set_owner_to_edited_scene_root(preview_card)
			DeckitUtils.center_texture_rect_pivot(preview_card)
#endregion

func _calculate_visual_pile_counter() -> int:
	@warning_ignore("integer_division")
	return ceili(cards.size() / maxi(1, visual_pile_cards_amount))
