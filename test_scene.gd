extends Control


@onready var card_pile: CardPile = $CardPile
@onready var card_hand: CardHand = $CardHand

@onready var deckit_playing_card_ui: DeckitPlayingCardUI = $DeckitPlayingCardUI
@onready var deckit_playing_card_ui_2: DeckitPlayingCardUI = $DeckitPlayingCardUI2
@onready var deckit_playing_card_ui_3: DeckitPlayingCardUI = $DeckitPlayingCardUI3
@onready var deckit_playing_card_ui_4: DeckitPlayingCardUI = $DeckitPlayingCardUI4


@onready var cards = [
	deckit_playing_card_ui,
	deckit_playing_card_ui_2,
	deckit_playing_card_ui_3,
	deckit_playing_card_ui_4
]

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		var card = cards.pop_front()
		
		if card:
			card_hand.add_card(card)
	
	if Input.is_action_just_pressed("ui_cancel"):
		var card := card_hand.remove_random_card()
		
		if card:
			card.position = Vector2(100, 70)
			cards.append(card)
