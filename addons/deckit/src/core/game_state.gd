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


func perform(action: DeckitCardAction) -> bool:
	if action == null:
		return false
	if not action.can_apply(self):
		action_rejected.emit(action)
		return false
	for rule in rules:
		if rule != null and not rule.allows(action, self):
			action_rejected.emit(action)
			return false
	if not action.apply(self):
		action_rejected.emit(action)
		return false
	action_applied.emit(action)
	return true
