@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type(
		"DeckitDraggable2D",
		"Button",
		preload("src/components/utils/draggable_2d.gd"), 
		preload("assets/draggable_2d.svg")
	)
	
	add_custom_type(
		"DeckitPlayingCardUI", 
		"Control",
		preload("src/components/ui/playing_card_ui.gd"),
		preload("assets/playing_card.svg")
	)
	
	add_custom_type(
		"DeckitCardHand", 
		"Control",
		preload("src/components/ui/card_hand.gd"),
		preload("assets/card_hand.svg")
	)
	
	add_custom_type(
		"DeckitCardPile", 
		"Control",
		preload("src/components/ui/card_pile.gd"),
		preload("assets/card_pile.svg")
	)
	
	add_custom_type(
		"DeckitDeck", 
		"Control",
		preload("src/components/ui/deck.gd"),
		preload("assets/deck.svg")
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
