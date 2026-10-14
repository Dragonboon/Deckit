extends SceneTree

const RESPONDER = preload("res://tests/headless/sample_event_responder.gd")
var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error("[Deckit events] " + label)


func _run() -> void:
	var game := DeckitGameState.new()
	var hand := DeckitCardZone.new(&"hand")
	var table := DeckitCardZone.new(&"table")
	game.register_zone(hand)
	game.register_zone(table)
	var definition := DeckitCardDefinition.new()
	var card := DeckitCardInstance.new(definition, &"one")
	_check(hand.add_card(card), "Prepare card")
	var queue := DeckitEventQueue.new()
	var listener = RESPONDER.new()
	listener.event_type = DeckitGameEvent.ACTION_APPLIED
	listener.respond = true
	_check(queue.bind(game), "Bind state")
	_check(queue.register_responder(listener), "Register")
	_check(not queue.register_responder(listener), "Reject repeated responder")
	_check(game.perform(DeckitCardAction.new(&"hand", &"table", &"one")), "Move through game")
	_check(queue.pending_count() == 1 and card.get_counter(&"bonus") == 0, "Deferred resolution")
	_check(queue.drain() == 2 and card.get_counter(&"bonus") == 1, "Response applied then notification consumed")
	_check(queue.pending_count() == 0, "Queue emptied")
	_check(not queue.resolve_next(), "Empty queue")
	listener.respond = false
	_check(queue.publish(DeckitGameEvent.new(&"other", 2)), "Custom low-priority event")
	_check(queue.publish(DeckitGameEvent.new(DeckitGameEvent.ACTION_APPLIED, 10)), "Custom high-priority event")
	_check(queue.publish(DeckitGameEvent.new(DeckitGameEvent.ACTION_APPLIED, 10)), "Equal-priority event")
	_check(queue.resolve_next(), "Resolve first high priority")
	_check(listener.seen.size() == 1, "Unrelated priority events do not match transfer-specific responder")
	_check(queue.pending_count() == 2, "Remaining queue")
	_check(queue.drain(1) == 1 and queue.pending_count() == 1, "Drain budget")
	_check(queue.drain() == 1, "Remaining event")
	queue.max_pending_events = 1
	_check(queue.publish(DeckitGameEvent.new(&"one")), "Bounded publish")
	_check(not queue.publish(DeckitGameEvent.new(&"overflow")), "Bounded rejection")
	queue.clear_pending()
	queue.unbind()
	_check(not queue.resolve_next(), "Unbound queue cannot resolve")
	print("[Deckit events] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
