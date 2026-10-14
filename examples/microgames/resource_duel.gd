## Original micro-duel. Costs, combat and AI belong to THIS example only.
class_name DeckitDemoResourceDuel extends RefCounted

var game := DeckitGameState.new()
var turns := DeckitTurnManager.new()
var ledger := DeckitValueLedger.new()
var queue := DeckitEventQueue.new()
var finished: bool = false
var victory: bool = false
var last_message: String = ""


func setup() -> bool:
	game = DeckitGameState.new()
	turns = DeckitTurnManager.new()
	ledger = DeckitValueLedger.new()
	queue = DeckitEventQueue.new()
	finished = false
	victory = false
	last_message = "Gain energy with Forge. Strike costs 2. Ward costs 1. Defeat the rival before turn 5."

	var catalog := DeckitCardCatalog.new()
	var deck := DeckitDeckList.new()
	var specs: Array[Dictionary] = [
		{"id": "forge", "count": 2, "cost": 0, "kind": "gain"},
		{"id": "ward", "count": 2, "cost": 1, "kind": "shield"},
		{"id": "strike", "count": 3, "cost": 2, "kind": "attack"}
	]
	for spec: Dictionary in specs:
		var definition := DeckitCardDefinition.new()
		definition.card_id = StringName(spec["id"])
		definition.display_name = String(spec["id"]).capitalize()
		definition.attributes = {"cost": spec["cost"], "kind": spec["kind"]}
		if not catalog.add_card(definition) or not deck.add(definition.card_id, int(spec["count"])):
			return false
	var factory := DeckitDeckFactory.new()
	var copies: Array[DeckitCardInstance] = factory.build(deck, catalog, &"main", &"pilot", "duel")
	if copies.size() != 7:
		return false
	for id: StringName in [&"draw", &"hand", &"play", &"discard"]:
		game.register_zone(DeckitCardZone.new(id))
	var draw: DeckitCardZone = game.get_zone(&"draw")
	for card: DeckitCardInstance in copies:
		draw.add_card(card)
	# Fixed opening of all three abilities, leaving further Strikes to draw.
	for kind: StringName in [&"strike", &"forge", &"ward"]:
		var found: DeckitCardInstance = null
		for card: DeckitCardInstance in draw.cards:
			if card.definition.card_id == kind:
				found = card
				break
		if found == null or not game.perform(DeckitCardAction.new(&"draw", &"hand", found.instance_id)):
			return false
	if not queue.bind(game):
		return false
	if not turns.configure([&"pilot"], [&"action", &"cleanup"]) or not turns.start():
		return false
	return ledger.set_value(&"pilot", &"energy", 1) and ledger.set_value(&"pilot", &"health", 8) and ledger.set_value(&"rival", &"health", 6)


func hand_cards() -> Array[DeckitCardInstance]:
	return game.get_zone(&"hand").cards.duplicate()


func play(card_id: StringName) -> bool:
	if finished or not turns.is_running or turns.current_phase() != &"action":
		return false
	var hand: DeckitCardZone = game.get_zone(&"hand")
	var card: DeckitCardInstance = hand.find_by_id(card_id)
	if card == null:
		return false
	var cost: int = int(card.get_attribute(&"cost", 0))
	if not ledger.can_pay(&"pilot", {&"energy": cost}):
		last_message = "Not enough energy for %s (cost %d)." % [card.definition.display_name, cost]
		return false
	if not game.perform(DeckitCardAction.new(&"hand", &"play", card_id, &"pilot")):
		return false
	# The host owns this policy: payment follows an accepted action.
	ledger.pay(&"pilot", {&"energy": cost})
	var kind: String = String(card.get_attribute(&"kind", ""))
	match kind:
		"gain":
			ledger.grant(&"pilot", {&"energy": 2})
		"shield":
			ledger.grant(&"pilot", {&"shield": 2})
		"attack":
			ledger.add_value(&"rival", &"health", -3)
	# An ordinary DeckitEffectAction keeps runtime visual state observable.
	var counter := DeckitCounterEffect.new()
	counter.counter_key = &"resolved"
	game.perform(DeckitEffectAction.new().configure(counter, DeckitCardTarget.new(&"play", card_id), &"pilot"))
	game.perform(DeckitCardAction.new(&"play", &"discard", card_id, &"pilot"))
	queue.drain()
	last_message = "%s resolved. Rival health: %d." % [card.definition.display_name, ledger.get_value(&"rival", &"health")]
	if ledger.get_value(&"rival", &"health") <= 0:
		finished = true
		victory = true
		last_message = "Victory! Rival defeated."
		turns.stop()
	return true


func end_turn() -> bool:
	if finished or not turns.is_running:
		return false
	turns.next_phase()
	var shield: int = ledger.get_value(&"pilot", &"shield")
	var damage: int = maxi(0, 2 - shield)
	ledger.set_value(&"pilot", &"shield", maxi(0, shield - 2))
	ledger.add_value(&"pilot", &"health", -damage)
	if ledger.get_value(&"pilot", &"health") <= 0 or turns.turn_number >= 4:
		finished = true
		victory = false
		last_message = "Defeat. The rival holds the arena."
		turns.stop()
		return true
	ledger.grant(&"pilot", {&"energy": 1})
	turns.end_turn()
	var hand: DeckitCardZone = game.get_zone(&"hand")
	var destinations: Array[StringName] = [&"hand"]
	DeckitDealer.deal_round_robin(game, &"draw", destinations, maxi(0, 3 - hand.size()))
	queue.drain()
	last_message = "Next turn. Rival dealt %d damage." % damage
	return true
