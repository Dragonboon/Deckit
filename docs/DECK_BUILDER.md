# Modular deck builder

Deckit separates **card definitions**, **editable deck recipes**, **rules**, and **runtime card instances**. No game-specific deck archetype or format is built in.

- `DeckitCardCatalog`: searchable card definitions with unique IDs.
- `DeckitDeckList` and `DeckitDeckEntry`: editable counts per card and named section; Resources save as `.tres` in Godot.
- `DeckitDeckRules`: minimum/maximum size, generic copy limit, forbidden cards, allowed/forbidden tags, section restrictions and custom checks.
- `DeckitDeckValidator`: returns actionable `DeckitDeckIssue` errors without modifying the recipe. Individual `card.deck_limit` is also checked (the tighter positive cap wins).
- `DeckitDeckCodec`: validated JSON format v1, containing deck metadata and card IDs/counts/sections, **not image data or runtime state**.
- `DeckitDeckBuilderUI`: optional reusable Control for search, editing quantities, custom section names, validation, duplication, save and load. Default save: `user://deckit-deck.json`. Change `save_path` as needed.

## Quick example

```gdscript
var catalog := DeckitCardCatalog.new()
var definition := DeckitCardDefinition.new()
definition.card_id = &"sample"
definition.display_name = "Sample"
catalog.add_card(definition)

var deck := DeckitDeckList.new()
deck.add(&"sample", 3, &"main")
deck.add(&"sample", 1, &"side")

var constraints := DeckitDeckRules.new()
constraints.default_copy_limit = 4

var issues := DeckitDeckValidator.validate(deck, catalog, constraints)
assert(DeckitDeckValidator.is_valid(deck, catalog, constraints))
```

## Visual editor

Add a `DeckitDeckBuilderUI` node, or create it in code and call `setup(catalog, deck, rules)` after adding it to the scene. Search the catalog, select an entry, choose a section and press **Add**; click deck entries to remove copies. Saving writes JSON inside Godot's user-data folder; loading replaces the draft only if parsing succeeds.

The editor intentionally allows invalid *drafts* and shows validation problems rather than silently imposing one game's restrictions. Save does not imply the deck is legal. Games should call `DeckitDeckValidator.is_valid()` before playing.

For Inspector-driven editing, create `DeckitCardDefinition`, `DeckitCardCatalog`, `DeckitDeckList`, and `DeckitDeckRules` Resources directly. Use custom `DeckitDeckRule` implementations for unique formats.

**Limitations:** No automatic game-specific deck construction, online deck database, network sync, image download or import of third-party formats. JSON roundtrips portable IDs/counts, not card artwork. Consumers must provide catalog assets matching the imported IDs.

Try `res://examples/labs/deck_builder_lab.tscn`. Test with `godot --headless --path . --script res://tests/headless/test_deck_builder.gd`.
