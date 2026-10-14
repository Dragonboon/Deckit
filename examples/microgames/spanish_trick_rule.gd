## Example-only rule. Never add this to addons/deckit/.
class_name DeckitDemoTrickRule extends DeckitCardRule

var session


func allows(action: DeckitCardAction, game: DeckitGameState) -> bool:
	if action.destination_zone_id != &"trick":
		return true
	if session == null or session.finished or action.actor_id != session.turns.current_participant():
		return false
	var required_source: StringName = session.hand_id(action.actor_id)
	if action.source_zone_id != required_source:
		return false
	var hand: DeckitCardZone = game.get_zone(required_source)
	var card: DeckitCardInstance = hand.find_by_id(action.card_instance_id)
	if card == null:
		return false
	var lead: String = session.lead_suit()
	if lead.is_empty() or DeckitCardRanking.suit_of(card) == lead:
		return true
	for candidate: DeckitCardInstance in hand.cards:
		if DeckitCardRanking.suit_of(candidate) == lead:
			return false
	return true
