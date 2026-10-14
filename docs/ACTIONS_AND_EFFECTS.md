# Targets, conditions, effects and sequences

Deckit supplies **optional, game-neutral building blocks**, not a TCG/LCG ruleset.

| Component | Use |
|---|---|
| `DeckitCardTarget` | Address a card by instance ID and zone ID; resolve stale references safely |
| `DeckitTargetSelection` | Select distinct existing targets with an optional maximum |
| `DeckitCardCondition` | Override `is_met()` with an eligibility check |
| `DeckitTagCondition` | Opt-in definition tag requirement |
| `DeckitCardEffect` | Extend `can_apply()/apply()` for game-specific operations |
| `DeckitCounterEffect` | Apply integer counter deltas, with zero floor |
| `DeckitFaceEffect` | Set or toggle runtime face orientation |
| `DeckitEffectAction` | Dispatch an effect through `DeckitGameState.perform()` and global rules |
| `DeckitActionSequence` | Execute bounded actions in sequence, stopping on the first rejection |

```gdscript
var target := DeckitCardTarget.new(&"table", &"instance-01")
var counter := DeckitCounterEffect.new()
counter.counter_key = &"charge"
counter.delta = 1
var action := DeckitEffectAction.new().configure(counter, target, &"player-1")
var tag_requirement := DeckitTagCondition.new()
tag_requirement.tag = "eligible"
action.conditions.append(tag_requirement)
var applied: bool = game_state.perform(action)
```

Effects only mutate the runtime card instance. Visual presenters need `refresh()` on **direct** host edits; effects dispatched through `perform()` emit `action_applied` for bound zone views.

## Important limits

- Conditions are optional, composable predicates. No turn ownership, payment, timing window or combat rule is implicit.
- An effect must return `false` without changing state when it cannot run.
- Sequences **are not atomic**. Successful previous steps remain if a later step fails; `failed_step` is zero-based.
- The current effect interface is synchronous. For animation, multiplayer command processing, transactionality or undo, use an orchestrator owned by the game.
- Target selection checks existence, not authorization. Use `DeckitCardRule` for server-authoritative permission checks.
- Concealed cards must be filtered from data sent to other network peers; rendering a back does not hide the underlying model from code.

Try `res://examples/labs/actions_lab.tscn` and run:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_actions.gd
```
