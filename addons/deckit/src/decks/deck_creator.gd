## This tool generates the DeckitPlayingCard resource files for a new deck that follows
## the folder templates included in src/decks/french/template or src/decks/spanish/template
@tool
class_name DeckitDeckCreator extends Node


@export_tool_button("Generate deck") var generate_action = generate_deck
@export_dir() var deck_path: String = ""
@export var use_original_card_texture_size: bool = true:
	set(value):
		if value != use_original_card_texture_size:
			use_original_card_texture_size = value
			notify_property_list_changed()
@export var target_size: Vector2 = Vector2(48, 48)
@export var texture_scale: float = 1.0


var card_value_mapping: Dictionary[String, float] = {
		"ace": 1.0,
		"two": 2.0,
		"three": 3.0,
		"four": 4.0,
		"five": 5.0,
		"six": 6.0,
		"seven": 7.0,
		"eight": 8.0,
		"nine": 9.0,
		"ten": 10.0,
		"jack": 11.0,
		"knight": 11.0,
		"horse": 11.0,
		"queen": 12.0,
		"king": 13.0,
}


func generate_deck() -> void:
	create_cards_as_resources(deck_path)
	
	
func _validate_property(property: Dictionary):
	if property.name in ["target_size", "texture_scale"]:
		property.usage = PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_EDITOR if use_original_card_texture_size else PROPERTY_USAGE_EDITOR
	
	
func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		queue_free()


func create_cards_as_resources(path: String) -> void:
	if not DeckitUtils.dirpath_is_valid(path):
		push_warning("DeckCreator: The path %s is not valid, the card resources will not be created" % path)
		return
		
	var image_format_regex = RegEx.new()
	image_format_regex.compile("(?i)\\.(png|jpg|jpeg|webp|svg)$")

	var backs: Array[Texture2D] = []
	var images: Array = DeckitUtils.get_files_recursive(path, image_format_regex)
	images.sort()
	# Discover backs first; source-file iteration order is not guaranteed.
	for file: String in images:
		if file.get_base_dir().get_file().to_lower() == "backs":
			var texture: Texture2D = ResourceLoader.load(file) as Texture2D
			if texture != null:
				backs.append(texture)
	if backs.is_empty():
		push_warning("DeckCreator: No card backs found. Cards will be face-up only until a back texture is assigned.")

	for file: String in images:
		var folder: String = file.get_base_dir()
		var folder_name: String = folder.get_file().to_lower()
		var file_name: String = file.get_file().get_basename()
		var resource_name: String = file_name + ".tres"
		var texture: Texture2D = ResourceLoader.load(file) as Texture2D
		if texture == null:
			push_warning("DeckCreator: Unable to load texture: %s" % file)
			continue
		var card := DeckitPlayingCard.new()
		card.id = StringName(file_name.to_snake_case())
		card.display_name = file_name.capitalize()
		card.suit = folder_to_suit(folder_name)
		card.default_orientation = DeckitPlayingCard.Orientation.FaceDown if folder_name == "backs" else DeckitPlayingCard.Orientation.FaceUp
		if folder_name == "backs":
			card.back_texture = texture
		else:
			card.front_texture = texture
			if not backs.is_empty():
				card.back_texture = backs.front()
		if use_original_card_texture_size:
			card.texture_size = texture.get_size()
		else:
			card.texture_size = target_size * texture_scale
		if card.is_joker() or card.is_back():
			card.value = 0.0
			card.table_value = 0.0
		else:
			card.value = detect_card_value_from_filename(resource_name)
			card.table_value = card.value
		var saved: Error = ResourceSaver.save(card, "%s/%s" % [folder, resource_name])
		if saved != OK:
			push_warning("DeckCreator: Could not save %s (%s)" % [resource_name, error_string(saved)])

	EditorInterface.get_resource_filesystem().scan()


func detect_card_value_from_filename(filename: String) -> float:
	var number_regex = RegEx.new()
	number_regex.compile("\\d+")
	
	var card_number: RegExMatch = number_regex.search(filename)
	
	if card_number:
		return float(card_number.get_string())
		
	## This regular expressions detect words by any type of separators like ace-of_clubs or ace_of_diamond
	## This is a second approach when the filename does not have a number that defines the card value
	var card_name_regex:RegEx = RegEx.new()
	card_name_regex.compile("[a-zA-Z]+")
	
	for regex_match: RegExMatch in card_name_regex.search_all(filename):
		var word: String = regex_match.get_string().to_lower()
		
		if card_value_mapping.has(word):
			return card_value_mapping[word]

	return 0.0
	
	
func folder_to_suit(folder_name: String) -> DeckitPlayingCard.Suits:
	match folder_name:
		"backs":
			return DeckitPlayingCard.Suits.Back
		"jokers":
			return DeckitPlayingCard.Suits.Joker
		"hearts":
			return DeckitPlayingCard.Suits.Heart
		"diamonds":
			return DeckitPlayingCard.Suits.Diamond
		"spades":
			return DeckitPlayingCard.Suits.Spade
		"clubs": 
			return DeckitPlayingCard.Suits.Club
		"golds":
			return DeckitPlayingCard.Suits.Gold
		"swords":
			return DeckitPlayingCard.Suits.Sword
		"cups":
			return DeckitPlayingCard.Suits.Cup
		_:
			return DeckitPlayingCard.Suits.Joker


func _calculate_scale_texture_based_on_target_size(
	texture: Texture2D,
	target_texture_size: Vector2 = target_size,
	target_texture_scale: float = texture_scale) -> Vector2:
	var texture_size = texture.get_size()
	
	return Vector2(target_texture_size.x / texture_size.x, target_texture_size.y / texture_size.y) * target_texture_scale
