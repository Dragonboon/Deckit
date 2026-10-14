<div align="center">
  <img src="icon.svg" alt="Deckit — overlapping playing cards" width="116">

# Deckit

**Build card games, not card-game boilerplate.**

Modular tools for cards, decks and gameplay in **Godot 4.7**.

[![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
[![GDScript](https://img.shields.io/badge/GDScript-native-478CBF)](https://docs.godotengine.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-2ea44f)](LICENSE)
[![Status](https://img.shields.io/badge/Status-active%20development-efb44c)](docs/INTEGRATION_VALIDATION.md)
[![CI](https://img.shields.io/badge/Tests-local%20headless-777777)](docs/INTEGRATION_VALIDATION.md)

[Installation](#installation) · [Quick start](#quick-start) · [Features](#what-is-included) · [Examples](#try-the-examples) · [Guides](#documentation)

</div>

---

**Deckit** is a Godot add-on for making traditional card games, deck builders and original card-based games. You choose the rules. Deckit provides the reusable pieces: card data, zones, actions, deck editing, visual controls and optional systems for turns and events.

You can use **one component on its own**, or combine several. Deckit does not include commercial card data, a mandatory game mode or a built-in multiplayer server.

## Installation

1. Download or clone this repository.
2. Copy **`addons/deckit/`** into your game's project directory. Keep the folder structure intact.
3. Open the project using **Godot 4.7** and allow the editor to import the assets.
4. For the classic editor nodes (hands, piles and deck controls), enable **Deckit** under **Project → Project Settings → Plugins**.
5. Create your own card definitions and connect only the modules you need. The data and headless systems use globally registered GDScript classes; they do not require a game scene.

> **Start here:** The repository includes nine independent labs in `examples/labs/`. They are optional demonstrations, not files you need to ship with your game.

## Quick start

This example creates a card, places it in a deck and moves it to a hand. It does not require an illustration, a scene or a particular set of rules.

```gdscript
var definition := DeckitCardDefinition.new()
definition.card_id = &"sample"
definition.display_name = "Sample Card"

var copy := DeckitCardInstance.new(definition, &"copy-001")
var draw_pile := DeckitCardZone.new(&"draw")
var hand := DeckitCardZone.new(&"hand")
draw_pile.add_card(copy)

var game := DeckitGameState.new()
game.register_zone(draw_pile)
game.register_zone(hand)
assert(game.perform(DeckitCardAction.new(&"draw", &"hand", copy.instance_id)))
```

A **definition** describes a kind of card; an **instance** is one copy during play; a **zone** is a place where copies live. The game state validates actions before moving cards.

## What is included

| Module | What it helps you do | Reference |
| --- | --- | --- |
| **Cards & zones** | Define cards, track independent copies and move them between draw piles, hands and custom areas. | [Core API](docs/CORE_API.md) |
| **Presentation** | Show a card or whole zone; request actions without changing game rules in UI code. | [Presentation](docs/PRESENTATION.md) |
| **Classic visual components** | Use card hands, card piles, dragging, fan layouts and French/Spanish playing-card utilities. | [Classic components](docs/CLASSIC_COMPONENTS.md) |
| **Deck builder** | Search a catalog, edit card counts and sections, validate limits and save or load deck recipes as JSON. | [Deck builder](docs/DECK_BUILDER.md) |
| **Setup, ranking & resources** | Turn deck recipes into runtime cards, deal through validated actions, compare cards and track scores or costs. | [Common services](docs/COMMON_SERVICES.md) |
| **Actions & effects** | Select targets, validate conditions, change counters or card orientation, run action sequences. | [Actions](docs/ACTIONS_AND_EFFECTS.md) |
| **Events & resolution** | Queue notifications, register responders, set priorities and enforce configurable resolution limits. | [Events](docs/EVENTS.md) |
| **Turns & phases** | Configure participants, phases, rounds and pause/advance behavior. | [Turns](docs/TURNS_AND_PHASES.md) |
| **Priority windows** | Stage player responses, pass priority and resolve proposed actions in LIFO/FIFO order. | [Priority windows](docs/PRIORITY_WINDOWS.md) |

**Modularity:** Turn management, priority windows, event queues and presentation are *opt-in*. A classic solitaire-style game does not need a TCG-like response window. Deck building works without an active match.

## Try the examples

Open the repository itself as a Godot project and run:

**`res://examples/labs/lab_hub.tscn`**

The nine labs cover card movement, rule checks, classic visuals, data-driven views, effects, event resolution, turns, priority and deck editing. See the [lab overview](docs/EXAMPLE_LABS.md) for a feature-by-feature map.

The labs are **outside the add-on folder** so they do not get bundled when you install only `addons/deckit/`.

## Game compatibility

Deckit supplies reusable foundations for Spanish and French classic decks, original trading-card games and living-card-style games, but **does not automatically implement their gameplay rules**. See the [game compatibility matrix](docs/GAME_COMPATIBILITY.md) for a per-mechanic audit, example genres and known gaps.

## Important boundaries

Deckit supplies building blocks, **not a finished game**. In particular:

- You supply cards, images, rules, card costs, actions allowed on each turn and any victory conditions.
- The classic visual nodes and the newer headless model are **separate APIs**; there is no automatic sync between them yet.
- Card backs in the UI do **not** secure hidden information. Multiplayer games must filter hidden data on the authoritative side.
- Action sequences and event resolution are **not transactional**. They cannot roll back an earlier successful action.
- The built-in deck editor creates editable recipes; your game must validate a deck before accepting it for play.

## Documentation

[Core](docs/CORE_API.md) · [Classic components](docs/CLASSIC_COMPONENTS.md) · [Deck builder](docs/DECK_BUILDER.md) · [Actions](docs/ACTIONS_AND_EFFECTS.md) · [Presentation](docs/PRESENTATION.md) · [Events](docs/EVENTS.md) · [Turns](docs/TURNS_AND_PHASES.md) · [Priority](docs/PRIORITY_WINDOWS.md)

[Run all local tests](docs/INTEGRATION_VALIDATION.md) · [Report a problem](https://github.com/sempitern0/Deckit/issues/new/choose) · [Contribute](CONTRIBUTING.md) · [Security](SECURITY.md)

## License

Distributed under the [MIT License](LICENSE). The license retains the original 2024 copyright notice. Deckit is not affiliated with any commercial card game or publisher.
