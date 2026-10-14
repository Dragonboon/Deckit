## Optional renderer for one registered DeckitCardZone.
## Renders card views and emits intent, but never mutates game state.
## Own-hand disclosure is opt-in through viewer_id; hidden zones stay hidden.
@icon("res://addons/deckit/assets/card_pile.svg")
class_name DeckitZoneView extends VBoxContainer

signal card_requested(zone_id: StringName, instance_id: StringName)

var game_state: DeckitGameState
var zone_id: StringName = &""
var viewer_id: StringName = &""
var reveal_owned_cards: bool = true
var show_card_count: bool = true

var _heading: Label
var _cards_row: HFlowContainer


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_heading = Label.new()
	_heading.add_theme_font_size_override("font_size", 18)
	add_child(_heading)

	_cards_row = HFlowContainer.new()
	_cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_row.add_theme_constant_override("h_separation", 8)
	_cards_row.add_theme_constant_override("v_separation", 8)
	add_child(_cards_row)
	refresh()


## May be called before or after adding this node to the scene tree.
func bind(state: DeckitGameState, target_zone_id: StringName, player_id: StringName = &"") -> void:
	if game_state != null and game_state.action_applied.is_connected(_on_action_applied):
		game_state.action_applied.disconnect(_on_action_applied)
	game_state = state
	zone_id = target_zone_id
	viewer_id = player_id
	if game_state != null:
		game_state.action_applied.connect(_on_action_applied)
	refresh()


func set_viewer(player_id: StringName) -> void:
	viewer_id = player_id
	refresh()


func refresh() -> void:
	if not is_node_ready():
		return
	for child in _cards_row.get_children():
		_cards_row.remove_child(child)
		child.queue_free()

	var zone: DeckitCardZone = null
	if game_state != null:
		zone = game_state.get_zone(zone_id)
	if zone == null:
		_heading.text = "Zone unavailable: %s" % String(zone_id)
		return

	_heading.text = String(zone_id).capitalize()
	if show_card_count:
		_heading.text += " (%d)" % zone.size()

	for card: DeckitCardInstance in zone.cards:
		var card_view := DeckitCardView.new()
		_cards_row.add_child(card_view)
		card_view.display_card(card, _can_reveal(zone, card))
		card_view.card_requested.connect(_on_card_requested)


func get_card_view(instance_id: StringName) -> DeckitCardView:
	if not is_node_ready():
		return null
	for child in _cards_row.get_children():
		var card_view := child as DeckitCardView
		if card_view != null and card_view.card_instance != null:
			if card_view.card_instance.instance_id == instance_id:
				return card_view
	return null


func _can_reveal(zone: DeckitCardZone, card: DeckitCardInstance) -> bool:
	if zone.visibility == DeckitCardZone.Visibility.HIDDEN:
		return false
	if zone.visibility == DeckitCardZone.Visibility.OWNER_ONLY:
		return reveal_owned_cards and viewer_id != &"" and viewer_id == zone.owner_id
	return card.face_up


func _on_card_requested(instance_id: StringName) -> void:
	card_requested.emit(zone_id, instance_id)


func _on_action_applied(action: DeckitCardAction) -> void:
	if action.source_zone_id == zone_id or action.destination_zone_id == zone_id:
		refresh()


func _exit_tree() -> void:
	if game_state != null and game_state.action_applied.is_connected(_on_action_applied):
		game_state.action_applied.disconnect(_on_action_applied)
