## Editor bootstrap regression. Run after the import pass in Godot 4.7.2.
## The editor plugin itself is loaded automatically when enabled.
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var issues: Array[String] = []
	var script: Script = load("res://addons/deckit/plugin.gd") as Script
	if script == null or not script.can_instantiate():
		issues.append("Deckit editor plugin script did not compile.")
	var session := DeckitDemoSpanishTricks.new()
	if not session.setup(420):
		issues.append("Spanish microgame failed to initialize.")
	elif session.get_hand(&"p1").size() != 3 or session.get_hand(&"p2").size() != 3:
		issues.append("Spanish hands have incorrect sizes.")
	# Smoke test the const rank list through the native PackedInt32Array API.
	var ranks := PackedInt32Array(DeckitDemoSpanishTricks.STRENGTH)
	if ranks.size() != 10 or ranks[0] != 1:
		issues.append("Spanish rank strength order failed.")
	for issue in issues:
		push_error("[Deckit bootstrap] " + issue)
	print("[Deckit bootstrap] %d issues" % issues.size())
	quit(0 if issues.is_empty() else 1)
