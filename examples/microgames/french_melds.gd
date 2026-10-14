## Three-round French deck pattern challenge, using the generic Deckit core.
class_name DeckitDemoFrenchMelds extends RefCounted

const SUITS: Array[String] = ["clubs", "diamonds", "hearts", "spades"]

var game := DeckitGameState.new()
var ledger := DeckitValueLedger.new()
var attempts: int = 0
var finished: bool = false
var last_message: String = ""


func setup(seed_value: int = 219) -> bool:
	game = DeckitGameState.new()
	ledger = DeckitValueLedger.new()
	attempts = 0
	finished = false
	last_message = "Choose 3 cards: same suit in a run (+5), or three of a kind (+4)."
	var catalog := DeckitCardCatalog.new()
	var deck := DeckitDeckList.new()
	for suit: String in SUITS:
		for rank in range(1, 14):
			var definition := DeckitCardDefinition.new()
			definition.card_id = StringName("%s-%d" % [suit, rank])
			definition.display_name = "%s %d" % [suit.capitalize(), rank]
			definition.attributes = {"suit": suit, "rank": rank}
			if not catalog.add_card(definition) or not deck.add(definition.card_id):
				return false
	var factory := DeckitDeckFactory.new()
	var copies: Array[DeckitCardInstance] = factory.build(deck, catalog, &"main", &"solo", "french")
	if copies.size() != 52:
		return false
	for id: StringName in [&"draw", &"hand", &"discard"]:
		game.register_zone(DeckitCardZone.new(id))
	var draw: DeckitCardZone = game.get_zone(&"draw")
	for card: DeckitCardInstance in copies:
		draw.add_card(card)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	draw.shuffle_with_rng(rng)
	# Starter combination guarantees one discoverable valid run.
	for definition_id: StringName in [&"hearts-4", &"hearts-5", &"hearts-6"]:
		var card: DeckitCardInstance = null
		for candidate: DeckitCardInstance in draw.cards:
			if candidate.definition.card_id == definition_id:
				card = candidate
				break
		if card == null or not game.perform(DeckitCardAction.new(&"draw", &"hand", card.instance_id)):
			return false
	var destinations: Array[StringName] = [&"hand"]
	return DeckitDealer.deal_round_robin(game, &"draw", destinations, 2) == 2


func get_hand() -> Array[DeckitCardInstance]:
	return game.get_zone(&"hand").cards.duplicate()


## Malformed selections never advance a round. Valid selections consume the
## chosen cards even if they score 0, just like the local challenge rules.
func submit(ids: Array[StringName]) -> bool:
	if finished or ids.size() != 3:
		return false
	var chosen: Array[DeckitCardInstance] = []
	var seen: Dictionary = {}
	var hand: DeckitCardZone = game.get_zone(&"hand")
	for id: StringName in ids:
		if id == &"" or seen.has(id):
			return false
		var card: DeckitCardInstance = hand.find_by_id(id)
		if card == null:
			return false
		seen[id] = true
		chosen.append(card)
	var points: int = 0
	if DeckitCardPatterns.all_share(chosen, &"suit") and DeckitCardPatterns.is_run(chosen):
		points = 5
	else:
		var counts: Dictionary = DeckitCardPatterns.attribute_counts(chosen, &"rank")
		if counts.size() == 1:
			points = 4
	for card: DeckitCardInstance in chosen:
		if not game.perform(DeckitCardAction.new(&"hand", &"discard", card.instance_id)):
			return false
	ledger.add_value(&"solo", &"score", points)
	attempts += 1
	last_message = "Round %d: %d points. Total: %d." % [attempts, points, ledger.get_value(&"solo", &"score")]
	if attempts >= 3:
		finished = true
		last_message += " Challenge completed."
	else:
		var destinations: Array[StringName] = [&"hand"]
		DeckitDealer.deal_round_robin(game, &"draw", destinations, 3)
	return true
