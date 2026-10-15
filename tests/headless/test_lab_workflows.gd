extends SceneTree

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var table = load("res://examples/labs/zone_flow_lab.tscn").instantiate()
	root.add_child(table)
	await process_frame
	check(table.game.get_zone(&"hand").is_empty(), "Startup never draws implicitly")
	table._draw_card()
	check(table.game.get_zone(&"hand").size() == 1, "Tabletop draw")
	table._move_selected(&"table")
	check(table.game.get_zone(&"table").size() == 1, "Keyboard/button transfer")
	table._flip()
	check(not table.game.get_zone(&"table").peek_top().face_up, "Flip through effect")
	table._reset()
	check(table.game.get_zone(&"draw").size() == 8 and table.selected_id == &"", "Tabletop reset")
	table.free()
	var lab = load("res://examples/labs/priority_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab._open()
	lab._select(&"hand", &"card-0")
	lab._stage()
	lab._select(&"hand", &"card-1")
	lab._stage()
	check(lab.window.pending_count() == 2 and lab.hand.size() == 3, "Different proposals leave cards in hand")
	check(not lab.timeline.next_phase(), "Open window gates phase advancement")
	lab._pass()
	lab._pass()
	lab._resolve()
	check(lab.table.peek_top().instance_id == &"card-1", "LIFO resolves response first")
	lab._react()
	check(lab.table.peek_top().get_counter(&"arrival") == 1, "Movement event applies exactly one arrival reaction")
	lab._pass()
	lab._pass()
	lab._resolve()
	check(lab.table.size() == 2, "Second action resolves after fresh passes")
	lab._select(&"hand", &"card-2")
	lab._stage()
	lab._pass()
	lab._pass()
	lab._resolve()
	check(lab.hand.size() == 1 and lab.table.size() == 2, "Restricted card rejected on resolution")
	lab._cancel()
	lab._next_phase()
	lab._reset()
	check(lab.timeline.current_phase() == &"begin" and lab.timeline.current_participant() == &"one", "Reset restores phase and participant")
	check(lab.window.pending_count() == 0 and lab.queue.pending_count() == 0, "Reset clears stack and event queue")
	lab._order()
	lab._open()
	lab._select(&"hand", &"card-0")
	lab._stage()
	lab._select(&"hand", &"card-1")
	lab._stage()
	lab._pass()
	lab._pass()
	lab._resolve()
	check(lab.table.peek_top().instance_id == &"card-0", "FIFO resolves first proposal first")
	lab.free()
	var workshop = load("res://examples/labs/deck_builder_lab.tscn").instantiate()
	root.add_child(workshop)
	await process_frame
	workshop._build()
	check(workshop.game.get_zone(&"preview").size() == 4, "Valid starter materializes")
	workshop.editor.deck.add(&"sample-01", 5)
	workshop._build()
	check(not workshop.factory.last_errors.is_empty(), "Invalid recipe cannot materialize")
	check(workshop.game.get_zone(&"preview").size() == 4, "Failed build preserves previous preview")
	workshop._reset()
	check(workshop.game.get_zone(&"preview").is_empty(), "Workshop reset clears preview")
	workshop.free()
	print("[Deckit guided labs] %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
