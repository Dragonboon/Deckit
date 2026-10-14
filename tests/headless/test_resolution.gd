extends SceneTree

const RESPONDER = preload("res://tests/headless/sample_event_responder.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(result: bool, label: String) -> void:
	if result:
		passed += 1
	else:
		failed += 1
		push_error("[Deckit resolution] " + label)

func _run() -> void:
	var game := DeckitGameState.new()
	var hand := DeckitCardZone.new(&"hand")
	var table := DeckitCardZone.new(&"table")
	game.register_zone(hand)
	game.register_zone(table)
	var definition := DeckitCardDefinition.new()
	var card := DeckitCardInstance.new(definition, &"card-1")
	_check(hand.add_card(card), "Seed")
	var queue := DeckitEventQueue.new()
	var responder = RESPONDER.new()
	responder.respond = true
	queue.bind(game)
	queue.register_responder(responder)
	_check(game.perform(DeckitCardAction.new(&"hand", &"table", &"card-1")), "Move")
	_check(queue.drain() == 2 and card.get_counter(&"bonus") == 1, "One response no uncontrolled chain")
	_check(queue.get_trace().size() >= 4, "Trace accepted and processed")
	var trace := queue.get_trace()
	trace.clear()
	_check(queue.get_trace().size() > 0, "Defensive trace copy")
	var first := DeckitGameEvent.new(&"custom", 1)
	var second := DeckitGameEvent.new(&"custom", 0)
	_check(queue.publish(first) and queue.publish(second), "Publish")
	_check(first.chain_id != second.chain_id and first.event_id != second.event_id, "Unique chains and event ids")
	_check(not queue.publish(first), "No event object reuse")
	_check(queue.cancel_event(first.event_id), "Cancel one")
	_check(queue.cancel_chain(second.chain_id) == 1 and queue.pending_count() == 0, "Cancel chain")
	queue.max_similar_events_per_chain = 1
	var custom := DeckitGameEvent.new(&"single")
	_check(queue.publish(custom), "First signature")
	_check(not queue.publish(custom), "No event reuse after acceptance")
	_check(queue.resolve_next(), "Resolve accepted event")
	queue.max_trace_entries = 3
	queue.clear_trace()
	for i in range(5):
		queue.publish(DeckitGameEvent.new(&"log"))
		queue.resolve_next()
	_check(queue.get_trace().size() <= 3, "Bounded trace")
	_check(queue.pending_count() == 0, "All resolved")
	print("[Deckit resolution] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
