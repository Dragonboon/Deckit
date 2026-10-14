extends SceneTree

var passed := 0
var failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("[Deckit actions] " + label)


func _run() -> void:
	var game := DeckitGameState.new()
	var hand := DeckitCardZone.new(&"hand")
	var table := DeckitCardZone.new(&"table")
	_check(game.register_zone(hand) and game.register_zone(table), "Zone registration")
	var definition := DeckitCardDefinition.new()
	definition.card_id = &"test"
	definition.tags = PackedStringArray(["allowed"])
	var first := DeckitCardInstance.new(definition, &"copy-1")
	var second := DeckitCardInstance.new(definition, &"copy-2")
	_check(hand.add_card(first) and hand.add_card(second), "Add instances")
	var selection := DeckitTargetSelection.new(1)
	_check(selection.select(game, &"hand", &"copy-1"), "Select valid card")
	_check(not selection.select(game, &"hand", &"copy-2"), "Selection limit")
	_check(not selection.select(game, &"hand", &"copy-1"), "Duplicate selection")
	var counter := DeckitCounterEffect.new()
	counter.counter_key = &"charge"
	counter.delta = 2
	var target := selection.first()
	var action := DeckitEffectAction.new().configure(counter, target)
	_check(game.perform(action), "Apply counter effect")
	_check(first.get_counter(&"charge") == 2 and second.get_counter(&"charge") == 0, "Target isolated")
	var tag := DeckitTagCondition.new()
	tag.tag = "allowed"
	action.conditions.append(tag)
	_check(game.perform(action) and first.get_counter(&"charge") == 4, "Permitted conditional effect")
	tag.tag = "missing"
	_check(not game.perform(action) and first.get_counter(&"charge") == 4, "Denied effect unchanged")
	var face := DeckitFaceEffect.new()
	var flip := DeckitEffectAction.new().configure(face, target)
	_check(game.perform(flip) and first.face_up, "Toggle face")
	var sequence := DeckitActionSequence.new()
	_check(sequence.add_step(DeckitCardAction.new(&"hand", &"table", &"copy-1")), "Append move")
	_check(sequence.add_step(DeckitEffectAction.new().configure(counter, DeckitCardTarget.new(&"table", &"copy-1"))), "Append counter")
	_check(sequence.execute(game) and sequence.executed_count == 2, "Sequence succeeds")
	_check(hand.size() == 1 and table.size() == 1 and first.get_counter(&"charge") == 6, "Sequence state")
	_check(target.resolve(game) == null, "Target becomes stale after move")
	var partial := DeckitActionSequence.new()
	partial.add_step(DeckitCardAction.new(&"hand", &"table", &"copy-2"))
	partial.add_step(DeckitCardAction.new(&"hand", &"table", &"copy-2"))
	_check(not partial.execute(game) and partial.executed_count == 1 and partial.failed_step == 1, "Stops on failed step")
	_check(hand.is_empty() and table.size() == 2, "Explicit non-transactional semantics")
	print("[Deckit actions] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
