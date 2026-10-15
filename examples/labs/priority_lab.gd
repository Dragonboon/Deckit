## One guided scenario combining optional mechanics without defining game rules in the addon.
extends Control

const RESPONDER = preload("res://examples/labs/sample_event_responder.gd")
const ACCESS_RULE = preload("res://examples/labs/sample_access_rule.gd")
var game := DeckitGameState.new()
var timeline := DeckitTurnManager.new()
var window := DeckitPriorityWindow.new()
var queue := DeckitEventQueue.new()
var gate := DeckitPriorityTurnGate.new()
var hand := DeckitCardZone.new(&"hand")
var table := DeckitCardZone.new(&"table")
var staged: Array[DeckitCardAction] = []
var chosen := DeckitTargetSelection.new(1)
var views: Array[DeckitZoneView] = []
var status: Label
var hint: Label
var history: Label
var stack_row: HFlowContainer
var stage_button: Button
var pass_button: Button
var resolve_button: Button
var effect_button: Button
var rule: DeckitCardRule


func _ready() -> void:
	var page := DeckitLabUI.page(self, "02 · Rules & responses / Reglas y respuestas",
		"Select A, open a window and stage it; select B and stage the response. Pass twice, resolve B, then process reactions. Pass twice again to resolve A.")
	DeckitLabUI.info(page, "Cards remain in hand while proposed. Only resolution changes zones. Card C is deliberately restricted: compare rejection with the accepted moves.")
	var controls := DeckitLabUI.controls(page)
	DeckitLabUI.button(controls, "Open window", _open)
	stage_button = DeckitLabUI.button(controls, "Stage selected", _stage)
	pass_button = DeckitLabUI.button(controls, "Pass priority", _pass)
	resolve_button = DeckitLabUI.button(controls, "Resolve next", _resolve)
	DeckitLabUI.button(controls, "Process reactions", _react)
	effect_button = DeckitLabUI.button(controls, "Conditional +1 charge", _effect)
	DeckitLabUI.button(controls, "Next phase", _next_phase)
	DeckitLabUI.button(controls, "LIFO / FIFO (empty window)", _order)
	DeckitLabUI.button(controls, "Cancel window", _cancel)
	DeckitLabUI.button(controls, "Reset", _reset)
	status = DeckitLabUI.info(page, "")
	hint = DeckitLabUI.info(page, "")
	var row := DeckitLabCardArt.zone_row(page)
	for id in [&"hand", &"table"]:
		var view := DeckitLabCardArt.zone_panel(row, game, id, &"", 0)
		view.card_requested.connect(_select)
		views.append(view)
	DeckitLabUI.heading(page, "Resolution order → first card shown resolves next")
	stack_row = DeckitLabCardArt.zone_row(page)
	history = DeckitLabUI.info(page, "")
	DeckitLabUI.info(page, "Integration: docs/RECIPES.md (#4–6). Rules and conditions must be pure checks; event reactions are explicitly drained. No automatic rollback.")
	game.register_zone(hand)
	game.register_zone(table)
	rule = ACCESS_RULE.new()
	rule.destination_id = &"table"
	rule.required_actor = &""
	game.register_rule(rule)
	gate.priority_window = window
	timeline.add_rule(gate)
	queue.register_responder(RESPONDER.new())
	queue.bind(game)
	window.action_resolved.connect(func(action: DeckitCardAction, success: bool) -> void:
		staged.erase(action)
		_log("%s: %s" % [action.card_instance_id, "moved to table" if success else "REJECTED by rule/state"]))
	_reset()


func _reset() -> void:
	window.cancel()
	staged.clear()
	chosen.clear()
	hand.cards.clear()
	table.cards.clear()
	queue.clear_pending()
	queue.clear_trace()
	timeline.stop()
	timeline.configure([&"one", &"two"], [&"begin", &"action", &"end"])
	timeline.start()
	window.resolution_order = DeckitPriorityWindow.ResolutionOrder.LIFO
	for index in range(3):
		var definition := DeckitCardDefinition.new()
		definition.card_id = StringName("demo-%d" % index)
		definition.display_name = "Card %s%s" % [char(65 + index), " (restricted)" if index == 2 else ""]
		definition.tags = PackedStringArray(["allowed"] if index != 2 else ["restricted"])
		DeckitLabCardArt.decorate(definition)
		var card := DeckitCardInstance.new(definition, StringName("card-%d" % index))
		card.face_up = true
		hand.add_card(card)
	for index in range(views.size()):
		views[index].bind(game, [&"hand", &"table"][index])
	history.text = "Results: reset complete."
	_refresh()


