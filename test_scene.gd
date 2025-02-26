extends Control


@onready var card_pile: CardPile = $CardPile



func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		var removed_card: DeckitPlayingCardUI = card_pile.remove_random_card()
		
		if removed_card:
			removed_card.queue_free()
