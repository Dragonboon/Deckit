## A laboratory-only response: add a marker when a transfer enters "table".
extends DeckitEventResponder


func matches(event: DeckitGameEvent, game: DeckitGameState) -> bool:
	return super.matches(event, game) and event.destination_zone_id == &"table" and event.source_zone_id != &"table"


func make_actions(event: DeckitGameEvent, _game: DeckitGameState) -> Array[DeckitCardAction]:
	var effect := DeckitCounterEffect.new()
	effect.counter_key = &"arrival"
	effect.delta = 1
	var action := DeckitEffectAction.new().configure(
		effect, DeckitCardTarget.new(&"table", event.card_instance_id), event.actor_id
	)
	return [action]
