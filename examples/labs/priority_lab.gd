## Demonstrates a generic priority window; no game-specific timing rules.
extends Control

var game := DeckitGameState.new()
var timeline := DeckitTurnManager.new()
var window := DeckitPriorityWindow.new()
var queue := DeckitEventQueue.new()
var bridge := DeckitPriorityEventBridge.new()
var gate := DeckitPriorityTurnGate.new()
var hand := DeckitCardZone.new(&"hand")
var table := DeckitCardZone.new(&"table")
var status: Label
var history: Label


func _ready() -> void:
	var page := DeckitLabUI.page(self, "08 • Priority Window",
		"Open a window, stage responses, pass in order, then resolve one action. The optional turn gate blocks transitions while the window is open.")
	var buttons := DeckitLabUI.controls(page)
	DeckitLabUI.button(buttons, "Open window", _open)
	DeckitLabUI.button(buttons, "Stage current player's card", _stage)
	DeckitLabUI.button(buttons, "Pass priority", _pass)
	DeckitLabUI.button(buttons, "Resolve next", _resolve)
	DeckitLabUI.button(buttons, "Next phase", _next_phase)
	DeckitLabUI.button(buttons, "Close empty", _close)
	DeckitLabUI.button(buttons, "Cancel window", _cancel)
	DeckitLabUI.button(buttons, "Drain event log", _drain)
	DeckitLabUI.button(buttons, "Reset", _reset)
	status = DeckitLabUI.info(page, "")
	history = DeckitLabUI.info(page, "Actions:")
	game.register_zone(hand)
	game.register_zone(table)
	timeline.configure([&"one", &"two"], [&"begin", &"action", &"end"])
	gate.priority_window = window
	timeline.add_rule(gate)
	timeline.start()
	queue.bind(game)
	bridge.bind(window, queue)
	window.action_resolved.connect(func(action: DeckitCardAction, success: bool) -> void:
		_log("Resolved %s: %s" % [action.card_instance_id, success])
	)
	window.resolution_ready.connect(func(count: int) -> void: _log("Ready to resolve (%d pending)" % count))
	_reset()


func _reset() -> void:
	window.cancel()
	hand.cards.clear()
	table.cards.clear()
	queue.clear_pending()
	for index in range(3):
		var definition := DeckitCardDefinition.new()
		definition.card_id = StringName("demo-%d" % index)
		definition.display_name = "Sample %d" % index
		var instance := DeckitCardInstance.new(definition, StringName("card-%d" % index))
		hand.add_card(instance)
	if not timeline.is_running:
		timeline.start()
	history.text = "Actions:"
	_refresh()


func _open() -> void:
	_log("Open: %s" % window.open_from_turn(game, timeline, &"sample-window"))
	_refresh()


func _stage() -> void:
	var actor := window.current_participant()
	var card := hand.peek_top()
	if card == null:
		_log("No card available")
		return
	var action := DeckitCardAction.new(&"hand", &"table", card.instance_id, actor)
	_log("Stage for %s: %s" % [actor, window.submit_action(actor, action)])
	_refresh()


func _pass() -> void:
	var actor := window.current_participant()
	_log("Pass %s: %s" % [actor, window.pass_priority(actor)])
	_refresh()


func _resolve() -> void:
	_log("Resolve result: %s" % window.resolve_next())
	_refresh()


func _next_phase() -> void:
	_log("Advance timeline: %s" % timeline.next_phase())
	_refresh()


func _close() -> void:
	_log("Close: %s" % window.close())
	_refresh()


func _cancel() -> void:
	_log("Cancel: %s" % window.cancel())
	_refresh()


func _drain() -> void:
	_log("Processed %d events" % queue.drain())
	_refresh()


func _log(message: String) -> void:
	history.text += "\n" + message
	if history.text.length() > 1800:
		history.text = "Actions:\n" + history.text.right(1300)


func _refresh() -> void:
	status.text = "Open: %s | Holder: %s | Passes: %d | Ready: %s | Staged: %d | Hand: %d | Table: %d | Phase: %s | Events: %d" % [
		window.is_open, window.current_participant(), window.consecutive_passes,
		window.ready_to_resolve, window.pending_count(), hand.size(), table.size(),
		timeline.current_phase(), queue.pending_count()
	]
