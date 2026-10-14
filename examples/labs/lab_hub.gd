extends Control


func _ready() -> void:
	var page := DeckitLabUI.page(
		self, "Deckit • Example Labs",
		"Isolated scenarios for inspecting reusable card mechanics. The labs live outside addons/deckit/ and are not game-specific modules."
	)
	DeckitLabUI.heading(page, "Choose an experiment")
	DeckitLabUI.button(page, "01  Zone flow: draw, move, shuffle, flip, counters", _open.bind("zone_flow_lab"))
	DeckitLabUI.button(page, "02  Rule gates: optional rule, ownership, capacity", _open.bind("rule_gate_lab"))
	DeckitLabUI.button(page, "03  Visual components: layouts, drag, pile, card faces", _open.bind("legacy_ui_lab"))
	DeckitLabUI.button(page, "04  State + presentation: observable zones and viewer access", _open.bind("presenter_lab"))
	DeckitLabUI.button(page, "05  Targets, effects, conditions and sequences", _open.bind("actions_lab"))
	DeckitLabUI.button(page, "06  Event queue: notifications, priorities and responses", _open.bind("events_lab"))
	DeckitLabUI.button(page, "07  Optional timeline: phases, turns and pause", _open.bind("turns_lab"))
	DeckitLabUI.button(page, "08  Priority windows: passes, responses and resolution", _open.bind("priority_lab"))
	DeckitLabUI.button(page, "09  Deck Builder: catalog, editing and validation", _open.bind("deck_builder_lab"))
	DeckitLabUI.heading(page, "Playable examples (rules outside the plugin)")
	DeckitLabUI.button(page, "10  Spanish Tricks: follow suit, trump, 3 tricks", _open_microgame.bind("spanish_tricks"))
	DeckitLabUI.button(page, "11  French Melds: runs, sets and score", _open_microgame.bind("french_melds"))
	DeckitLabUI.button(page, "12  Resource Duel: energy, protection and effects", _open_microgame.bind("resource_duel"))
	DeckitLabUI.info(
		page,
		"Use Tab and Shift+Tab to navigate; Enter or Space activates focused buttons. Each example is independent of the installable addon."
	)


func _open(lab_name: String) -> void:
	get_tree().change_scene_to_file("res://examples/labs/%s.tscn" % lab_name)


func _open_microgame(game_name: String) -> void:
	get_tree().change_scene_to_file("res://examples/microgames/%s.tscn" % game_name)
