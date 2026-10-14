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
		push_error("[Deckit microgames] " + label)

func _run() -> void:
	var spanish := DeckitDemoSpanishTricks.new()
	_check(spanish.setup(420), "Spanish setup")
	var safety: int = 0
	while not spanish.finished and safety < 6:
		var player: StringName = spanish.turns.current_participant()
		var hand: Array[DeckitCardInstance] = spanish.get_hand(player)
		var candidate: DeckitCardInstance = null
		var lead: String = spanish.lead_suit()
		for card: DeckitCardInstance in hand:
			if lead.is_empty() or DeckitCardRanking.suit_of(card) == lead:
				candidate = card
				break
		if candidate == null and not hand.is_empty():
			candidate = hand[0]
		_check(candidate != null and spanish.play(candidate.instance_id), "Spanish valid play")
		safety += 1
	_check(spanish.finished and spanish.tricks_played == 3, "Spanish end state")
	_check(spanish.game.inspect_integrity().is_empty(), "Spanish unique runtime instances")
	_check(spanish.ledger.get_value(&"p1", &"tricks") + spanish.ledger.get_value(&"p2", &"tricks") == 3, "Spanish trick scores")

	var french := DeckitDemoFrenchMelds.new()
	_check(french.setup(219), "French setup")
	var run_ids: Array[StringName] = []
	for card: DeckitCardInstance in french.get_hand():
		if card.definition.card_id in [&"hearts-4", &"hearts-5", &"hearts-6"]:
			run_ids.append(card.instance_id)
	_check(run_ids.size() == 3 and french.submit(run_ids), "French valid run")
	_check(french.ledger.get_value(&"solo", &"score") == 5, "French pattern score")
	_check(not french.submit([&"bad", &"bad", &"bad"]), "French reject invalid group")
	for i in range(2):
		var cards: Array[DeckitCardInstance] = french.get_hand()
		var ids: Array[StringName] = []
		for j in range(3):
			ids.append(cards[j].instance_id)
		_check(french.submit(ids), "French additional round")
	_check(french.finished and french.attempts == 3, "French completed")
	_check(french.game.inspect_integrity().is_empty(), "French unique runtime instances")

	var duel := DeckitDemoResourceDuel.new()
	_check(duel.setup(), "Duel setup")
	var forge_id: StringName = &""
	for card: DeckitCardInstance in duel.hand_cards():
		if card.definition.card_id == &"forge":
			forge_id = card.instance_id
	_check(forge_id != &"" and duel.play(forge_id), "Duel resource generator")
	_check(duel.ledger.get_value(&"pilot", &"energy") == 3, "Duel resource gained")
	for card: DeckitCardInstance in duel.hand_cards():
		if card.definition.card_id == &"strike":
			_check(duel.play(card.instance_id), "Duel attack")
			break
	_check(duel.ledger.get_value(&"rival", &"health") == 3, "Duel damage")
	_check(duel.end_turn(), "Duel ends turn")
	_check(duel.game.inspect_integrity().is_empty(), "Duel unique runtime instances")
	print("[Deckit microgames] %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
