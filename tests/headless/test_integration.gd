## End-to-end coverage for time, priority, action rules and event queue.
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
		push_error("[Deckit integration] " + label)


func _run() -> void:
	var game := DeckitGameState.new()
	var source := DeckitCardZone.new(&"hand")
	var destination := DeckitCardZone.new(&"table")
	game.register_zone(source)
	game.register_zone(destination)
	var definition := DeckitCardDefinition.new()
	var instance := DeckitCardInstance.new(definition, &"unique-card")
	_check(source.add_card(instance), "Setup source card")

	var turns := DeckitTurnManager.new()
	_check(turns.configure([&"a", &"b"], [&"prepare", &"act"]), "Configure participants")
	var ended_observations: Array[String] = []
	var started_observations: Array[String] = []
	turns.phase_ended.connect(func(player: StringName, phase: StringName, _number: int) -> void:
		ended_observations.append("%s/%s:%s/%s" % [player, phase, turns.current_participant(), turns.current_phase()])
	)
	turns.phase_started.connect(func(player: StringName, phase: StringName, _number: int) -> void:
		started_observations.append("%s/%s:%s/%s" % [player, phase, turns.current_participant(), turns.current_phase()])
	)
	_check(turns.start(), "Start timeline")
	_check(turns.next_phase(), "Next phase")
	_check(ended_observations[0] == "a/prepare:a/prepare", "Phase end observes outgoing state")
	_check(started_observations.back() == "a/act:a/act", "Phase start observes incoming state")

	var queue := DeckitEventQueue.new()
	_check(queue.bind(game), "Bind event engine")
	var turn_bridge := DeckitTurnEventBridge.new()
	_check(turn_bridge.bind(turns, queue), "Bind turn events")
	var priority := DeckitPriorityWindow.new()
	var gate := DeckitPriorityTurnGate.new()
	gate.priority_window = priority
	_check(turns.add_rule(gate), "Bind optional turn guard")
	var priority_bridge := DeckitPriorityEventBridge.new()
	_check(priority_bridge.bind(priority, queue), "Bind priority events")
	_check(priority.open_from_turn(game, turns), "Open in current phase")
	_check(not turns.end_turn(), "Open window prevents turn advancement")
	_check(turns.current_participant() == &"a" and turns.current_phase() == &"act", "Denied transition is unchanged")

	var move := DeckitCardAction.new(&"hand", &"table", &"unique-card", &"a")
	_check(priority.submit_action(&"a", move), "Stage move from holder")
	_check(source.contains(instance) and destination.is_empty(), "Staging does not mutate")
	_check(priority.pass_priority(&"b") and priority.pass_priority(&"a"), "All participants pass")
	_check(priority.ready_to_resolve, "Resolution becomes available")
	_check(priority.resolve_next(), "Action executes via game state")
	_check(destination.contains(instance) and source.is_empty(), "Card moved once")
	_check(queue.pending_count() > 0, "Action, turn and priority events queued")
	_check(priority.pass_priority(&"a") and priority.pass_priority(&"b"), "Pass on empty window")
	_check(not priority.is_open, "Close window after empty pass cycle")
	_check(turns.end_turn() and turns.current_participant() == &"b", "Turn resumes")
	_check(ended_observations.back() == "a/act:a/act", "Turn end keeps outgoing state")
	_check(started_observations.back() == "b/prepare:b/prepare", "New turn observes incoming state")
	_check(queue.drain() > 0 and queue.pending_count() == 0, "Event queue resolves all notifications")
	_check(queue.get_trace().size() > 0, "Execution was traced")
	priority_bridge.unbind()
	turn_bridge.unbind()
	queue.unbind()

	_check(priority.open(game, [&"a", &"b"], &"b"), "Independent priority order")
	var stale := DeckitCardAction.new(&"hand", &"table", &"unique-card", &"b")
	_check(priority.submit_action(&"b", stale), "Stage rejected action")
	_check(priority.pass_priority(&"a") and priority.pass_priority(&"b"), "Pass rejected action to resolution")
	_check(not priority.resolve_next(), "Game validation rejects stale action")
	_check(destination.contains(instance) and priority.pending_count() == 0, "Rejected action preserves game state")
	_check(priority.cancel(), "Cancel remaining window")
	# Lambdas above capture the RefCounted emitter; disconnect before releasing it.
	for descriptor in turns.get_signal_list():
		for connection in turns.get_signal_connection_list(descriptor.name):
			turns.disconnect(descriptor.name, connection.callable)
	print("[Deckit integration] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
