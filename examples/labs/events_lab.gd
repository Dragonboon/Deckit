## Isolated demonstration. No rules specific to a game enter addons/deckit.
extends Control

const SAMPLE_RESPONDER = preload("res://examples/labs/sample_event_responder.gd")

var game := DeckitGameState.new()
var queue := DeckitEventQueue.new()
var source := DeckitCardZone.new(&"hand")
var destination := DeckitCardZone.new(&"table")
var status: Label
var history: Label


func _ready() -> void:
	var page := DeckitLabUI.page(
		self, "06 • Event Queue",
		"Move a card, inspect the queued notification and explicitly resolve a generic response. Events do not execute themselves."
	)
	var controls := DeckitLabUI.controls(page)
	DeckitLabUI.button(controls, "Move to table", _move)
	DeckitLabUI.button(controls, "Resolve next", _resolve_next)
	DeckitLabUI.button(controls, "Drain queue", _drain)
	DeckitLabUI.button(controls, "Publish high-priority custom event", _publish_custom)
	DeckitLabUI.button(controls, "Cancel pending", _cancel_pending)
	DeckitLabUI.button(controls, "Stop on rejection", _toggle_policy)
	DeckitLabUI.button(controls, "Reset", _reset)
	status = DeckitLabUI.info(page, "")
	history = DeckitLabUI.info(page, "")
	queue.event_queued.connect(_on_queued)
	queue.event_processed.connect(_on_processed)
	queue.event_dropped.connect(func(event: DeckitGameEvent) -> void:
		_log("DROPPED %s" % event.event_type)
	)
	queue.register_responder(SAMPLE_RESPONDER.new())
	queue.bind(game)
	_reset()


func _reset() -> void:
	queue.clear_pending()
	queue.clear_trace()
	queue.rejection_policy = DeckitEventQueue.RejectionPolicy.CONTINUE
	game.zones.clear()
	source.cards.clear()
	destination.cards.clear()
	game.register_zone(source)
	game.register_zone(destination)
	var definition := DeckitCardDefinition.new()
	definition.card_id = &"generic"
	definition.display_name = "Generic card"
	source.add_card(DeckitCardInstance.new(definition, &"unique-1"))
	history.text = "Resolution log:"
	_update()


func _move() -> void:
	var card := source.peek_top()
	if card == null:
		_log("No cards left in hand. Reset to repeat.")
		return
	var success := game.perform(DeckitCardAction.new(&"hand", &"table", card.instance_id, &"demo"))
	_log("Move %s" % ("accepted" if success else "rejected"))
	_update()


func _resolve_next() -> void:
	_log("Resolved next: %s" % queue.resolve_next())
	_update()


func _drain() -> void:
	_log("Drained %d events" % queue.drain())
	_update()


func _cancel_pending() -> void:
	var before := queue.pending_count()
	queue.clear_pending()
	_log("Cancelled %d pending events" % before)
	_update()

func _toggle_policy() -> void:
	queue.rejection_policy = DeckitEventQueue.RejectionPolicy.STOP_DRAIN if queue.rejection_policy == DeckitEventQueue.RejectionPolicy.CONTINUE else DeckitEventQueue.RejectionPolicy.CONTINUE
	_log("Policy: %s" % ("stop drain" if queue.rejection_policy == DeckitEventQueue.RejectionPolicy.STOP_DRAIN else "continue"))

func _publish_custom() -> void:
	queue.publish(DeckitGameEvent.new(&"example.notification", 100, {"context": "lab"}))
	_update()


func _on_queued(event: DeckitGameEvent) -> void:
	_log("QUEUED %s (priority %d)" % [event.event_type, event.priority])
	_update()


func _on_processed(event: DeckitGameEvent, applied: int, rejected: int) -> void:
	_log("PROCESSED %s: %d applied, %d rejected" % [event.event_type, applied, rejected])
	_update()


func _log(message: String) -> void:
	if history == null:
		return
	history.text += "\n" + message
	if history.text.length() > 2400:
		history.text = "Resolution log:\n" + history.text.right(1800)


func _update() -> void:
	if status == null:
		return
	var card := destination.peek_top()
	status.text = "Hand: %d | Table: %d | Pending: %d | Arrival counters: %d" % [
		source.size(), destination.size(), queue.pending_count(),
		card.get_counter(&"arrival") if card != null else 0
	]
