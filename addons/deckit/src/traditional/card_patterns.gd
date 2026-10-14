## Generic rank/suit predicates, not hardcoded poker or rummy rules.
class_name DeckitCardPatterns extends RefCounted


static func attribute_counts(cards: Array[DeckitCardInstance], key: StringName) -> Dictionary:
	var counts: Dictionary = {}
	for card: DeckitCardInstance in cards:
		if card == null or card.definition == null:
			continue
		var value: Variant = card.get_attribute(key, null)
		if value == null:
			continue
		counts[value] = int(counts.get(value, 0)) + 1
	return counts


static func all_share(cards: Array[DeckitCardInstance], key: StringName) -> bool:
	if cards.is_empty():
		return false
	var first: Variant = null
	for index in range(cards.size()):
		var card: DeckitCardInstance = cards[index]
		if card == null or card.definition == null:
			return false
		var value: Variant = card.get_attribute(key, null)
		if value == null:
			return false
		if index == 0:
			first = value
		elif value != first:
			return false
	return true


## Consecutive ranks in a caller-supplied LOWEST-TO-HIGHEST ordering.
## Empty order uses ordinary integer adjacency. No wraparound/Ace exception.
static func is_run(
	cards: Array[DeckitCardInstance],
	rank_order: PackedInt32Array = PackedInt32Array(),
	rank_key: StringName = &"rank"
) -> bool:
	if cards.is_empty():
		return false
	var ranks: Array[int] = []
	for card: DeckitCardInstance in cards:
		if card == null or card.definition == null:
			return false
		var value: Variant = card.get_attribute(rank_key, null)
		if not (value is int):
			return false
		var rank: int = int(value)
		var position: int = rank_order.find(rank) if not rank_order.is_empty() else rank
		if position < 0 or ranks.has(position):
			return false
		ranks.append(position)
	ranks.sort()
	for i in range(1, ranks.size()):
		if ranks[i] != ranks[i - 1] + 1:
			return false
	return true
