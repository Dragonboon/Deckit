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
	DeckitLabUI.info(
		page,
		"Start each lab independently; use the All labs button to return. Labs 01–02 exercise the headless core; 03 tests legacy nodes; 04 uses the optional new presenter without game rules."
	)


func _open(lab_name: String) -> void:
	get_tree().change_scene_to_file("res://examples/labs/%s.tscn" % lab_name)
