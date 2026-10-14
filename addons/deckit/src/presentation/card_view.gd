## Game-neutral card button. Never directly edits the represented card.
## Caller controls reveal_front and is responsible for hidden data security.
@icon("res://addons/deckit/assets/playing_card.svg")
class_name DeckitCardView extends Button

signal card_requested(instance_id: StringName)

var card_instance: DeckitCardInstance
var front_revealed: bool = false
## Visual selection only: the host owns action legality and selected IDs.
var is_selected: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(112, 158)
	focus_mode = Control.FOCUS_ALL
	toggle_mode = true
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pressed.connect(_on_pressed)
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


## Selection is presentation state, not a card or game-state mutation.
func set_selected(selected: bool) -> void:
	if is_selected == selected:
		return
	is_selected = selected
	if selected:
		var highlight := StyleBoxFlat.new()
		highlight.bg_color = Color(0.16, 0.29, 0.39, 0.94)
		highlight.border_color = Color(0.98, 0.76, 0.31)
		highlight.set_border_width_all(4)
		highlight.set_corner_radius_all(9)
		for state in ["normal", "hover", "pressed", "focus"]:
			add_theme_stylebox_override(state, highlight)
	else:
		for state in ["normal", "hover", "pressed", "focus"]:
			remove_theme_stylebox_override(state)
	refresh()


func _on_pressed() -> void:
	if card_instance != null:
		card_requested.emit(card_instance.instance_id)
