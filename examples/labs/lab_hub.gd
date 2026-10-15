extends Control


func _ready() -> void:
	var page := DeckitLabUI.page(self, "Deckit · Learn by playing",
		"Three focused labs. Each has a repeatable exercise, visible state and a Reset button. Start at 01; add only the modules your game needs.")
	DeckitLabUI.button(page, "01 · TABLETOP — draw, drag, drop, arrange, flip", _open.bind("zone_flow_lab"))
	DeckitLabUI.info(page, "Learn zones and presentation. Move cards freely while transfers still obey the game state.")
	DeckitLabUI.button(page, "02 · RULES & RESPONSES — conditions, events, turns, stack", _open.bind("priority_lab"))
	DeckitLabUI.info(page, "Stage different cards, pass priority and watch a move trigger a visible reaction.")
	DeckitLabUI.button(page, "03 · DECK WORKSHOP — catalog, limits, save, playtest", _open.bind("deck_builder_lab"))
	DeckitLabUI.info(page, "Build a valid list, materialize independent card instances and inspect them.")
	DeckitLabUI.heading(page, "Mini-tutorials / Recetas")
	DeckitLabUI.info(page, "docs/RECIPES.md: first hand, drag and drop, hidden cards, effects, reactions, turns/stack, deck construction. Examples remain outside addons/deckit/.")
	var more := VBoxContainer.new()
	DeckitLabUI.button(page, "Show / hide optional playable examples", func() -> void: more.visible = not more.visible)
	page.add_child(more)
	more.hide()
	for entry in [["Spanish Tricks", "spanish_tricks"], ["French Melds", "french_melds"], ["Resource Duel", "resource_duel"]]:
		DeckitLabUI.button(more, entry[0], _open_game.bind(entry[1]))
	DeckitLabUI.info(more, "Reference games with example-specific rules; these are not additional feature labs.")


func _open(scene: String) -> void:
	get_tree().change_scene_to_file("res://examples/labs/%s.tscn" % scene)


func _open_game(scene: String) -> void:
	get_tree().change_scene_to_file("res://examples/microgames/%s.tscn" % scene)
