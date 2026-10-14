extends DeckitEventResponder

var seen: Array[StringName] = []
var respond: bool = false


func matches(event: DeckitGameEvent, game: DeckitGameState) -> bool:
	return super.matches(event, game)


func make_actions(event: DeckitGameEvent, _game: DeckitGameState) -> Array[DeckitCardAction]:
	seen.append(event.event_type)
	if not respond:
		return []
	var effect := DeckitCounterEffect.new()
	effect.counter_key = &"bonus"
	return [DeckitEffectAction.new().configure(effect, DeckitCardTarget.new(&"table", event.card_instance_id))]
