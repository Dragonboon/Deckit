# Optional priority and response windows

`DeckitPriorityWindow` is a **game-neutral**, synchronous action-opportunity coordinator. Unlike the turn manager, its priority holder may be different from the current turn participant. No particular TCG timing, interrupts, stack semantics, action costs or network authority is imposed.

```gdscript
var window := DeckitPriorityWindow.new()
window.open(game_state, [&"alice", &"bob"], &"alice")
window.submit_action(&"alice", DeckitCardAction.new(&"hand", &"table", &"card-1", &"alice"))
window.pass_priority(&"bob")
window.pass_priority(&"alice")
window.resolve_next() # only now game_state.perform() is called
```

## Contract

- `open(game, participants, first, id)` validates nonempty, unique participant IDs and selects an initial priority holder.
- `open_from_turn(game, timeline, id)` optionally copies participants and current player from the active, unpaused turn manager.
- `submit_action(actor, action)` requires the current priority holder and a matching `action.actor_id`; it **stages**, not executes, an action.
- `pass_priority(actor)` records one pass. When everyone passes and actions are pending, `ready_to_resolve` becomes true.
- `resolve_next()` executes **one** staged action via `DeckitGameState.perform()`, respecting all registered game rules; after resolution the priority returns to the starting player, and another round of passes/answers is possible.
- `resolution_order` is `LIFO` by default (last staged resolves first), or `FIFO` by choice.
- If everyone passes with an empty queue, `auto_close_when_empty = true` closes the window.
- `close()` refuses to throw away staged work; `cancel()` explicitly abandons unresolved proposals. Already executed actions are never rolled back.
- `max_pending_actions` bounds staged actions. No unbounded automatic resolution loop runs.

## Optional integrations

`DeckitPriorityTurnGate` is a `DeckitTurnTransitionRule` which, when registered on a turn manager, prevents phase/turn progression while the window is open.

`DeckitPriorityEventBridge` publishes `priority.window_opened`, `priority.changed`, `priority.passed`, `priority.action_staged`, `priority.resolution_ready`, `priority.action_resolved`, `priority.action_cancelled`, and `priority.window_closed` notifications. Its queue must be bound to a game state for `drain()`.

These integrations are not automatic. Games requiring ownership, timeouts, interruption legality, simultaneous actions, animations, or authoritative multiplayer must supply those policies.

Run `res://examples/labs/priority_lab.tscn` or `godot --headless --path . --script res://tests/headless/test_priority.gd`.
