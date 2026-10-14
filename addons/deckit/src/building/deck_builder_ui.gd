## Drop-in deck editor. Set catalog, deck and optional rules with setup().
## Works independently of turns, actions, multiplayer and any game-specific UI.
class_name DeckitDeckBuilderUI extends VBoxContainer

signal deck_changed(deck: DeckitDeckList)
signal deck_saved(path: String)
signal validation_updated(valid: bool, issues: Array[DeckitDeckIssue])

var catalog: DeckitCardCatalog
var deck: DeckitDeckList
var rules: DeckitDeckRules
## Optional save location for the demo/editor. Defaults to project user data.
var save_path: String = "user://deckit-deck.json"

var _search: LineEdit
var _section: LineEdit
var _catalog_list: ItemList
var _deck_list: ItemList
var _name: LineEdit
var _status: Label
var _issues: RichTextLabel
var _filtered: Array[DeckitCardDefinition] = []
var _entry_keys: Array[Dictionary] = []


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var headline := Label.new()
	headline.text = "Deck Builder"
	headline.add_theme_font_size_override("font_size", 21)
	add_child(headline)
	var metadata := HBoxContainer.new()
	add_child(metadata)
	_name = LineEdit.new()
	_name.placeholder_text = "Deck name"
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.text_changed.connect(_rename)
	metadata.add_child(_name)
	_section = LineEdit.new()
	_section.text = "main"
	_section.tooltip_text = "Arbitrary section name (main, side, etc.)"
	_section.custom_minimum_size.x = 100
	metadata.add_child(_section)

	_search = LineEdit.new()
	_search.placeholder_text = "Search card ID, name or tag…"
	_search.clear_button_enabled = true
	_search.tooltip_text = "Filter the card catalog by ID, name or tag."
	_search.text_changed.connect(func(_value: String) -> void: _refresh_catalog())
	add_child(_search)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 12)
	add_child(columns)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(left)
	var left_title := Label.new()
	left_title.text = "Catalog (select a card)"
	left.add_child(left_title)
	_catalog_list = ItemList.new()
	_catalog_list.custom_minimum_size = Vector2(220, 170)
	_catalog_list.tooltip_text = "Choose a card; press Add 1 or Add 4 to include copies."
	_catalog_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(_catalog_list)
	var catalog_actions := HFlowContainer.new()
	left.add_child(catalog_actions)
	_button(catalog_actions, "+ Add 1", _add_selected)
	_button(catalog_actions, "+ Add 4", _add_four)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(right)
	var right_title := Label.new()
	right_title.text = "Deck entries (select to edit)"
	right.add_child(right_title)
	_deck_list = ItemList.new()
	_deck_list.custom_minimum_size = Vector2(220, 170)
	_deck_list.tooltip_text = "Choose a deck entry, then remove one copy or all copies."
	right.add_child(_deck_list)
	var deck_actions := HFlowContainer.new()
	right.add_child(deck_actions)
	_button(deck_actions, "− Remove 1", _remove_selected)
	_button(deck_actions, "Remove entry", _clear_selected)

	var operations := HFlowContainer.new()
	add_child(operations)
	_button(operations, "Validate", _validate)
	_button(operations, "Save JSON", _save)
	_button(operations, "Load JSON", _load)
	_button(operations, "Duplicate", _duplicate)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.tooltip_text = "Current deck totals and save location."
	add_child(_status)
	_issues = RichTextLabel.new()
	_issues.custom_minimum_size.y = 100
	_issues.fit_content = false
	_issues.scroll_active = true
	_issues.tooltip_text = "Deck validation results. Errors must be corrected before play."
	add_child(_issues)
	refresh()


func setup(new_catalog: DeckitCardCatalog, new_deck: DeckitDeckList, new_rules: DeckitDeckRules = null) -> void:
	catalog = new_catalog
	deck = new_deck
	rules = new_rules
	refresh()


func _button(parent: Node, title: String, callback: Callable) -> void:
	var control := Button.new()
	control.text = title
	control.custom_minimum_size.y = 34
	control.tooltip_text = title
	control.focus_mode = Control.FOCUS_ALL
	control.pressed.connect(callback)
	parent.add_child(control)


func _rename(value: String) -> void:
	if deck == null:
		return
	deck.deck_name = value
	deck.emit_changed()
	deck_changed.emit(deck)


func _section_id() -> StringName:
	return StringName(_section.text.strip_edges())


func _selected_catalog_id() -> StringName:
	var indices := _catalog_list.get_selected_items()
	if indices.is_empty() or indices[0] >= _filtered.size():
		return &""
	return _filtered[indices[0]].card_id


