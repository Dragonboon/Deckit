## Optional round-robin deal via GameState's normal action/rule gateway.
## Partial success is intentionally nontransactional if a rule denies a move.
class_name DeckitDealer extends RefCounted


## Returns number of successfully moved cards; no direct zone mutation.
## The final string is the actor ID used by game-owned rules (optional).
static func deal_round_robin(
	game: DeckitGameState,
	source_id: StringName,
	destinations: Array[StringName],
	cards_per_destination: int,
	actor_id: StringName = &""
) -> int:
	if game == null or destinations.is_empty() or cards_per_destination < 1:
		return 0
	var source: DeckitCardZone = game.get_zone(source_id)
	if source == null:
		return 0
	for id: StringName in destinations:
		if id == &"" or id == source_id or game.get_zone(id) == null:
			return 0
	var moved: int = 0
	for round_index in range(cards_per_destination):
		for id: StringName in destinations:
			var top: DeckitCardInstance = source.peek_top()
			if top == null:
				return moved
			var action := DeckitCardAction.new(source_id, id, top.instance_id, actor_id)
			if not game.perform(action):
				return moved
			moved += 1
	return moved
