## Optional renderer for one DeckitCardZone.
## Reuses card buttons on refresh to preserve focus and reduce allocations.
@icon("res://addons/deckit/assets/card_pile.svg")
class_name DeckitZoneView extends VBoxContainer

signal card_requested(zone_id: StringName, instance_id: StringName)

var game_state: DeckitGameState
var zone_id: StringName = &""
var viewer_id: StringName = &""
var reveal_owned_cards: bool = true
var show_card_count: bool = true
## 0 displays all cards; positive values display only the top N cards.
var max_visible_cards: int = 0

var _heading: Label
var _cards_row: HFlowContainer
var _views: Dictionary = {}


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
		card_view.display_card(card, _can_reveal(zone, card))
		active[key] = true

	for key in _views.keys():
		if not active.has(key):
			var removed: DeckitCardView = _views[key]
			_cards_row.remove_child(removed)
			removed.queue_free()
			_views.erase(key)


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
