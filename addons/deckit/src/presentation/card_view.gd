## Game-neutral card button. Never directly edits the represented card.
## Caller controls reveal_front and is responsible for hidden data security.
@icon("res://addons/deckit/assets/playing_card.svg")
class_name DeckitCardView extends Button

signal card_requested(instance_id: StringName)

var card_instance: DeckitCardInstance
var front_revealed: bool = false
## Visual selection only: the host owns action legality and selected IDs.
var is_selected: bool = false
## Disabled by default; the host supplies a state, source zone and acting player.
var drag_enabled: bool = false
var drag_game: DeckitGameState
var drag_zone_id: StringName = &""
var drag_actor_id: StringName = &""
var _art: TextureRect
var _caption: Label
var _caption_panel: PanelContainer
var _side: Label


func _ready() -> void:
	custom_minimum_size = Vector2(128, 184)
	focus_mode = Control.FOCUS_ALL
	toggle_mode = true
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pressed.connect(_on_pressed)
	# Keep Button text/icon as semantic state, with a separate predictable layout.
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color", "font_hover_pressed_color", "icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color", "icon_disabled_color", "icon_hover_pressed_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	clip_text = true
	_art = TextureRect.new()
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.offset_left = 7
	_art.offset_top = 7
	_art.offset_right = -7
	_art.offset_bottom = -7
	_side = Label.new()
	_side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side.position = Vector2(14, 10)
	_side.add_theme_font_size_override("font_size", 12)
	add_child(_side)
	_caption_panel = PanelContainer.new()
	_caption_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caption_panel)
	_caption_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_caption_panel.offset_left = 10
	_caption_panel.offset_right = -10
	_caption_panel.offset_top = -68
	_caption_panel.offset_bottom = -10
	_caption = Label.new()
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", 13)
	_caption_panel.add_child(_caption)
	refresh()


func display_card(card: DeckitCardInstance, reveal_front: bool) -> void:
	card_instance = card
	front_revealed = reveal_front
	refresh()


func refresh() -> void:
	disabled = card_instance == null
	if card_instance == null:
		text = "No card"
		icon = null
		tooltip_text = ""
		if _art != null:
			_art.texture = null
			_caption.text = text
			_side.text = ""
		return

	var definition: DeckitCardDefinition = card_instance.definition
	if front_revealed and definition != null:
		var label: String = definition.display_name
		if label.is_empty():
			label = String(definition.card_id)
		text = label
		if card_instance.exhausted:
			text += "\n[Exhausted]"
		if not card_instance.counters.is_empty():
			var labels := PackedStringArray()
			for key in card_instance.counters:
				labels.append("%s: %d" % [key, int(card_instance.counters[key])])
			text += "\n" + ", ".join(labels)
		icon = definition.front_texture
		tooltip_text = "Face up: %s. Activate to select." % label
	else:
		text = "Face down"
		icon = definition.back_texture if definition != null else null
		tooltip_text = "Face-down card. Activate to select."
	if is_selected:
		text += "\n● SELECTED"
		tooltip_text += " Selected. Activate to deselect."
	set_pressed_no_signal(is_selected)
	if _art != null:
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var face := StyleBoxFlat.new()
			face.bg_color = Color("f9f6ed") if front_revealed else Color("172c4b")
			face.border_color = Color("e8a52f") if is_selected else (Color("4c9ad4") if state == "focus" else Color("647888"))
			face.set_border_width_all(4 if is_selected else 2)
			face.set_corner_radius_all(9)
			add_theme_stylebox_override(state, face)
		_art.texture = icon
		_caption.text = text
		_side.text = "FRONT / FRENTE" if front_revealed else "BACK / DORSO"
		var ink := Color("172b3a") if front_revealed else Color("f4f7fb")
		_caption.add_theme_color_override("font_color", ink)
		_side.add_theme_color_override("font_color", ink)
		var background := StyleBoxFlat.new()
		background.bg_color = Color("f4f1e8") if front_revealed else Color("14283f")
		background.set_corner_radius_all(4)
		_caption_panel.add_theme_stylebox_override("panel", background)


func _get_drag_data(at_position: Vector2) -> Variant:
	if not drag_enabled or disabled or card_instance == null:
		return null
	var data := DeckitCardDrag.new(drag_game, drag_zone_id, card_instance, drag_actor_id, at_position)
	if not data.is_current(drag_game):
		return null
	var preview := Control.new()
	var image := DeckitCardView.new()
	preview.add_child(image)
	image.position = -at_position
	image.size = size
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.display_card(card_instance, front_revealed)
	set_drag_preview(preview)
	return data


## Selection is presentation state, not a card or game-state mutation.
func set_selected(selected: bool) -> void:
	if is_selected == selected:
		set_pressed_no_signal(selected)
		return
	is_selected = selected

	refresh()


func _on_pressed() -> void:
	if card_instance != null:
		card_requested.emit(card_instance.instance_id)
