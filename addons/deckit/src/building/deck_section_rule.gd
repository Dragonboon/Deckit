## Optional per-section count limits. 0 means no constraint.
@tool
class_name DeckitDeckSectionRule extends Resource

@export var section_id: StringName = &"main"
@export_range(0, 9999, 1) var minimum: int = 0
@export_range(0, 9999, 1) var maximum: int = 0
