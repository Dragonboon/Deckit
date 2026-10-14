## Game-neutral card button. Never directly edits the represented card.
## Caller controls reveal_front and is responsible for hidden data security.
@icon("res://addons/deckit/assets/playing_card.svg")
class_name DeckitCardView extends Button

signal card_requested(instance_id: StringName)

var card_instance: DeckitCardInstance
var front_revealed: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(112, 158)
	focus_mode = Control.FOCUS_ALL
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
	if not is_node_ready():
		return


func _on_pressed() -> void:
	if card_instance != null:
		card_requested.emit(card_instance.instance_id)