func _select(zone: StringName, id: StringName) -> void:
	chosen.clear()
	chosen.select(game, zone, id)
	_refresh()


func _open() -> void:
	_log("Open window: %s" % window.open_from_turn(game, timeline))
	_refresh()


func _is_staged(id: StringName) -> bool:
	for action in staged:
		if action.card_instance_id == id:
			return true
	return false


func _stage() -> void:
	var target := chosen.first()
	if target == null or target.zone_id != &"hand" or _is_staged(target.instance_id):
		return
	var action := DeckitCardAction.new(&"hand", &"table", target.instance_id, window.current_participant())
	if window.submit_action(action.actor_id, action):
		staged.append(action)
		_log("Staged %s by %s (not yet executed)." % [action.card_instance_id, action.actor_id])
		chosen.clear()
	_refresh()


func _pass() -> void:
	window.pass_priority(window.current_participant())
	_refresh()


func _resolve() -> void:
	window.resolve_next()
	chosen.clear()
	_refresh()


func _react() -> void:
	_log("Processed %d queued events. Accepted arrivals gain an arrival counter." % queue.drain())
	_refresh()


func _effect() -> void:
	var target := chosen.first()
	if target == null:
		return
	var effect := DeckitCounterEffect.new()
	effect.counter_key = &"charge"
	effect.delta = 1
	var action := DeckitEffectAction.new().configure(effect, target, timeline.current_participant())
	var condition := DeckitTagCondition.new()
	condition.tag = "allowed"
	action.conditions.append(condition)
	_log("Conditional charge: %s" % game.perform(action))
	_refresh()


func _next_phase() -> void:
	_log("Next phase: %s (blocked while window is open)." % timeline.next_phase())
	_refresh()


func _cancel() -> void:
	window.cancel()
	staged.clear()
	_log("Unresolved proposals cancelled; earlier results are retained.")
	_refresh()


func _order() -> void:
	if window.pending_count() > 0:
		_log("Resolve or cancel proposals before changing the order.")
	else:
		window.resolution_order = DeckitPriorityWindow.ResolutionOrder.FIFO if window.resolution_order == DeckitPriorityWindow.ResolutionOrder.LIFO else DeckitPriorityWindow.ResolutionOrder.LIFO
	_refresh()


func _log(message: String) -> void:
	history.text = (history.text + "\n" + message).right(1100)


func _refresh() -> void:
	var target := chosen.first()
	for view in views:
		view.refresh()
		var ids: Array[StringName] = []
		if target != null and target.zone_id == view.zone_id:
			ids.append(target.instance_id)
		view.set_selected_cards(ids)
	stage_button.disabled = not window.is_open or window.ready_to_resolve or target == null or target.zone_id != &"hand" or _is_staged(target.instance_id)
	pass_button.disabled = not window.is_open or window.ready_to_resolve
	resolve_button.disabled = not window.ready_to_resolve or window.pending_count() == 0
	effect_button.disabled = target == null or target.resolve(game) == null
	var order := "LIFO" if window.resolution_order == DeckitPriorityWindow.ResolutionOrder.LIFO else "FIFO"
	status.text = "Turn: %s · Phase: %s · Priority: %s · Passes: %d/2 · %s · Pending reactions: %d" % [timeline.current_participant(), timeline.current_phase(), window.current_participant(), window.consecutive_passes, order, queue.pending_count()]
	hint.text = "Next: open a window and select a hand card." if not window.is_open else ("Next: resolve one proposal." if window.ready_to_resolve else "Next: stage a different card, or pass priority with both players.")
	for child in stack_row.get_children():
		stack_row.remove_child(child)
		child.queue_free()
	var ordered := staged.duplicate()
	if window.resolution_order == DeckitPriorityWindow.ResolutionOrder.LIFO:
		ordered.reverse()
	for action in ordered:
		var card := hand.find_by_id(action.card_instance_id)
		if card != null:
			var image := DeckitLabCardArt.card_button(stack_row, card, true)
			image.disabled = true
	if ordered.is_empty():
		DeckitLabUI.info(stack_row, "No proposals. Select a card and stage it.")
