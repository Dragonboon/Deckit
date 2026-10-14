<div align="center">

<img src="icon.svg" alt="Deckit: three overlapping playing cards and a blue star" width="128">

# Deckit

**Build card games, not card-game boilerplate.**

Godot-native building blocks for traditional card games, deck builders, TCGs, LCGs and original game rules.

[![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![GDScript](https://img.shields.io/badge/GDScript-native-3E7BB6)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/)
[![MIT](https://img.shields.io/badge/License-MIT-2E8B57)](LICENSE)
![Development](https://img.shields.io/badge/Status-early%20development-D99B41)

[Quick start](#quick-start) · [Example labs](docs/EXAMPLE_LABS.md) · [Core API](docs/CORE_API.md) · [Legacy UI](#existing-ui-components) · [Contributing](CONTRIBUTING.md)

</div>

---

Deckit is a **modular toolkit**, not a game-specific rules engine. Design reusable cards and move independent instances through zones; add rules only when your game needs them.

## What you can use today

| Building block | Purpose |
| --- | --- |
| `DeckitCardDefinition` | Data-driven card templates: names, art, tags, custom values |
| `DeckitCardInstance` | Per-copy runtime state: owner, controller, face, counters |
| `DeckitCardZone` | Ordered deck, hand, discard, battlefield or custom zone |
| `DeckitCardAction` | Move a specific card between registered zones |
| `DeckitCardRule` | Extend action eligibility for your game's own rules |
| `DeckitGameState` | Execute allowed actions and observe success/failure |

The new **headless core** is separate from the legacy visual components; optional `DeckitCardView` and `DeckitZoneView` render it without enforcing game rules. Rules for turns, costs, combat and abilities remain game-owned and are **not yet implemented**.

## Quick start

1. Copy `addons/deckit/` into your Godot 4.7 project.
2. Enable **Deckit** in **Project Settings → Plugins** to use the existing editor-facing UI nodes.
3. Use the globally registered core types directly from scripts or Resources.

```gdscript
var card_data := DeckitCardDefinition.new()
card_data.card_id = &"ace_of_spades"
card_data.display_name = "Ace of Spades"

var card := DeckitCardInstance.new(card_data, &"unique-card-1")
var draw_zone := DeckitCardZone.new(&"draw")
var hand_zone := DeckitCardZone.new(&"hand")
draw_zone.add_card(card)

var game := DeckitGameState.new()
game.register_zone(draw_zone)
game.register_zone(hand_zone)
game.perform(DeckitCardAction.new(&"draw", &"hand", card.instance_id))
```

See **[Core API and rules](docs/CORE_API.md)** for practical usage, limitations, and reproducible headless tests.

## Explore eight interactive labs

Open [`examples/labs/lab_hub.tscn`](examples/labs/lab_hub.tscn) in Godot 4.7 and choose **Zone Flow**, **Rule Gates**, **Legacy Visual Components**, **State + Presentation**, **Targets & Effects**, **Event Queue**, **Turns & Phases**, or **Priority Windows**. Each demonstration is standalone and lives outside the reusable addon. See the [lab guide](docs/EXAMPLE_LABS.md) for the feature matrix and limitations.

## Optional actions and effects

The [`actions and effects`](docs/ACTIONS_AND_EFFECTS.md) layer provides target selection, conditional effects, card counters, face changes and stepwise action sequences. Sequences are **not transactional**: previous successful steps are not rolled back on a later failure.

## Optional event resolution

The [event queue](docs/EVENTS.md) supports opt-in event notifications, explicit resolution, priority-ordered responders, causal chain limits, cancellation, and bounded diagnostic traces. The queue does not introduce rules, automatic interrupts, rollback or networking.

## Optional turns and phases

The [turn manager](docs/TURNS_AND_PHASES.md) coordinates configurable participants and phases with pause/resume and transition hooks. Its event bridge is strictly opt-in and never imposes game-specific action legality or automatic progression.

## Optional priority windows

The [priority window](docs/PRIORITY_WINDOWS.md) supports multiple participants passing, staging actions and resolving them in selectable LIFO/FIFO order. Turn blocking and lifecycle event reporting are opt-in, and all executed actions still go through the game state's rules.

## Existing UI components

Deckit still includes its original `DeckitDeck`, `DeckitCardHand`, `DeckitCardPile`, `DeckitPlayingCardUI`, `DeckitPlayingCard` and `DeckitDeckCreator` components. These support traditional French/Spanish suits, drag-and-drop, card stacks and hand layouts.

They remain available while their integration and refactor proceed incrementally. **The new headless core does not automatically synchronize with these UI nodes yet.**

## Roadmap

- Bind the existing UI components to card instances and zones without hardcoded game rules.
- Expand reusable effects, deck-building validation and optional TCG/LCG integrations.
- Extend the example lab catalog, add persistence interfaces and further Godot 4.7 validation.
- Keep multiplayer transport and game policy optional, never mandatory dependencies.

## Validation

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/headless/test_core.gd
```

For full cross-module regression coverage, see [Integration validation](docs/INTEGRATION_VALIDATION.md). These are **tests to run locally**, not a claim of completed Godot runtime validation.

## Contributing and license

See [Contributing](CONTRIBUTING.md) and [Security](SECURITY.md). Released under the [MIT License](LICENSE).
