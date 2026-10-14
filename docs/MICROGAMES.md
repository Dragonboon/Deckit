# Three playable integration examples

These are **original, intentionally small** games in `examples/microgames/`, not prepackaged Deckit rules. They demonstrate how a consumer can compose the reusable plugin APIs without making the addon specific to any one genre.

| Scene | Mechanics exercised | Local game rules |
| --- | --- | --- |
| `spanish_tricks.tscn` | Spanish 40-card catalog, deterministic deal, turns, trump comparator, validated moves, score ledger | Two players, follow suit if able, three tricks, fixed trump `oros` |
| `french_melds.tscn` | French 52-card catalog, selection, run/set checks, discard, draw, score | Three submissions of three cards; same-suit run scores 5, three equal ranks score 4 |
| `resource_duel.tscn` | Runtime factory, multi-track ledger, costs, action validation, counter effect, turn phases, event queue | Original solo arena with Forge (+energy), Strike (damage), Ward (shield), rival retaliation and win/lose |

Open the repository in Godot 4.7, run `res://examples/labs/lab_hub.tscn`, and use the three playable examples at the bottom.

These examples are *integration laboratories*, not finished production games. They use list-based UI, no third-party art and no networking. The Spanish sample is a three-trick original exercise, **not** full Brisca/Tute rules. The French sample is a small pattern game, **not** full Rummy/Poker. The duel is a generic cost/effect exercise, **not** a commercial TCG/LCG implementation.

## Headless regression

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_microgames.gd
```

The test checks representative complete scenario flows, scoring, phase changes, rejection, effects and instance-ID integrity. Interactive Godot execution remains necessary for graphical validation.

The reusable addon is still installed by copying **only** `addons/deckit/`. All scenario-specific rules are outside it.
