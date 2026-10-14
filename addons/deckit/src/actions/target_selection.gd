## Lightweight target selection with an optional maximum (0 = unlimited).
## Selection checks existence only: gameplay permissions belong to rules.
class_name DeckitTargetSelection extends RefCounted

var maximum_targets: int = 1
var targets: Array[DeckitCardTarget] = []


func _init(maximum: int = 1) -> void:
	maximum_targets = maxi(0, maximum)


func select(game: DeckitGameState, zone_id: StringName, instance_id: StringName) -> bool:
	var candidate := DeckitCardTarget.new(zone_id, instance_id)
	if candidate.resolve(game) == null:
		return false
	for existing in targets:
		if existing.zone_id == zone_id and existing.instance_id == instance_id:
			return false
	if maximum_targets > 0 and targets.size() >= maximum_targets:
		return false
	targets.append(candidate)
	return true


func remove(zone_id: StringName, instance_id: StringName) -> bool:
	for target in targets:
		if target.zone_id == zone_id and target.instance_id == instance_id:
			targets.erase(target)
			return true
	return false


func clear() -> void:
	targets.clear()


func first() -> DeckitCardTarget:
	return null if targets.is_empty() else targets.front()


func current(game: DeckitGameState) -> Array[DeckitCardTarget]:
	var valid: Array[DeckitCardTarget] = []
	for target in targets:
		if target.resolve(game) != null:
			valid.append(target)
	return valid
