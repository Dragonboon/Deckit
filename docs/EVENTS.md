# Events and optional resolution queue

Deckit's event system is a game-neutral, **opt-in**, synchronous notification and reaction layer. It does not introduce turns, combat phases, interrupts, priority windows, or any rules specific to collectible/living card games.

- `DeckitGameEvent` is a notification snapshot with event type, priority, action identifiers and optional payload.
- `DeckitEventResponder` is an extensible Resource that matches event types and *proposes* actions.
- `DeckitEventQueue` stores events, sorts higher priority first (FIFO for ties) and executes proposed actions through `DeckitGameState.perform()`.

## Usage

```gdscript
var queue := DeckitEventQueue.new()
queue.bind(game_state)
queue.register_responder(my_optional_responder)
game_state.perform(my_action) # records action.applied or action.rejected
queue.drain()                 # explicit resolution, not automatic
```

A responder subclasses `DeckitEventResponder` and overrides `matches()` or `make_actions()`. It must **not directly mutate** game state. The returned actions are checked by the existing game rules.

## Safety and ordering

- Event priority is descending; equal priorities preserve publication order.
- Responder priority is descending; equal priorities preserve registration order.
- Calling `drain()` or `resolve_next()` while resolving returns immediately without reentry.
- `max_pending_events`, `max_events_per_drain` and `max_actions_per_event` bound queue growth and execution work. Overflow and truncated responses emit signals.
- A responder may generate actions which themselves publish further events. **The queue does not automatically suppress recursive reaction chains**; budget limits and the host's policies must bound them. Only call `drain()` at controlled resolution points.
- Applied effects and actions are **not rolled back** if later responses fail. The event system is not a transaction, replay log, persistence format or network transport.
- Notifications snapshot action identifiers, not complete historical card state. The host must maintain any required authoritative action log and filter hidden information before sending it to other players.

Try `res://examples/labs/events_lab.tscn` and run `godot --headless --path . --script res://tests/headless/test_events.gd`.
