<div align="center">
  <img src="icon.svg" width="112" alt="Deckit logo: overlapping playing cards">

# Deckit

**Modular card-game tools for Godot 4.7**

[![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![GDScript](https://img.shields.io/badge/GDScript-native-478CBF)](https://docs.godotengine.org/)
[![MIT](https://img.shields.io/badge/License-MIT-2ea44f)](LICENSE)

[Install](#installation) · [Get started](docs/GETTING_STARTED.md) · [API reference](docs/REFERENCE.md) · [Examples](docs/EXAMPLES.md) · [Tests](docs/TESTING.md)

</div>

Deckit is a **reusable Godot plugin** for building games with cards. Start with a traditional **Spanish or French deck**, design your own rules, or use its building blocks in a **TCG, LCG or deck-building game**. It supplies cards, decks, zones, visual components and optional systems for actions, effects, turns and events.

**Your game chooses the rules.** Deckit does not contain predefined combat systems, commercial card data, a complete game format or mandatory dependencies between its modules.

## Installation

1. Download the repository (or clone it).
2. Copy **`addons/deckit/`** into the root of your Godot 4.7 project, preserving its directory structure.
3. Open the project and let Godot import the add-on.
4. Under **Project → Project Settings → Plugins**, enable **Deckit** to register its classic editor nodes.

The GDScript `class_name` components (card definitions, zones, deck building, etc.) work independently of example scenes. **Do not copy `examples/` or `tests/` into your game unless you want them.**

See [Getting started](docs/GETTING_STARTED.md) for a first playable card transfer, a deck-building example and editor instructions.

## What can I build?

| Need | Deckit provides |
| --- | --- |
| Spanish or French playing cards | Suit/rank data, classic card visuals, shuffle, deal, card comparison and pattern helpers |
| Deck construction | Searchable catalogs, per-section quantities, customizable validation and JSON import/export |
| Card-game logic | Ordered zones, unique card instances, validated transfers, optional rules and target selection |
| Effects and interaction | Counters, face changes, event queue, priority windows, state-driven views and opt-in drag/drop with free table positioning |
| Turn-based games | Optional participant, phase, round, score and resource tracking |
| TCG/LCG foundations | Composition of the above; **game-specific abilities, combat, scenarios and costs are up to you** |

Modules can be used separately. A simple card game does not need a priority stack or event resolver.

## Small example

```gdscript
var definition := DeckitCardDefinition.new()
definition.card_id = &"sample"
definition.display_name = "Sample card"

var card := DeckitCardInstance.new(definition, &"unique-001")
var draw := DeckitCardZone.new(&"draw")
var hand := DeckitCardZone.new(&"hand")
var state := DeckitGameState.new()
state.register_zone(draw)
state.register_zone(hand)
draw.add_card(card)

assert(state.perform(DeckitCardAction.new(&"draw", &"hand", card.instance_id)))
```

A **definition** describes a card type. An **instance** represents an individual copy in play. A **zone** holds ordered instances. Validated actions go through the game state.

## Explore the project

To try features without writing your own game, open **this repository** as a Godot project and run:

`res://examples/labs/lab_hub.tscn`

It includes **3 focused labs**: tabletop drag-and-drop, rules/responses, and deck construction. Press **F5** to open the hub. Three optional small games live behind an expandable section. All example policies stay outside the add-on. See the [lab guide](docs/EXAMPLES.md) and [integration mini-tutorials](docs/RECIPES.md).

## Documentation

- [Getting started](docs/GETTING_STARTED.md) — installation, first cards, deck editor and setup
- [API reference](docs/REFERENCE.md) — modules, common operations, limitations and extension points
- [Examples](docs/EXAMPLES.md) — three guided labs and optional playable references
- [Integration recipes](docs/RECIPES.md) — hands, drag/drop, hidden cards, effects, reactions, turns and deck construction
- [Testing and troubleshooting](docs/TESTING.md) — local Godot tests, installation checks and common issues

**Important:** The original visual hand/pile/deck controls and the newer headless state model are independent APIs; they are not automatically synchronized. Hidden-card UI is not network security, and action/event sequences do not provide transaction rollback. Read the [reference](docs/REFERENCE.md) before integrating either behavior.

Problems and suggestions: [open an issue](https://github.com/Dragonboon/Deckit/issues/new/choose). Security-sensitive reports: see [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE).