func _selected_deck_entry() -> Dictionary:
	var indices := _deck_list.get_selected_items()
	if indices.is_empty() or indices[0] >= _entry_keys.size():
		return {}
	return _entry_keys[indices[0]]


func _add_selected() -> void:
	_add_quantity(1)


func _add_four() -> void:
	_add_quantity(4)


func _add_quantity(amount: int) -> void:
	if deck == null or catalog == null:
		return
	var id := _selected_catalog_id()
	if id == &"" or _section_id() == &"":
		_status.text = "Select a catalog card and enter a section name."
		return
	if not deck.add(id, amount, _section_id()):
		_status.text = "Could not add cards (invalid or quantity limit)."
		return
	deck_changed.emit(deck)
	refresh()


func _remove_selected() -> void:
	_remove_quantity(false)


func _clear_selected() -> void:
	_remove_quantity(true)


func _remove_quantity(all_copies: bool) -> void:
	if deck == null:
		return
	var chosen := _selected_deck_entry()
	if chosen.is_empty():
		return
	var amount: int = deck.count(chosen["id"], chosen["section"])
	if deck.remove(chosen["id"], amount if all_copies else 1, chosen["section"]):
		deck_changed.emit(deck)
		refresh()


func _duplicate() -> void:
	if deck == null:
		return
	deck = deck.copy_deck()
	deck.deck_name += " (copy)"
	deck_changed.emit(deck)
	refresh()


func _validate() -> void:
	if deck == null or catalog == null:
		return
	var issues := DeckitDeckValidator.validate(deck, catalog, rules)
	var valid: bool = true
	for issue in issues:
		if issue == null or issue.severity == DeckitDeckIssue.Severity.ERROR:
			valid = false
			break
	_issues.clear()
	if issues.is_empty():
		_issues.append_text("✓ No validation issues.")
	else:
		for issue in issues:
			_issues.append_text("%s [%s] %s\n" % [
				"Warning" if issue.severity == DeckitDeckIssue.Severity.WARNING else "Error",
				issue.code, issue.message
			])
	validation_updated.emit(valid, issues)


func _save() -> void:
	if deck == null:
		return
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		_status.text = "Save error: %s" % FileAccess.get_open_error()
		return
	file.store_string(DeckitDeckCodec.encode(deck))
	file.close()
	_status.text = "Saved to %s" % save_path
	deck_saved.emit(save_path)


func _load() -> void:
	if not FileAccess.file_exists(save_path):
		_status.text = "No saved deck at %s" % save_path
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		_status.text = "Load error: %s" % FileAccess.get_open_error()
		return
	var decoded := DeckitDeckCodec.decode(file.get_as_text())
	if decoded == null:
		_status.text = "Invalid or unsupported deck JSON."
		return
	deck = decoded
	deck_changed.emit(deck)
	refresh()
	_status.text = "Loaded from %s" % save_path


func refresh() -> void:
	if not is_node_ready():
		return
	_name.text = deck.deck_name if deck != null else ""
	# Preserve selections when quantities change so repeated Add/Remove works.
	var chosen_card: StringName = _selected_catalog_id()
	var chosen_entry: Dictionary = _selected_deck_entry()
	_refresh_catalog()
	_entry_keys.clear()
	_deck_list.clear()
	if deck != null:
		for entry in deck.entries:
			if entry == null:
				continue
			_entry_keys.append({"id": entry.card_id, "section": entry.section_id})
			_deck_list.add_item("%s ×%d (%s)" % [
				entry.card_id, entry.quantity, entry.section_id
			])
			if entry.card_id == chosen_entry.get("id", &"") and entry.section_id == chosen_entry.get("section", &""):
				_deck_list.select(_entry_keys.size() - 1)
	_status.text = "Cards: %d | Unique entries: %d | Save: %s" % [
		deck.total_cards() if deck != null else 0, _entry_keys.size(), save_path
	]
	_validate()


## Filtering does not recompute deck validation or rebuild the deck list.
func _refresh_catalog() -> void:
	if not is_node_ready():
		return
	var selected_id: StringName = _selected_catalog_id()
	_filtered.clear()
	_catalog_list.clear()
	if catalog == null:
		return
	_filtered = catalog.search(_search.text)
	for index in range(_filtered.size()):
		var card: DeckitCardDefinition = _filtered[index]
		_catalog_list.add_item("%s [%s]" % [card.display_name, card.card_id])
		if card.card_id == selected_id:
			_catalog_list.select(index)
