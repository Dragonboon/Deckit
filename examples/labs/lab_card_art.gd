## Example-only SVG card art and small visual helpers.
## SVG source is rasterized once at runtime so a fresh Godot import is not
## required to preload texture resources in the example scripts.
class_name DeckitLabCardArt extends RefCounted

const FRONT_PATH: String = "res://examples/assets/card_front.svg"
const BACK_PATH: String = "res://examples/assets/card_back.svg"

static var _front: Texture2D
static var _back: Texture2D


static func _load_svg(path: String) -> Texture2D:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Deckit lab: Missing card placeholder at %s" % path)
		return null
	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	var image := Image.new()
	if image.load_svg_from_buffer(bytes) != OK:
		push_error("Deckit lab: Could not render placeholder at %s" % path)
		return null
	return ImageTexture.create_from_image(image)


static func front() -> Texture2D:
	if _front == null:
		_front = _load_svg(FRONT_PATH)
	return _front


static func back() -> Texture2D:
	if _back == null:
		_back = _load_svg(BACK_PATH)
	return _back


static func decorate(definition: DeckitCardDefinition) -> void:
	if definition == null:
		return
	if definition.front_texture == null:
		definition.front_texture = front()
	if definition.back_texture == null:
		definition.back_texture = back()


## Compact selectable image of one runtime card (example-only).
static func card_button(parent: Node, card: DeckitCardInstance, reveal: bool = true) -> DeckitCardView:
	var view := DeckitCardView.new()
	parent.add_child(view)
	decorate(card.definition)
	view.display_card(card, reveal)
	return view


## Displays current state, not a list of log messages.
static func zone_panel(
	parent: Node,
	game: DeckitGameState,
	id: StringName,
	viewer: StringName = &"",
	max_cards: int = 3
) -> DeckitZoneView:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 178)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 8)
	panel.add_child(margin)
	var view := DeckitZoneView.new()
	view.max_visible_cards = max_cards
	margin.add_child(view)
	view.bind(game, id, viewer)
	return view


static func zone_row(parent: Node) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	parent.add_child(row)
	return row
