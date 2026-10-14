## A small, game-agnostic card button. The view never changes card state.
## Caller decides whether card identity may be revealed.
@icon("res://addons/deckit/assets/playing_card.svg")
class_name DeckitCardView extends Button

signal card_requested(instance_id: StringName)

var card_instance: DeckitCardInstance
var front_revealed: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(118, 154)
	focus_mode = Control.FOCUS_ALL
	pressed.connect(_on_pressed)
	refresh()


## Bind a runtime card; setting reveal_front=true does not grant data access.
## The host must still protect hidden data when networking.
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
			text += "\nCounters: %d" % card_instance.counters.size()
		icon = definition.front_texture
		tooltip_text = label
	else:
		text = "Face down"
		icon = definition.back_texture if definition != null else null
		tooltip_text = "Concealed card"


func _on_pressed() -> void:
	if card_instance != null:
		card_requested.emit(card_instance.instance_id)
