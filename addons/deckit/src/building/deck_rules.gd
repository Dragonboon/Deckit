## Optional generic build constraints; a game may omit them entirely.
@tool
class_name DeckitDeckRules extends Resource

@export_range(0, 9999, 1) var minimum_cards: int = 0
@export_range(0, 9999, 1) var maximum_cards: int = 0
## 0 means no generic limit. Individual card.deck_limit still applies.
@export_range(0, 9999, 1) var default_copy_limit: int = 0
@export var forbidden_ids: PackedStringArray = PackedStringArray()
@export var allowed_tags: PackedStringArray = PackedStringArray()
@export var forbidden_tags: PackedStringArray = PackedStringArray()
@export var sections: Array[DeckitDeckSectionRule] = []
@export var custom_rules: Array[DeckitDeckRule] = []
