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


## Resolution safeguards (new)

The resolver assigns monotonically increasing `event_id`, a `chain_id` and a causal `depth` when an event is accepted. A responder-generated action emits an event in the same chain at depth +1.

- `max_chain_depth` (default 8): reject deeper notifications.
- `max_similar_events_per_chain` (default 3): reject identical event signatures within a chain. Set 0 to disable this heuristic for legitimate repeated responses.
- `get_trace()`: a bounded copy of diagnostic entries containing event/chain IDs, depth, status, reason and action counts. `max_trace_entries` defaults to 128.
- `cancel_event(event_id)` / `cancel_chain(chain_id)` / `clear_pending()`: cancel only unresolved notifications; never undo applied state.
- `rejection_policy`: `CONTINUE`, `STOP_EVENT` or `STOP_DRAIN`. Previously successful actions stay committed.
- `request_stop()`: politely stop after the currently active event completes.

Event signatures consist of the event type, actor, card instance and source/destination zone. This is a **best-effort guard**, not semantic equivalence of all custom payloads. Limits are per queue/chain and never enforce game turns or target legality.

### Display sizing

The example project now opens at **960×600** without the earlier 2× viewport-to-window enlargement. Laboratory padding, headings and sample-board dimensions have been reduced. These preferences are scoped to the repository's example project, not to consumer games installing `addons/deckit/`.
