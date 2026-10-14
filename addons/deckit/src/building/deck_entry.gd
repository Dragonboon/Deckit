## One card count in one arbitrary deck section.
## The host decides which sections (main, side, encounter, etc.) are legal.
@tool
class_name DeckitDeckEntry extends Resource

@export var card_id: StringName = &""
@export_range(1, 9999, 1) var quantity: int = 1
@export var section_id: StringName = &"main"
