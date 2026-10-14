# Optional turn and phase coordinator

The `DeckitTurnManager` in `addons/deckit/src/turns/` models an ordered cycle of **participants**, **phase identifiers**, and **rounds**. It works independently from card zones, gameplay rules, UI, and the event queue.

```gdscript
var timeline := DeckitTurnManager.new()
timeline.configure(
    [&"player-a", &"player-b"],
    [&"setup", &"action", &"cleanup"]
)
timeline.start()
timeline.next_phase()
timeline.end_turn()
```

- `configure()` requires nonempty, unique IDs and works only while stopped.
- `start(first_participant)` starts turn 1 / round 1. The first participant can be selected explicitly.
- `next_phase()` advances one phase, crossing from the last phase to the next participant's first phase.
- `end_turn()` skips remaining phases to begin the next participant's turn.
- `pause()` and `resume()` suspend advancement, not event delivery or game actions.
- `stop()` resets counters while preserving configuration and rules.
- `add_rule()` accepts an optional `DeckitTurnTransitionRule` override for the **proposed destination**. Rejection leaves the current position untouched.

Signals provide `turn_started`, `turn_ended`, `phase_started`, `phase_ended`, `transition_denied`, and lifecycle notifications.

## Opt-in event integration

`DeckitTurnEventBridge` publishes `turn.started`, `turn.ended`, `phase.started`, and `phase.ended` notifications through the existing `DeckitEventQueue`. It does not call `drain()`, automatically advance the timeline, enforce actor permissions, or intercept card actions.

```gdscript
var queue := DeckitEventQueue.new()
queue.bind(game_state)
var bridge := DeckitTurnEventBridge.new()
bridge.bind(timeline, queue)
timeline.start()
queue.drain()
```

A game can implement phase-specific costs, legal actions and active-player checks by registering its own `DeckitCardRule` on the game state. That policy is not built into Deckit.

**Important:** starting at a non-first participant still counts as round 1. A new round begins when the cycle crosses from the last participant to the first. Signals are synchronous and the manager rejects reentrant transition calls. Neither the manager nor its event bridge implements rollback, timer-driven turns, automatic queues, interrupts, or networking.

Run `res://examples/labs/turns_lab.tscn` or `godot --headless --path . --script res://tests/headless/test_turns.gd`.
