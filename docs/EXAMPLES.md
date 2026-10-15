# Three focused labs

Open the repository in **Godot 4.7.x** and press **F5**. The main scene is
`res://examples/labs/lab_hub.tscn`. Only `addons/deckit/` belongs in your own game;
all sample policies, SVGs and tutorials remain outside the plugin.

| Lab | Scene | Repeatable exercise |
|---|---|---|
| 01 · Tabletop | `examples/labs/zone_flow_lab.tscn` | Draw two cards, drag to the table, arrange freely, flip, add a marker and discard. Try a full hand or release outside a target. |
| 02 · Rules & responses | `examples/labs/priority_lab.tscn` | Stage A then B, pass with both players, resolve B and process its arrival reaction. Compare LIFO/FIFO and reject restricted card C. |
| 03 · Deck workshop | `examples/labs/deck_builder_lab.tscn` | Start from four valid cards, exceed a copy limit, fix it, save/load JSON and build independent runtime copies. |

Every lab offers a reset, visible state and instructions. The old isolated
presentation, rule, effect, event and turn scenes have been consolidated into
these workflows; the reusable plugin modules remain available independently.

## Cards and interaction

- Light **FRONT / FRENTE** versus navy **BACK / DORSO**, with an asymmetric front
  and a patterned back. Text sits in its own caption area rather than beside a shrinking icon.
- Selection has a gold outline and explicit SELECTED label. Hidden cards never
  show their title or counters in the caption or drag preview.
- Drag between zones in lab 01. Zone capacity and optional rules still apply.
  Position within the table is UI state; it does not reorder or transfer cards.
- A failed/cancelled drop leaves the original in place. A payload from another
  game, or from a card replaced during a reset, is rejected.
- Keyboard: Tab/Shift+Tab, Enter/Space and move buttons. Arrow keys reposition the
  selected table card while that card has focus.

The drag interaction is opt-in in the plugin. See [integration recipes](RECIPES.md)
for a minimal setup, hidden hands, effects, event reactions and response windows.

## Optional playable references

The hub has one expandable section for three small original games:

| Scene under `examples/microgames/` | Mechanics |
|---|---|
| `spanish_tricks.tscn` | Spanish 40-card deck, follow-suit, trump, three tricks |
| `french_melds.tscn` | French 52-card deck, three-card runs/sets and score |
| `resource_duel.tscn` | Custom cards, energy, shields, damage and turns |

They are reference integrations, not complete commercial game recreations. Their
rules are not installed with Deckit. Traditional hand/pile controls also remain
in the add-on, but are separate from the state-backed views used in the labs.

## Verify

See [Testing](TESTING.md). The new regressions exercise both direct drop contracts
and real GUI mouse events dispatched through Godot's native Control drag engine,
plus the complete guided workflows. Still check your own theme, resolution,
input devices and game policies when integrating.
