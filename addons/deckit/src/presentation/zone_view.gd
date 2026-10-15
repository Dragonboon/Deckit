## Optional renderer for one DeckitCardZone.
## Reuses card buttons on refresh to preserve focus and reduce allocations.
@icon("res://addons/deckit/assets/card_pile.svg")
class_name DeckitZoneView extends VBoxContainer

signal card_requested(zone_id: StringName, instance_id: StringName)
signal drop_completed(action: DeckitCardAction, accepted: bool)
signal card_position_changed(instance_id: StringName, position: Vector2)

var game_state: DeckitGameState
var zone_id: StringName = &""
var viewer_id: StringName = &""
var reveal_owned_cards: bool = true
var show_card_count: bool = true
## 0 displays all cards; positive values display only the top N cards.
var max_visible_cards: int = 0

## Opt-in local interaction. Set actor explicitly; viewer identity is not authority.
var drag_enabled: bool = false
var drop_enabled: bool = false
var actor_id: StringName = &""
## Set before adding to the tree. Free layout stores UI positions, not game rules.
var free_layout: bool = false
var table_height: float = 280.0
var card_positions: Dictionary[StringName, Vector2] = {}
var _heading: Label
var _cards_row: Control
var _views: Dictionary = {}
var _selected_ids: Array[StringName] = []


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	_heading = Label.new()
	_heading.add_theme_font_size_override("font_size", 18)
	add_child(_heading)
	_cards_row = Control.new() if free_layout else HFlowContainer.new()
	if free_layout:
		_cards_row.custom_minimum_size = Vector2(260, table_height)
		_cards_row.clip_contents = true
		_cards_row.resized.connect(_clamp_positions)
	else:
		_cards_row.custom_minimum_size = Vector2(128, 184)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_cards_row.mouse_filter = Control.MOUSE_FILTER_PASS
	_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_row.add_theme_constant_override("h_separation", 8)
	_cards_row.add_theme_constant_override("v_separation", 8)
	add_child(_cards_row)
	_cards_row.set_drag_forwarding(Callable(), _can_drop_data, _drop_on_surface)
	refresh()


func bind(state: DeckitGameState, target_zone_id: StringName, player_id: StringName = &"") -> void:
	if game_state != null and game_state.action_applied.is_connected(_on_action_applied):
		game_state.action_applied.disconnect(_on_action_applied)
	if game_state != state or zone_id != target_zone_id:
		card_positions.clear()
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
	var zone: DeckitCardZone = game_state.get_zone(zone_id) if game_state != null else null
	_heading.text = "Zone unavailable: %s" % String(zone_id) if zone == null else String(zone_id).capitalize()
	if zone == null:
		_clear_views()
		return
	if show_card_count:
		_heading.text += " (%d)" % zone.size()

	var active: Dictionary = {}
	var first_index: int = maxi(0, zone.cards.size() - max_visible_cards) if max_visible_cards > 0 else 0
	var visible_index: int = 0
	for index in range(first_index, zone.cards.size()):
		var card: DeckitCardInstance = zone.cards[index]
		if card == null:
			continue
		var key: StringName = card.instance_id
		var card_view: DeckitCardView = _views.get(key, null)
		if card_view == null:
			card_view = DeckitCardView.new()
			_cards_row.add_child(card_view)
			card_view.card_requested.connect(_on_card_requested)
			_views[key] = card_view
		# Keep order consistent with the zone, including after shuffles.
		_cards_row.move_child(card_view, visible_index)
		visible_index += 1
		card_view.drag_enabled = drag_enabled
		card_view.drag_game = game_state
		card_view.drag_zone_id = zone_id
		card_view.drag_actor_id = actor_id
		card_view.set_drag_forwarding(Callable(), _can_drop_data,
			func(point: Vector2, data: Variant) -> void:
				_drop_on_surface(_cards_row.get_global_transform().affine_inverse() * (card_view.get_global_transform() * point), data))
		card_view.display_card(card, _can_reveal(zone, card))
		if free_layout:
			card_view.size = card_view.custom_minimum_size
			if not card_positions.has(key):
				card_positions[key] = Vector2(16 + ((visible_index - 1) % 4) * 138, 12 + ((visible_index - 1) / 4) * 28)
			set_card_position(key, card_positions[key])
		card_view.set_selected(_selected_ids.has(key))
		active[key] = true

	for key in _views.keys():
		if not active.has(key):
			var removed: DeckitCardView = _views[key]
			_cards_row.remove_child(removed)
			removed.queue_free()
			_views.erase(key)
			card_positions.erase(key)


## Explicitly highlight the cards selected by the consuming scene.
## This method does not select targets or execute any game action.
func set_selected_cards(ids: Array[StringName]) -> void:
	_selected_ids = ids.duplicate()
	for key in _views:
		var view: DeckitCardView = _views[key]
		view.set_selected(_selected_ids.has(key))


func clear_selection() -> void:
	var empty: Array[StringName] = []
	set_selected_cards(empty)


func _clear_views() -> void:
	for view: DeckitCardView in _views.values():
		_cards_row.remove_child(view)
		view.queue_free()
	_views.clear()


func get_card_view(instance_id: StringName) -> DeckitCardView:
	return _views.get(instance_id, null) if is_node_ready() else null


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


## Positions are local to the card surface. No zone order/state changes occur.
func set_card_position(id: StringName, point: Vector2) -> void:
	var view := get_card_view(id)
	if not free_layout or view == null or not point.is_finite():
		return
	var limit := (_cards_row.size - view.size).max(Vector2.ZERO)
	var bounded := point.clamp(Vector2.ZERO, limit)
	card_positions[id] = bounded
	view.position = bounded
	card_position_changed.emit(id, bounded)


func _clamp_positions() -> void:
	for id in card_positions.keys():
		set_card_position(id, card_positions[id])


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not drop_enabled or not data is DeckitCardDrag or not data.is_current(game_state):
		return false
	if data.source_zone_id == zone_id:
		return free_layout
	return game_state.can_perform(data.action_to(zone_id))


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var surface_point := _cards_row.get_global_transform().affine_inverse() * (get_global_transform() * at_position)
	_drop_on_surface(surface_point, data)


func _drop_on_surface(point: Vector2, data: Variant) -> void:
	# Revalidate on release: the game may have changed since the hover check.
	if not _can_drop_data(point, data):
		return
	var action: DeckitCardAction = data.action_to(zone_id)
	var accepted: bool = data.source_zone_id == zone_id or game_state.perform(action)
	if accepted:
		refresh()
		if free_layout:
			set_card_position(data.instance.instance_id, point - data.grab_offset)
			var view := get_card_view(data.instance.instance_id)
			if view != null:
				_cards_row.move_child(view, -1)
		drop_completed.emit(action, true)
	else:
		drop_completed.emit(action, false)
