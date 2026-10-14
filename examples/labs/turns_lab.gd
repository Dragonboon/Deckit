extends Control

var timeline := DeckitTurnManager.new()
var queue := DeckitEventQueue.new()
var game := DeckitGameState.new()
var bridge := DeckitTurnEventBridge.new()
var status: Label
var log_view: Label


func _ready() -> void:
	var page := DeckitLabUI.page(
		self, "07 • Turns & Phases",
		"Optional timeline with two participants and three arbitrary phase names. Transitions emit signals and events, never force game rules."
	)
	var controls := DeckitLabUI.controls(page)
	DeckitLabUI.button(controls, "Start", _start)
	DeckitLabUI.button(controls, "Next phase", _next_phase)
	DeckitLabUI.button(controls, "End turn", _end_turn)
	DeckitLabUI.button(controls, "Pause / Resume", _toggle_pause)
	DeckitLabUI.button(controls, "Resolve events", _drain)
	DeckitLabUI.button(controls, "Stop", _stop)
	status = DeckitLabUI.info(page, "")
	log_view = DeckitLabUI.info(page, "Timeline log:")
	timeline.configure(
		[&"player-a", &"player-b"],
		[&"prepare", &"main", &"cleanup"]
	)
	queue.bind(game)
	bridge.bind(timeline, queue)
	timeline.phase_started.connect(func(player: StringName, phase: StringName, turn: int) -> void:
		_record("START %s / %s (turn %d)" % [player, phase, turn])
	)
	timeline.turn_ended.connect(func(player: StringName, turn: int, round: int) -> void:
		_record("END %s (turn %d, round %d)" % [player, turn, round])
	)
	timeline.transition_denied.connect(func(player: StringName, phase: StringName) -> void:
		_record("DENIED %s / %s" % [player, phase])
	)
	_refresh()


func _start() -> void:
	_record("Start: %s" % timeline.start())
	_refresh()


func _next_phase() -> void:
	_record("Next phase: %s" % timeline.next_phase())
	_refresh()


func _end_turn() -> void:
	_record("End turn: %s" % timeline.end_turn())
	_refresh()


func _toggle_pause() -> void:
	var changed: bool = timeline.resume() if timeline.is_paused else timeline.pause()
	_record("Pause toggle: %s" % changed)
	_refresh()


func _stop() -> void:
	_record("Stop: %s" % timeline.stop())
	_refresh()


func _drain() -> void:
	_record("Resolved %d event notifications" % queue.drain())
	_refresh()


func _record(message: String) -> void:
	log_view.text += "\n" + message
	if log_view.text.length() > 1800:
		log_view.text = "Timeline log:\n" + log_view.text.right(1300)


func _refresh() -> void:
	status.text = "Running: %s | Paused: %s | Player: %s | Phase: %s | Turn: %d | Round: %d | Queued: %d" % [
		timeline.is_running, timeline.is_paused, timeline.current_participant(),
		timeline.current_phase(), timeline.turn_number, timeline.round_number,
		queue.pending_count()
	]
