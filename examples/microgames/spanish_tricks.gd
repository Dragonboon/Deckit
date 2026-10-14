## Original two-player mini trick-taking match.
## This sample's follow-suit policy is separate from the Deckit plugin.
class_name DeckitDemoSpanishTricks extends RefCounted

const SUITS: Array[String] = ["oros", "copas", "espadas", "bastos"]
const RANKS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12]
const STRENGTH: PackedInt32Array = PackedInt32Array([1, 3, 12, 11, 10, 7, 6, 5, 4, 2])

var game := DeckitGameState.new()
var turns := DeckitTurnManager.new()
var ledger := DeckitValueLedger.new()
var rule := DeckitDemoTrickRule.new()
var trump_suit: String = "oros"
var tricks_played: int = 0
var finished: bool = false
var last_message: String = ""

func setup(seed_value: int = 420) -> bool:
	game = DeckitGameState.new()
	turns = DeckitTurnManager.new()
	ledger = DeckitValueLedger.new()
	rule = DeckitDemoTrickRule.new()
	rule.session = self
	tricks_played = 0
	finished = false
	trump_suit = "oros"
	last_message = "Play one card per participant. Follow the lead suit when possible."

	var catalog := DeckitCardCatalog.new()
	var deck := DeckitDeckList.new()
	for suit: String in SUITS:
		for rank: int in RANKS:
			var definition := DeckitCardDefinition.new()
			definition.card_id = StringName("%s-%d" % [suit, rank])
			definition.display_name = "%s %d" % [suit.capitalize(), rank]
			definition.attributes = {"suit": suit, "rank": rank}
			if not catalog.add_card(definition) or not deck.add(definition.card_id):
				return false
	var rules := DeckitDeckRules.new()
	rules.default_copy_limit = 1
	rules.minimum_cards = 40
	rules.maximum_cards = 40
	var factory := DeckitDeckFactory.new()
	var copies: Array[DeckitCardInstance] = factory.build(deck, catalog, &"main", &"", "spanish", rules)
	if copies.size() != 40:
		return false

	for id: StringName in [&"draw", &"p1_hand", &"p2_hand", &"trick", &"p1_won", &"p2_won"]:
		if not game.register_zone(DeckitCardZone.new(id)):
			return false
	var draw: DeckitCardZone = game.get_zone(&"draw")
	for card: DeckitCardInstance in copies:
		if not draw.add_card(card):
			return false
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	draw.shuffle_with_rng(rng)
	var destinations: Array[StringName] = [&"p1_hand", &"p2_hand"]
	if DeckitDealer.deal_round_robin(game, &"draw", destinations, 3) != 6:
		return false
	if not game.register_rule(rule):
		return false
	if not turns.configure([&"p1", &"p2"], [&"play"]):
		return false
	return turns.start()


func hand_id(player_id: StringName) -> StringName:
	if player_id == &"p1":
		return &"p1_hand"
	if player_id == &"p2":
		return &"p2_hand"
	return &""


func lead_suit() -> String:
	var trick: DeckitCardZone = game.get_zone(&"trick")
	if trick == null or trick.is_empty():
		return ""
	return DeckitCardRanking.suit_of(trick.cards[0])


func play(card_id: StringName) -> bool:
	if finished or not turns.is_running:
		return false
	var actor: StringName = turns.current_participant()
	var action := DeckitCardAction.new(hand_id(actor), &"trick", card_id, actor)
	if not game.perform(action):
		last_message = "Illegal move: select a card in the active hand and follow suit if possible."
		return false
	var trick: DeckitCardZone = game.get_zone(&"trick")
	if trick.size() == 1:
		last_message = "%s led %s. Other player must follow suit where possible." % [actor, lead_suit()]
		return turns.end_turn()

	var pair: Array[DeckitCardInstance] = trick.cards.duplicate()
	var winner_index: int = DeckitCardRanking.trick_winner(pair, trump_suit, STRENGTH)
	var winner: StringName = &"p1" if winner_index == 0 and actor == &"p2" else &"p2"
	# If the first lead was p2 instead, the second player must be p1.
	if winner_index == 0:
		winner = &"p2" if actor == &"p1" else &"p1"
	else:
		winner = actor
	var captured: StringName = &"p1_won" if winner == &"p1" else &"p2_won"
	for card: DeckitCardInstance in pair:
		if not game.perform(DeckitCardAction.new(&"trick", captured, card.instance_id, winner)):
			return false
	ledger.add_value(winner, &"tricks", 1)
	tricks_played += 1
	last_message = "%s wins trick %d; next lead: %s." % [winner, tricks_played, winner]
	turns.stop()
	if tricks_played >= 3:
		finished = true
		var left: int = ledger.get_value(&"p1", &"tricks")
		var right: int = ledger.get_value(&"p2", &"tricks")
		last_message = "Final: P1 %d – P2 %d tricks." % [left, right]
		return true
	return turns.start(winner)


func get_hand(player_id: StringName) -> Array[DeckitCardInstance]:
	var zone: DeckitCardZone = game.get_zone(hand_id(player_id))
	return zone.cards.duplicate() if zone != null else []


func result_text() -> String:
	return last_message
