@tool
extends EditorPlugin

## Custom editor icons are loaded from their SVG source at runtime.
## Do not preload imported SVG textures here: this plugin is enabled by
## project.godot and may be parsed before Godot completes the first import.
const ICON_DIRECTORY: String = "res://addons/deckit/assets/"


func _icon(name: String) -> Texture2D:
	var path: String = ICON_DIRECTORY.path_join(name + ".svg")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Deckit: Custom icon not found: %s" % path)
		return null

	var data: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	var image := Image.new()
	if image.load_svg_from_buffer(data) != OK:
		push_warning("Deckit: Cannot render editor icon: %s" % path)
		return null
	return ImageTexture.create_from_image(image)


func _enter_tree() -> void:
	add_custom_type(
		"DeckitDraggable2D",
		"Button",
		preload("src/components/utils/draggable_2d.gd"),
		_icon("draggable_2d")
	)
	add_custom_type(
		"DeckitPlayingCardUI",
		"Control",
		preload("src/components/ui/playing_card_ui.gd"),
		_icon("playing_card")
	)
	add_custom_type(
		"DeckitCardHand",
		"Control",
		preload("src/components/ui/card_hand.gd"),
		_icon("card_hand")
	)
	add_custom_type(
		"DeckitCardPile",
		"Control",
		preload("src/components/ui/card_pile.gd"),
		_icon("card_pile")
	)
	add_custom_type(
		"DeckitDeck",
		"Control",
		preload("src/components/ui/deck.gd"),
		_icon("deck")
	)
	add_custom_type(
		"DeckitDeckCreator",
		"Node",
		preload("src/decks/deck_creator.gd"),
		null
	)


func _exit_tree() -> void:
	remove_custom_type("DeckitDeckCreator")
	remove_custom_type("DeckitDeck")
	remove_custom_type("DeckitCardPile")
	remove_custom_type("DeckitCardHand")
	remove_custom_type("DeckitPlayingCardUI")
	remove_custom_type("DeckitDraggable2D")
