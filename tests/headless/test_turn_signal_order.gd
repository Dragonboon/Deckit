## Lifecycle callbacks are synchronous and cannot reenter transitions.
extends SceneTree

var passed := 0
var failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("[Deckit signal order] " + message)


func _run() -> void:
	var turns := DeckitTurnManager.new()
	_check(turns.configure([&"a", &"b"], [&"start", &"end"]), "Configure")
	var reentered: bool = false
	var visited: Array[String] = []
	turns.turn_started.connect(func(_player: StringName, _number: int, _round: int) -> void:
		reentered = turns.next_phase()
	)
	turns.phase_ended.connect(func(participant: StringName, phase: StringName, _number: int) -> void:
		visited.append("end:%s:%s:%s:%s" % [participant, phase, turns.current_participant(), turns.current_phase()])
	)
	turns.turn_ended.connect(func(participant: StringName, _number: int, _round: int) -> void:
		visited.append("turn:%s:%s:%s" % [participant, turns.current_participant(), turns.current_phase()])
	)
	_check(turns.start(), "Start")
	_check(not reentered and turns.current_phase() == &"start", "Cannot reenter start")
	_check(turns.end_turn(), "Next turn")
	_check(visited[0] == "end:a:start:a:start", "Outgoing phase before mutation")
	_check(visited[1] == "turn:a:a:start", "Outgoing turn before mutation")
	_check(turns.current_participant() == &"b" and not reentered, "Incoming start guarded")
	print("[Deckit signal order] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
