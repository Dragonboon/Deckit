class_name DeckitDeckPreloader

#region Decks
## EXAMPLE 
## const FrenchPixelPlayingCards: StringName = &"pixel_playing_cards"
#endregion

class DeckRecord:
	var type: DeckitDeck.DeckType
	var cards_path: String
	
	var backs: Array[DeckitPlayingCard] = []
	var jokers: Array[DeckitPlayingCard] = []
	var clubs: Array[DeckitPlayingCard] = []
	var hearts: Array[DeckitPlayingCard] = []
	var diamonds: Array[DeckitPlayingCard] = []
	var spades: Array[DeckitPlayingCard] = []
	var golds: Array[DeckitPlayingCard] = []
	var cups: Array[DeckitPlayingCard] = []
	var swords: Array[DeckitPlayingCard] = []
	
	func _init(path: String, deck_type: DeckitDeck.DeckType) -> void:
		cards_path = path
		type = deck_type
		
		## Common suits for all decks
		for back: DeckitPlayingCard in DeckitUtils.get_resource_files(path.path_join("backs")):
			backs.append(back)
			
		for joker: DeckitPlayingCard in DeckitUtils.get_resource_files(path.path_join("jokers")):
			jokers.append(joker)

		for club: DeckitPlayingCard in DeckitUtils.get_resource_files(path.path_join("clubs")):
			clubs.append(club)
			
		if is_french():
			for diamond: DeckitPlayingCard in DeckitUtils.get_resource_files(path.path_join("diamonds")):
				diamonds.append(diamond)
				
			for heart: DeckitPlayingCard in DeckitUtils.get_resource_files(path.path_join("hearts")):
				hearts.append(heart)
				
			for spade: DeckitPlayingCard in DeckitUtils.get_resource_files(path.path_join("spades")):
				spades.append(spade)
		
		elif is_spanish():
			for cup: DeckitPlayingCard in DeckitUtils.get_resource_files(path.path_join("cups")):
				cups.append(cup)
				
			for gold: DeckitPlayingCard in DeckitUtils.get_resource_files(path.path_join("golds")):
				golds.append(gold)
				
			for sword: DeckitPlayingCard in DeckitUtils.get_resource_files(path.path_join("swords")):
				swords.append(sword)

	
	func is_spanish() -> bool:
		return type == DeckitDeck.DeckType.Spanish
		

	func is_french() -> bool:
		return type == DeckitDeck.DeckType.French
		

static var available_decks: Dictionary[StringName, DeckRecord] = {
	## EXAMPLE
	## FrenchPixelDeckitPlayingCards: DeckRecord.new("res://scenes/cards/decks/french/pixel_playing_cards/", DeckitDeck.DeckType.French)
}
