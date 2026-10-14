# Integration validation

The tests in `tests/headless/` run without installing a CI workflow and exercise the independent Deckit modules together.

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_core.gd
godot --headless --path . --script res://tests/headless/test_actions.gd
godot --headless --path . --script res://tests/headless/test_presentation.gd
godot --headless --path . --script res://tests/headless/test_events.gd
godot --headless --path . --script res://tests/headless/test_resolution.gd
godot --headless --path . --script res://tests/headless/test_turns.gd
godot --headless --path . --script res://tests/headless/test_priority.gd
godot --headless --path . --script res://tests/headless/test_turn_signal_order.gd
godot --headless --path . --script res://tests/headless/test_integration.gd
godot --headless --path . --script res://tests/headless/test_deck_builder.gd
```

## Module boundaries

- **Core** owns zones, runtime instances, rules and validated actions. It does not inspect the turn manager.
- **Turn manager** advances a purely logical timeline. Its completion signals are emitted while the outgoing participant/phase is still current; start signals observe the incoming state. Lifecycle callbacks cannot reenter transitions.
- **Priority window** stages actions without executing them. Only explicit resolution invokes `GameState.perform()`. The optional `DeckitPriorityTurnGate` prevents turn advancement when a window remains open.
- **Event queue** observes action and lifecycle notifications only after its adapters are bound. Resolution and cancellation remain explicit.
- **Presentation** and **labs** do not control authoritative rules. The example project is optional when installing the plugin.

## Limits

No transactional rollback, timer-driven priority changes, multiplayer synchronization, automatic rule definitions, or persistence format is provided by these tests. Godot 4.7 graphical validation is still required for the interactive laboratories.

### Regression checks

`test_turn_signal_order.gd` guards callback-visible state and reentrant transitions. `test_integration.gd` covers a complete phase → priority response → validated card move → event emission → end-turn flow, including a stale action rejected without moving a card.

Because events and actions have deliberately different lifecycle semantics, tests should inspect both state and signals, not only return values.
