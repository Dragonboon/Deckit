## Optional synchronous reaction. Subclass to create arbitrary action requests.
## The responder never executes an action itself; the queue runs them via
## DeckitGameState.perform(), preserving registered DeckitCardRule checks.
@tool
class_name DeckitEventResponder extends Resource

@export var event_type: StringName = &"action.applied"
@export var priority: int = 0
@export var enabled: bool = true


func matches(event: DeckitGameEvent, _game: DeckitGameState) -> bool:
	return enabled and event != null and event.event_type == event_type


## Called at resolution time. Return actions WITHOUT mutating game state.
## Listener ordering: higher priority first, registration order breaks ties.
func make_actions(_event: DeckitGameEvent, _game: DeckitGameState) -> Array[DeckitCardAction]:
	return []
