## A minimal orchestration boundary for card zones and gameplay actions.
## Deckit owns no turn sequence, combat rules, network transport or UI.
class_name DeckitGameState extends RefCounted

signal action_applied(action: DeckitCardAction)
signal action_rejected(action: DeckitCardAction)

var zones: Dictionary[StringName, DeckitCardZone] = {}
var rules: Array[DeckitCardRule] = []


func register_zone(zone: DeckitCardZone) -> bool:
	if zone == null or zone.zone_id == &"" or zones.has(zone.zone_id):
		return false
	zones[zone.zone_id] = zone
	return true


func get_zone(id: StringName) -> DeckitCardZone:
	return zones.get(id, null)


func register_rule(rule: DeckitCardRule) -> bool:
	if rule == null or rules.has(rule):
		return false
	rules.append(rule)
	return true


## Rules/conditions must be side-effect free: UI may query this during a drag.
func can_perform(action: DeckitCardAction) -> bool:
	if action == null or not action.can_apply(self):
		return false
	for rule in rules:
		if rule != null and not rule.allows(action, self):
			return false
	return true


func perform(action: DeckitCardAction) -> bool:
	if action == null:
		return false
	if not can_perform(action) or not action.apply(self):
		action_rejected.emit(action)
		return false
	action_applied.emit(action)
	return true

## Non-mutating runtime check for mismatched zones or duplicate instance IDs.
## Call after materializing a deck and before persisting or starting a match.
## Public zones may be changed directly; this reports violations but does not
## substitute for authoritative game rules or automatic ID allocation.
func inspect_integrity() -> PackedStringArray:
	var problems := PackedStringArray()
	var seen_ids: Dictionary = {}
	for key in zones:
		var zone: DeckitCardZone = zones[key]
		if zone == null:
			problems.append("Null zone registered under %s" % key)
			continue
		if zone.zone_id != key:
			problems.append("Zone registry key and zone_id differ for %s" % key)
		if zone.capacity > 0 and zone.cards.size() > zone.capacity:
			problems.append("Zone %s exceeds capacity" % key)
		for card in zone.cards:
			if card == null or card.definition == null or card.instance_id == &"":
				problems.append("Zone %s contains an invalid card instance" % key)
				continue
			if seen_ids.has(card.instance_id):
				problems.append("Duplicate instance ID %s in zones %s and %s" % [
					card.instance_id, seen_ids[card.instance_id], key
				])
			else:
				seen_ids[card.instance_id] = key
	return problems
