# Deckit examples

Open the Deckit repository in **Godot 4.7.x**, then run:

```text
res://examples/labs/lab_hub.tscn
```

The nine feature labs and three original microgames are **optional**. Most card-oriented scenarios now display reusable front/back SVG placeholders and respond to card clicks. The placeholder artwork lives under `examples/assets/`, not the installable plugin. Only `addons/deckit/` is needed in your own game.

## Nine interactive feature labs

| Lab | Scene inside `examples/labs/` | What to try |
| --- | --- | --- |
| 01 · Zone Flow | `zone_flow_lab.tscn` | Draw, transfer, discard, recycle, shuffle, flip and counters |
| 02 · Rule Gates | `rule_gate_lab.tscn` | Allow/deny moves by optional tags, actors and capacity |
| 03 · Classic Visuals | `legacy_ui_lab.tscn` | Classic hand layouts, card flipping and piles |
| 04 · State and Presentation | `presenter_lab.tscn` | Bind views to zones, reveal only permitted faces |
| 05 · Targets and Effects | `actions_lab.tscn` | Target cards, conditions, counters, face effects and action sequences |
| 06 · Event Queue | `events_lab.tscn` | Publish, order, resolve and cancel events |
| 07 · Turns and Phases | `turns_lab.tscn` | Configure participants, advance phases, pause and resume |
| 08 · Priority Windows | `priority_lab.tscn` | Stage actions, pass, resolve and prevent turn advances |
| 09 · Deck Builder | `deck_builder_lab.tscn` | Search card catalogs, add/remove copies, validate and save JSON |

## Three playable microgames

| Game | Scene inside `examples/microgames/` | Demonstrates |
| --- | --- | --- |
| Spanish Tricks | `spanish_tricks.tscn` | 40 Spanish cards; two-player follow-suit and trump, three tricks |
| French Melds | `french_melds.tscn` | 52 French cards; find runs and sets, gain points |
| Resource Duel | `resource_duel.tscn` | Custom cards, energy, costs, shield, damage and turns |

These are original **integration examples**, not full recreations of Brisca, Tute, Rummy, Poker or any licensed TCG/LCG. The scenario policies live under `examples/`; installing Deckit does not impose them on a consuming game.

## Testing the examples

The labs are intended for graphical, interactive use. The microgame regression test runs headlessly:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_microgames.gd
```

See [Testing and troubleshooting](TESTING.md) for the complete local test suite.

## Stacks, reactions, customization

- **Response stack:** `DeckitPriorityWindow` stages proposals, collects passes, then resolves one action at a time in selectable **LIFO/FIFO** order. The Priority lab displays staged cards in their expected resolution order; a full commercial-style TCG stack and automatic priority timing are **not** implicit.
- **Reactions to movement:** binding `DeckitEventQueue` to `DeckitGameState` publishes `action.applied`/`action.rejected`. A `DeckitEventResponder` can check movement source/destination, return new actions, and queue those outcomes. The Events lab displays emitted and resolved notifications with a representative card.
- **Customization:** card definitions support any tags and attributes; games register `DeckitCardRule`, `DeckitCardCondition`, `DeckitCardEffect`, `DeckitDeckRule`, event responders, and optional turn/priority policies. Demo-specific policies remain outside `addons/deckit/`.

The sample artwork illustrates presentation, not network secrecy: never transmit concealed card definitions to unauthorized clients.
