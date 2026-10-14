# Classic card components

Deckit also includes its original visual card tools. They are independent from the new data-driven core and remain available for existing projects and conventional playing-card games.

| Component | What it does |
| --- | --- |
| `DeckitPlayingCard` | Resource with suit, numeric value, textures and orientation (French or Spanish suits). |
| `DeckitPlayingCardUI` | Interactive Control for a card, including orientation, dragging and drop detection. |
| `DeckitCardHand` | Arranges cards horizontally or in a fan, with configurable selection and capacity. |
| `DeckitCardPile` | Places visual cards in a stack and accepts drops depending on restrictions. |
| `DeckitDeck` | Visual deck, card groups, draw/discard operations and shuffling. |
| `DeckitDeckCreator` | Editor tool for creating traditional card Resources from suit folders. |
| `DeckitDeckPreloader` | Loads traditional card resources from folders into a `DeckRecord`. |

## Quick visual check

Run **`res://examples/labs/legacy_ui_lab.tscn`** from this repository. It demonstrates layout modes and pile operations using placeholder graphics.

For your own scenes, add visual nodes from the editor with the add-on enabled, and assign a valid `DeckitPlayingCard` Resource and front/back textures. The original UI nodes require scene-tree context: unlike `DeckitCardZone`, they are not headless card containers.

## Asset-folder deck creation

`DeckitDeckCreator` expects a directory of images grouped into suit folders, such as `backs/`, `hearts/` and `spades/`. Empty folder templates for French and Spanish suits live inside `addons/deckit/src/decks/`. Populate a **copy** of a template with your own images; do not expect these placeholder folders to contain cards.

The tool creates Godot Resources (`.tres`) beside source images. Inspect your generated Resources before including them in a game.

## Migration boundary

**Classic visual components and new core components are not synonyms.** The original `DeckitPlayingCard` is not automatically a `DeckitCardDefinition`. Similarly, `DeckitDeck` is a visual Control and `DeckitDeckList` is an editable recipe. Bind them explicitly rather than assuming live synchronization.

See [Core API](CORE_API.md) and [Presentation](PRESENTATION.md) when starting a new game.
