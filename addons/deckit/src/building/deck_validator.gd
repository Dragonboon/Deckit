## Validates a recipe against an independent catalog and optional policies.
## Never mutates the deck, catalog, or rule resources.
class_name DeckitDeckValidator extends RefCounted


static func validate(
	deck: DeckitDeckList,
	catalog: DeckitCardCatalog,
	rules: DeckitDeckRules = null
) -> Array[DeckitDeckIssue]:
	var issues: Array[DeckitDeckIssue] = []
	if deck == null or catalog == null:
		issues.append(DeckitDeckIssue.new(&"missing_input", "Deck and catalog are required."))
		return issues
	for message in catalog.invalid_ids():
		issues.append(DeckitDeckIssue.new(&"invalid_catalog", message))

	# Build a local index once. Large catalogs should not be scanned for
	# every deck entry or for each combined copy-limit check.
	# The first definition wins, matching CardCatalog.find_card().
	var definitions: Dictionary = {}
	for candidate: DeckitCardDefinition in catalog.cards:
		if candidate != null and candidate.card_id != &"" and not definitions.has(candidate.card_id):
			definitions[candidate.card_id] = candidate

	var seen_entries: Dictionary = {}
	var count_by_id: Dictionary = {}
	for entry in deck.entries:
		if entry == null or entry.card_id == &"" or entry.section_id == &"":
			issues.append(DeckitDeckIssue.new(&"invalid_entry", "Each entry requires a card and section ID."))
			continue
		var unique_key: String = "%s\u001f%s" % [entry.section_id, entry.card_id]
		if seen_entries.has(unique_key):
			issues.append(DeckitDeckIssue.new(&"duplicate_entry", "Duplicate card entry in section.", entry.card_id, entry.section_id))
		seen_entries[unique_key] = true
		if entry.quantity < 1 or entry.quantity > 9999:
			issues.append(DeckitDeckIssue.new(&"invalid_quantity", "Quantity must be between 1 and 9999.", entry.card_id, entry.section_id))
			continue
		count_by_id[entry.card_id] = int(count_by_id.get(entry.card_id, 0)) + entry.quantity
		var definition: DeckitCardDefinition = definitions.get(entry.card_id, null)
		if definition == null:
			issues.append(DeckitDeckIssue.new(&"unknown_card", "Card ID is missing from the catalog.", entry.card_id, entry.section_id))
			continue
		if rules != null:
			if rules.forbidden_ids.has(String(entry.card_id)):
				issues.append(DeckitDeckIssue.new(&"forbidden_card", "This card is forbidden.", entry.card_id, entry.section_id))
			for label in rules.forbidden_tags:
				if definition.has_tag(label):
					issues.append(DeckitDeckIssue.new(&"forbidden_tag", "Card carries a forbidden tag: %s" % label, entry.card_id, entry.section_id))
			if not rules.allowed_tags.is_empty():
				var accepted: bool = false
				for label in rules.allowed_tags:
					if definition.has_tag(label):
						accepted = true
						break
				if not accepted:
					issues.append(DeckitDeckIssue.new(&"disallowed_tag", "Card has none of the allowed tags.", entry.card_id, entry.section_id))

	for id in count_by_id:
		var definition: DeckitCardDefinition = definitions.get(id, null)
		var effective_limit: int = 0
		if rules != null and rules.default_copy_limit > 0:
			effective_limit = rules.default_copy_limit
		if definition != null and definition.deck_limit > 0:
			effective_limit = mini(effective_limit, definition.deck_limit) if effective_limit > 0 else definition.deck_limit
		if effective_limit > 0 and int(count_by_id[id]) > effective_limit:
			issues.append(DeckitDeckIssue.new(&"copy_limit", "Maximum %d copies across all sections." % effective_limit, id))
	if rules == null:
		return issues

	var total: int = deck.total_cards()
	if rules.minimum_cards > 0 and total < rules.minimum_cards:
		issues.append(DeckitDeckIssue.new(&"minimum_size", "Deck needs at least %d cards." % rules.minimum_cards))
	if rules.maximum_cards > 0 and total > rules.maximum_cards:
		issues.append(DeckitDeckIssue.new(&"maximum_size", "Deck permits at most %d cards." % rules.maximum_cards))
	var seen_sections: Dictionary = {}
	for section_rule in rules.sections:
		if section_rule == null or section_rule.section_id == &"":
			issues.append(DeckitDeckIssue.new(&"invalid_section_rule", "Section rule has no ID."))
			continue
		if seen_sections.has(section_rule.section_id):
			issues.append(DeckitDeckIssue.new(&"duplicate_section_rule", "Duplicate section constraint.", &"", section_rule.section_id))
		seen_sections[section_rule.section_id] = true
		var section_count: int = deck.total_cards(section_rule.section_id)
		if section_rule.minimum > 0 and section_count < section_rule.minimum:
			issues.append(DeckitDeckIssue.new(&"section_minimum", "Section needs at least %d cards." % section_rule.minimum, &"", section_rule.section_id))
		if section_rule.maximum > 0 and section_count > section_rule.maximum:
			issues.append(DeckitDeckIssue.new(&"section_maximum", "Section permits at most %d cards." % section_rule.maximum, &"", section_rule.section_id))
	for custom_rule in rules.custom_rules:
		if custom_rule == null:
			issues.append(DeckitDeckIssue.new(&"invalid_custom_rule", "A custom rule is null."))
		else:
			issues.append_array(custom_rule.validate(deck, catalog))
	return issues


static func is_valid(
	deck: DeckitDeckList,
	catalog: DeckitCardCatalog,
	rules: DeckitDeckRules = null
) -> bool:
	for issue in validate(deck, catalog, rules):
		if issue == null or issue.severity == DeckitDeckIssue.Severity.ERROR:
			return false
	return true
