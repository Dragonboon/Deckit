## Reusable, immutable-by-convention design data for a card.
## One definition may be shared by many distinct DeckitCardInstance objects.
@tool
class_name DeckitCardDefinition extends Resource

@export var card_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var front_texture: Texture2D
@export var back_texture: Texture2D
@export var tags: PackedStringArray = PackedStringArray()
## Game-specific stats such as cost, attack, faction, rarity or suit.
@export var attributes: Dictionary = {}
## Optional deck-building hint; 0 means no definition-level limit.
## Deckit does not enforce this without an explicit rule.
@export_range(0, 999, 1) var deck_limit: int = 0


func has_tag(tag: String) -> bool:
	return tags.has(tag)


func get_attribute(key: StringName, fallback: Variant = null) -> Variant:
	return attributes.get(key, fallback)
