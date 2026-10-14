extends SceneTree

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("[Deckit turns] " + label)


func _run() -> void:
	var timeline := DeckitTurnManager.new()
	_check(not timeline.start(), "Start without configuration denied")
	_check(not timeline.configure([&"a", &"a"], [&"start"]), "Duplicate players denied")
	_check(not timeline.configure([&"a"], [&"", &"end"]), "Empty phase denied")
	_check(timeline.configure([&"a", &"b"], [&"start", &"action", &"end"]), "Configure")
	var game := DeckitGameState.new()
	var queue := DeckitEventQueue.new()
	_check(queue.bind(game), "Bind queue")
	var bridge := DeckitTurnEventBridge.new()
	_check(bridge.bind(timeline, queue), "Bind optional bridge")
	_check(timeline.start(), "Start configured timeline")
	_check(timeline.current_participant() == &"a" and timeline.current_phase() == &"start", "First state")
	_check(timeline.turn_number == 1 and timeline.round_number == 1, "Initial counters")
	_check(queue.pending_count() == 2, "Start signals published")
	_check(not timeline.configure([&"other"], [&"phase"]), "Cannot reconfigure running timeline")
	_check(timeline.next_phase() and timeline.current_phase() == &"action", "Advance phase")
	_check(timeline.pause() and not timeline.next_phase(), "Pause denies advancement")
	_check(not timeline.end_turn(), "Pause denies turn end")
	_check(timeline.resume(), "Resume")
	_check(timeline.end_turn(), "End turn")
	_check(timeline.current_participant() == &"b" and timeline.current_phase() == &"start", "Next participant")
	_check(timeline.turn_number == 2 and timeline.round_number == 1, "Turn counter")
	_check(timeline.end_turn() and timeline.current_participant() == &"a", "Wrap participant")
	_check(timeline.round_number == 2 and timeline.turn_number == 3, "Round wrap")
	_check(queue.pending_count() == 12, "Four notifications per turn change and first phase")
	_check(queue.drain() == 12, "Queue accepts bridge notifications")
	bridge.unbind()
	_check(timeline.stop(), "Stop")
	_check(timeline.current_participant() == &"" and timeline.turn_number == 0, "Stop clears progress")
	_check(timeline.start(&"b") and timeline.current_participant() == &"b", "Selectable starting participant")
	_check(queue.pending_count() == 0, "Unbound bridge no longer publishes")
	print("[Deckit turns] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
