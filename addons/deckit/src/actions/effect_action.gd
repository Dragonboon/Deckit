## Route a targeted state effect through DeckitGameState.perform(), so
## global DeckitCardRule hooks and action_applied/rejected signals are reused.
class_name DeckitEffectAction extends DeckitCardAction

var target: DeckitCardTarget
var effect: DeckitCardEffect
var conditions: Array[DeckitCardCondition] = []


## Configure before calling game.perform(); can_apply() also checks stale targets.
func configure(
	new_effect: DeckitCardEffect,
	new_target: DeckitCardTarget,
	player_id: StringName = &""
) -> DeckitEffectAction:
	effect = new_effect
	target = new_target
	actor_id = player_id
	if new_target != null:
		source_zone_id = new_target.zone_id
		destination_zone_id = new_target.zone_id
		card_instance_id = new_target.instance_id
	return self


func can_apply(game: DeckitGameState) -> bool:
	if game == null or target == null or effect == null:
		return false
	if source_zone_id != target.zone_id or destination_zone_id != target.zone_id:
		return false
	if card_instance_id != target.instance_id or target.resolve(game) == null:
		return false
	for condition in conditions:
		if condition == null or not condition.is_met(game, self, target):
			return false
	return effect.can_apply(game, target)


func apply(game: DeckitGameState) -> bool:
	if not can_apply(game):
		return false
	return effect.apply(game, target)
