## Game-neutral sample catalog. Consumer apps supply their own Resources.
extends Control


func _ready() -> void:
	var page := DeckitLabUI.page(self, "09 • Build a Deck",
		"Search a catalog, choose an arbitrary section, add/remove copies, validate and save or reload a JSON deck in the user data folder.")
	var catalog := DeckitCardCatalog.new()
	for i in range(12):
		var definition := DeckitCardDefinition.new()
		definition.card_id = StringName("sample-%02d" % (i + 1))
		definition.display_name = "Sample Card %02d" % (i + 1)
		definition.tags = PackedStringArray(["type-%d" % (i % 3)])
		definition.deck_limit = 2 if i == 0 else 0
		catalog.add_card(definition)
	var recipe := DeckitDeckList.new()
	recipe.deck_name = "Example Deck"
	var rules := DeckitDeckRules.new()
	rules.minimum_cards = 4
	rules.maximum_cards = 20
	rules.default_copy_limit = 4
	var editor := DeckitDeckBuilderUI.new()
	editor.save_path = "user://deckit-lab-deck.json"
	page.add_child(editor)
	editor.setup(catalog, recipe, rules)
	DeckitLabUI.info(page, "The first card has a per-card copy limit of 2. Try adding more, and watch validation identify the excess. 'side' or any other section ID is supported.")
