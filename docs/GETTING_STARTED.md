# Getting started with Deckit

Deckit targets **Godot 4.7.x** and uses GDScript. You can use individual modules without installing a complete game framework.

## 1. Install the add-on

Copy `addons/deckit/` to the root of your own Godot project:

```text
my-game/
├── project.godot
└── addons/
    └── deckit/
        ├── plugin.cfg
        ├── plugin.gd
        ├── assets/
        └── src/
```

Open your project in Godot so it can scan the `class_name` scripts and import the icons. Go to **Project → Project Settings → Plugins** and enable **Deckit** for the classic custom editor nodes (drag, card, hand, pile and deck controls).

The new data-model classes do not require the example project or an autoload.

## 2. Create and move a card

In a Node script, try:

```gdscript
extends Node

func _ready() -> void:
    var definition := DeckitCardDefinition.new()
    definition.card_id = &"demo-card"
    definition.display_name = "Demo Card"

    var card := DeckitCardInstance.new(definition, &"demo-copy-1")
    var draw := DeckitCardZone.new(&"draw")
    var hand := DeckitCardZone.new(&"hand")

    var game := DeckitGameState.new()
    game.register_zone(draw)
    game.register_zone(hand)
    draw.add_card(card)

    var action := DeckitCardAction.new(&"draw", &"hand", card.instance_id)
    if game.perform(action):
        print("Card in hand: ", hand.size())
```

Definitions are shared data; instances are individual runtime copies. Use unique instance IDs in a match. Use `game.perform()` for moves that should respect registered rules; directly changing zones bypasses those rules.

## 3. Build a deck

Create a `DeckitCardCatalog` and populate it with `DeckitCardDefinition` resources. Create a `DeckitDeckList` with card IDs and quantities; a `DeckitDeckRules` resource optionally limits cards, copies, sections and tags.

```gdscript
var catalog := DeckitCardCatalog.new()
var definition := DeckitCardDefinition.new()
definition.card_id = &"unit-a"
definition.display_name = "Unit A"
catalog.add_card(definition)

var recipe := DeckitDeckList.new()
recipe.add(&"unit-a", 3, &"main")

var limits := DeckitDeckRules.new()
limits.default_copy_limit = 3
assert(DeckitDeckValidator.is_valid(recipe, catalog, limits))

var factory := DeckitDeckFactory.new()
var copies := factory.build(recipe, catalog, &"main", &"player-1", "player1", limits)
```

The factory creates runtime instances; it does not automatically create zones or start a game. Reuse a factory or use distinct prefixes to avoid ID collisions across factories.

### Optional visual deck editor

Add a `DeckitDeckBuilderUI` node from the registered script or instantiate it in code, then call `setup(catalog, recipe, limits)` **after adding the node to the scene tree**:

```gdscript
var builder := DeckitDeckBuilderUI.new()
add_child(builder)
builder.setup(catalog, recipe, limits)
```

Search by card ID/name/tag, select entries, adjust quantities and sections, and validate the recipe. Save/load uses JSON under `user://deckit-deck.json` unless you set `save_path`. You can also save catalog/deck resources as `.tres` in the Godot editor. JSON contains IDs and counts, **not** artwork or running game state.

### Classic playing-card visuals

The original `DeckitPlayingCard`, `DeckitPlayingCardUI`, `DeckitCardHand`, `DeckitCardPile` and `DeckitDeck` work with scene-tree nodes. They are **distinct** from `DeckitCardDefinition`, `DeckitCardZone` and `DeckitDeckList`. Assign classic `DeckitPlayingCard` resources and textures as appropriate; see the **Legacy Visual Components** lab.

The optional `DeckitDeckCreator` and `DeckitDeckPreloader` support suit-folder asset workflows. French and Spanish directory templates are included but contain **no licensed card artwork**.

## 4. Try the examples

Run `res://examples/labs/lab_hub.tscn` **in the Deckit repository project** to explore 9 feature labs and 3 original small games. Examples are not installed when you copy only `addons/deckit/` into your game. Full listing: [Examples](EXAMPLES.md).

## Where to go next

Use the [API reference](REFERENCE.md) to add your own rules, effects, turn manager and priority windows. For import or editor errors, see [Testing and troubleshooting](TESTING.md).


## Learn common integrations

Press F5 in this repository to open three focused labs. Start with the tabletop
for draw/discard, selecting, dragging between zones and free placement. Continue
with rules/responses and the deck workshop. Follow the [seven mini-tutorials](RECIPES.md)
for small code examples you can adapt to your own game.
