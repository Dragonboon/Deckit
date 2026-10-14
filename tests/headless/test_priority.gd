extends SceneTree

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("[Deckit priority] " + label)


func _run() -> void:
	var game := DeckitGameState.new()
	var hand := DeckitCardZone.new(&"hand")
	var table := DeckitCardZone.new(&"table")
	game.register_zone(hand)
	game.register_zone(table)
	var definition := DeckitCardDefinition.new()
	for i in range(2):
		_check(hand.add_card(DeckitCardInstance.new(definition, StringName("c%d" % i))), "Seed card")
	var timeline := DeckitTurnManager.new()
	_check(timeline.configure([&"a", &"b"], [&"first", &"last"]), "Timeline config")
	_check(timeline.start(), "Timeline start")
	var window := DeckitPriorityWindow.new()
	var gate := DeckitPriorityTurnGate.new()
	gate.priority_window = window
	_check(timeline.add_rule(gate), "Register gate")
	_check(window.open_from_turn(game, timeline), "Open from timeline")
	_check(window.current_participant() == &"a", "First priority")
	_check(not timeline.next_phase(), "Turn transition blocked")
	_check(not window.submit_action(&"b", DeckitCardAction.new(&"hand", &"table", &"c0", &"b")), "Reject actor out of priority")
	_check(window.submit_action(&"a", DeckitCardAction.new(&"hand", &"table", &"c0", &"a")), "Stage action")
	_check(window.current_participant() == &"b" and window.pending_count() == 1, "Rotate after action")
	_check(window.pass_priority(&"b") and window.pass_priority(&"a"), "All pass")
	_check(window.ready_to_resolve and not window.pass_priority(&"b"), "Freeze priority for resolution")
	_check(window.resolve_next(), "Resolve validated move")
	_check(table.find_by_id(&"c0") != null and window.pending_count() == 0, "Only resolution mutates state")
	_check(window.current_participant() == &"a", "Starter gets next priority")
	_check(window.pass_priority(&"a") and window.pass_priority(&"b"), "Pass empty window")
	_check(not window.is_open and timeline.next_phase(), "Auto close restores timeline")
	_check(window.open(game, [&"a", &"b"], &"b"), "Custom first participant")
	_check(window.current_participant() == &"b", "Chosen starter")
	_check(window.submit_action(&"b", DeckitCardAction.new(&"hand", &"table", &"c1", &"b")), "Stage second action")
	_check(not window.close(), "No silent discard of pending action")
	_check(window.cancel() and hand.find_by_id(&"c1") != null, "Cancel does not execute")
	var queue := DeckitEventQueue.new()
	var bridge := DeckitPriorityEventBridge.new()
	_check(queue.bind(game) and bridge.bind(window, queue), "Optional bridge")
	_check(window.open(game, [&"a", &"b"]), "Reopen")
	_check(queue.pending_count() == 2, "Window and priority notifications")
	_check(window.cancel(), "Cancel bridged window")
	_check(queue.pending_count() == 3, "Window closed notification")
	bridge.unbind()
	print("[Deckit priority] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
