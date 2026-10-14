## Attribute-based comparison for Spanish/French decks and custom card games.
## The rank order is listed strongest first, e.g. [1, 3, 12, ...].
## Equal ranks tie; unlisted ranks are weaker than ranked values.
class_name DeckitCardRanking extends RefCounted


static func suit_of(card: DeckitCardInstance, key: StringName = &"suit") -> String:
	if card == null:
		return ""
	return String(card.get_attribute(key, ""))


static func rank_of(card: DeckitCardInstance, key: StringName = &"rank") -> int:
	if card == null:
		return 0
	return int(card.get_attribute(key, 0))


## Positive means candidate wins; negative means incumbent wins, zero tie.
## A lead suit must be supplied if different nontrump suits are compared.
static func compare(
	candidate: DeckitCardInstance,
	incumbent: DeckitCardInstance,
	lead_suit: String = "",
	trump_suit: String = "",
	rank_order: PackedInt32Array = PackedInt32Array(),
	suit_key: StringName = &"suit",
	rank_key: StringName = &"rank"
) -> int:
	if candidate == null or incumbent == null:
		return 0
	var suit_a: String = suit_of(candidate, suit_key)
	var suit_b: String = suit_of(incumbent, suit_key)
	if suit_a != suit_b:
		if not trump_suit.is_empty():
			if suit_a == trump_suit:
				return 1
			if suit_b == trump_suit:
				return -1
		if suit_a == lead_suit and suit_b != lead_suit:
			return 1
		if suit_b == lead_suit and suit_a != lead_suit:
			return -1
		return 0
	var rank_a: int = rank_of(candidate, rank_key)
	var rank_b: int = rank_of(incumbent, rank_key)
	if rank_a == rank_b:
		return 0
	if not rank_order.is_empty():
		var pos_a: int = rank_order.find(rank_a)
		var pos_b: int = rank_order.find(rank_b)
		if pos_a < 0 and pos_b < 0:
			return 0
		if pos_a < 0:
			return -1
		if pos_b < 0:
			return 1
		return 1 if pos_a < pos_b else -1
	return 1 if rank_a > rank_b else -1


## Winner index of a trick: the first eligible card establishes the lead.
## Ties stay with the earlier played card. Game chooses rank/trump policy.
static func trick_winner(
	cards: Array[DeckitCardInstance],
	trump_suit: String = "",
	rank_order: PackedInt32Array = PackedInt32Array(),
	suit_key: StringName = &"suit",
	rank_key: StringName = &"rank"
) -> int:
	if cards.is_empty() or cards[0] == null:
		return -1
	var lead: String = suit_of(cards[0], suit_key)
	var winner: int = 0
	for i in range(1, cards.size()):
		if cards[i] != null and compare(cards[i], cards[winner], lead, trump_suit, rank_order, suit_key, rank_key) > 0:
			winner = i
	return winner
