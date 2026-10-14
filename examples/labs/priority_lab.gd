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
var zone_views: Array[DeckitZoneView] = []
var staged_cards: HFlowContainer
var staged_actions: Array[DeckitCardAction] = []


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
	var panels := DeckitLabCardArt.zone_row(page)
	zone_views.append(DeckitLabCardArt.zone_panel(panels, game, &"hand", &"", 3))
	zone_views.append(DeckitLabCardArt.zone_panel(panels, game, &"table", &"", 3))
	DeckitLabUI.heading(page, "Response stack — last in, first out")
	staged_cards = DeckitLabCardArt.zone_row(page)
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
	window.action_staged.connect(func(_actor: StringName, action: DeckitCardAction) -> void:
		staged_actions.append(action)
		_update_stack()
	)
	window.action_cancelled.connect(func(_action: DeckitCardAction) -> void:
		if not staged_actions.is_empty():
			staged_actions.pop_back()
		_update_stack()
	)
	window.action_resolved.connect(func(action: DeckitCardAction, success: bool) -> void:
		staged_actions.erase(action)
		_update_stack()
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
		DeckitLabCardArt.decorate(definition)
		var instance := DeckitCardInstance.new(definition, StringName("card-%d" % index))
		instance.face_up = true
		hand.add_card(instance)
	if not timeline.is_running:
		timeline.start()
	staged_actions.clear()
	_update_stack()
	for index in range(zone_views.size()):
		zone_views[index].bind(game, [&"hand", &"table"][index])
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
	for view in zone_views:
		view.refresh()
	status.text = "Open: %s | Holder: %s | Passes: %d | Ready: %s | Staged: %d | Hand: %d | Table: %d | Phase: %s | Events: %d" % [
		window.is_open, window.current_participant(), window.consecutive_passes,
		window.ready_to_resolve, window.pending_count(), hand.size(), table.size(),
		timeline.current_phase(), queue.pending_count()
	]


func _update_stack() -> void:
	if staged_cards == null:
		return
	for child in staged_cards.get_children():
		staged_cards.remove_child(child)
		child.queue_free()
	for index in range(staged_actions.size() - 1, -1, -1):
		var action: DeckitCardAction = staged_actions[index]
		var card: DeckitCardInstance = hand.find_by_id(action.card_instance_id)
		if card == null:
			card = table.find_by_id(action.card_instance_id)
		if card != null:
			var image := DeckitLabCardArt.card_button(staged_cards, card, true)
			image.disabled = true
			image.tooltip_text = "Resolution %d: %s" % [staged_actions.size() - index, action.card_instance_id]
