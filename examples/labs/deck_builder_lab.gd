## Catalog → validated recipe → independent runtime copies.
extends Control

var catalog := DeckitCardCatalog.new()
var rules := DeckitDeckRules.new()
var factory := DeckitDeckFactory.new()
var game := DeckitGameState.new()
var editor: DeckitDeckBuilderUI
var preview: DeckitZoneView
var status: Label


func _ready() -> void:
	var page := DeckitLabUI.page(self, "03 · Deck workshop / Taller de mazos",
		"Start with a valid four-card recipe. Add too many copies of Card 01, inspect the validation error, then fix it and build a runtime preview.")
	for i in range(12):
		var definition := DeckitCardDefinition.new()
		definition.card_id = StringName("sample-%02d" % (i + 1))
		definition.display_name = "Card %02d" % (i + 1)
		definition.tags = PackedStringArray(["type-%d" % (i % 3)])
		definition.deck_limit = 2 if i == 0 else 0
		DeckitLabCardArt.decorate(definition)
		catalog.add_card(definition)
	rules.minimum_cards = 4
	rules.maximum_cards = 20
	rules.default_copy_limit = 4
	var controls := DeckitLabUI.controls(page)
	DeckitLabUI.button(controls, "Build runtime preview", _build)
	DeckitLabUI.button(controls, "Reset recipe", _reset)
	editor = DeckitDeckBuilderUI.new()
	editor.save_path = "user://deckit-lab-deck.json"
	page.add_child(editor)
	status = DeckitLabUI.info(page, "")
	game.register_zone(DeckitCardZone.new(&"preview"))
	preview = DeckitLabCardArt.zone_panel(page, game, &"preview", &"demo", 6)
	DeckitLabUI.info(page, "JSON saves a deck recipe, not a match. Build creates unique copies only after validation. Preview shows up to six cards. Integration: docs/RECIPES.md (#7).")
	_reset()


func _reset() -> void:
	var recipe := DeckitDeckList.new()
	recipe.deck_name = "Four-card starter"
	for i in range(4):
		recipe.add(StringName("sample-%02d" % (i + 1)))
	editor.setup(catalog, recipe, rules)
	game.get_zone(&"preview").cards.clear()
	preview.refresh()
	status.text = "Ready: 4 cards. First definition has a copy limit of 2; all others default to 4."


func _build() -> void:
	var cards := factory.build(editor.deck, catalog, &"", &"demo", "workshop", rules)
	if not factory.last_errors.is_empty():
		status.text = "Not built: " + "; ".join(factory.last_errors)
		return
	var zone := game.get_zone(&"preview")
	zone.cards.clear()
	for card in cards:
		card.face_up = true
		zone.add_card(card)
	preview.refresh()
	status.text = "Built %d independent instances. Integrity issues: %d. Editing the recipe does not mutate this preview." % [cards.size(), game.inspect_integrity().size()]
