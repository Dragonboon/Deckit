## Lightweight per-participant tracks for score, coins, health, actions, etc.
## No game-specific currency, limits or win/loss semantics are imposed.
class_name DeckitValueLedger extends RefCounted

signal values_changed(participant_id: StringName, changed_tracks: PackedStringArray)

var _values: Dictionary = {}


func get_value(participant_id: StringName, track_id: StringName) -> int:
	if participant_id == &"" or track_id == &"":
		return 0
	var bucket: Dictionary = _values.get(participant_id, {})
	return int(bucket.get(track_id, 0))


## Signed values allow point penalties. Games choose legal ranges.
func set_value(participant_id: StringName, track_id: StringName, value: int) -> bool:
	if participant_id == &"" or track_id == &"":
		return false
	var bucket: Dictionary = _values.get(participant_id, {})
	bucket[track_id] = value
	_values[participant_id] = bucket
	values_changed.emit(participant_id, PackedStringArray([String(track_id)]))
	return true


func add_value(participant_id: StringName, track_id: StringName, amount: int) -> bool:
	return set_value(participant_id, track_id, get_value(participant_id, track_id) + amount)


## Strict, atomic cost check: nonnegative integer costs only; no changes
## are made unless ALL requested tracks have sufficient nonnegative balance.
func can_pay(participant_id: StringName, costs: Dictionary) -> bool:
	if participant_id == &"" or costs.is_empty():
		return false
	for key: Variant in costs:
		var name: StringName = StringName(str(key))
		var amount: Variant = costs[key]
		if name == &"" or not (amount is int) or int(amount) < 0:
			return false
		if get_value(participant_id, name) < int(amount):
			return false
	return true


## Emits one change notification after all balances were updated.
func pay(participant_id: StringName, costs: Dictionary) -> bool:
	if not can_pay(participant_id, costs):
		return false
	var bucket: Dictionary = _values.get(participant_id, {})
	var changed := PackedStringArray()
	for key: Variant in costs:
		var name: StringName = StringName(str(key))
		bucket[name] = int(bucket.get(name, 0)) - int(costs[key])
		changed.append(String(name))
	_values[participant_id] = bucket
	values_changed.emit(participant_id, changed)
	return true


## Nonnegative integer grants. All-or-nothing input validation.
func grant(participant_id: StringName, gains: Dictionary) -> bool:
	if participant_id == &"" or gains.is_empty():
		return false
	for key: Variant in gains:
		if String(str(key)).is_empty() or not (gains[key] is int) or int(gains[key]) < 0:
			return false
	var bucket: Dictionary = _values.get(participant_id, {})
	var changed := PackedStringArray()
	for key: Variant in gains:
		var name: StringName = StringName(str(key))
		bucket[name] = int(bucket.get(name, 0)) + int(gains[key])
		changed.append(String(name))
	_values[participant_id] = bucket
	values_changed.emit(participant_id, changed)
	return true


func snapshot(participant_id: StringName) -> Dictionary:
	var bucket: Dictionary = _values.get(participant_id, {})
	return bucket.duplicate(true)


func clear() -> void:
	_values.clear()
