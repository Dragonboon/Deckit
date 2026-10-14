## Ordered, UI-independent collection of runtime card instances.
## The last card is the top of the zone; capacity 0 means unlimited.
class_name DeckitCardZone extends RefCounted

enum Visibility { PUBLIC, OWNER_ONLY, HIDDEN }

var zone_id: StringName = &""
var owner_id: StringName = &""
## Visibility describes the game intent; the host must filter hidden data.
var visibility: Visibility = Visibility.PUBLIC
var capacity: int = 0
var cards: Array[DeckitCardInstance] = []


func _init(id: StringName = &"", player_id: StringName = &"") -> void:
	zone_id = id
	owner_id = player_id


func size() -> int:
	return cards.size()


func is_empty() -> bool:
	return cards.is_empty()


func contains(card: DeckitCardInstance) -> bool:
	return card != null and cards.has(card)


func find_by_id(id: StringName) -> DeckitCardInstance:
	if id == &"":
		return null
	for card in cards:
		if card != null and card.instance_id == id:
			return card
	return null


func can_accept(card: DeckitCardInstance) -> bool:
	return card != null and card.definition != null and card.instance_id != &"" \
		and (capacity <= 0 or cards.size() < capacity) and find_by_id(card.instance_id) == null


func add_card(card: DeckitCardInstance) -> bool:
	if not can_accept(card):
		return false
	cards.append(card)
	return true


func remove_card(card: DeckitCardInstance) -> bool:
	if not contains(card):
		return false
	cards.erase(card)
	return true


func peek_top() -> DeckitCardInstance:
	return null if cards.is_empty() else cards.back()


func take_top() -> DeckitCardInstance:
	return null if cards.is_empty() else cards.pop_back()


func move_card_to(destination: DeckitCardZone, card: DeckitCardInstance) -> bool:
	if destination == null or destination == self or not contains(card):
		return false
	if not destination.can_accept(card):
		return false
	if not remove_card(card):
		return false
	if destination.add_card(card):
		return true
	# Restore on unexpected failure; ordinary rejected moves never mutate.
	cards.append(card)
	return false


## Fisher-Yates shuffle using a caller-owned RNG (seed it for replay).
func shuffle_with_rng(rng: RandomNumberGenerator) -> void:
	if rng == null:
		return
	for i in range(cards.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var previous: DeckitCardInstance = cards[i]
		cards[i] = cards[j]
		cards[j] = previous
