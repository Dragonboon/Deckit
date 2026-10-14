## Scenario policy lives here; the reusable add-on remains rule-neutral.
extends Control

var game := DeckitGameState.new()
var selected := DeckitTargetSelection.new(1)
var source := DeckitCardZone.new(&"hand", &"demo")
var table := DeckitCardZone.new(&"table", &"demo")
var status: Label
var cards_list: ItemList
var visual: DeckitZoneView
var condition := DeckitTagCondition.new()


func _ready() -> void:
	var page := DeckitLabUI.page(
		self, "05 • Targets & Effects",
		"Select a card, then apply generic effects or a checked two-step sequence. Tagged restrictions belong to an optional condition."
	)
	var controls := DeckitLabUI.controls(page)
	DeckitLabUI.button(controls, "Add counter", _effect.bind(false))
	DeckitLabUI.button(controls, "Toggle face", _effect.bind(true))
	DeckitLabUI.button(controls, "Conditional counter", _conditional)
	DeckitLabUI.button(controls, "Move + counter sequence", _sequence)
	DeckitLabUI.button(controls, "Reset", _reset)
	cards_list = ItemList.new()
	cards_list.custom_minimum_size = Vector2(560, 200)
	cards_list.item_selected.connect(_select)
	page.add_child(cards_list)
	visual = DeckitLabCardArt.zone_panel(page, game, &"hand", &"demo", 4)
	visual.card_requested.connect(func(_zone: StringName, id: StringName) -> void:
		selected.clear()
		selected.select(game, &"hand", id)
	)
	status = DeckitLabUI.info(page, "")
	game.action_applied.connect(_on_applied)
	game.action_rejected.connect(_on_rejected)
	condition.tag = "eligible"
	_reset()


func _reset() -> void:
	game.zones.clear()
	source.cards.clear()
	table.cards.clear()
	game.register_zone(source)
	game.register_zone(table)
	selected.clear()
	for index in range(3):
		var definition := DeckitCardDefinition.new()
		definition.card_id = StringName("demo-%d" % index)
		definition.display_name = "Sample %d" % (index + 1)
		definition.tags = PackedStringArray(["eligible"] if index != 1 else ["restricted"])
		DeckitLabCardArt.decorate(definition)
		var card := DeckitCardInstance.new(definition, StringName("instance-%d" % index))
		card.face_up = true
		source.add_card(card)
	visual.bind(game, &"hand", &"demo")
	status.text = "Select a card. The middle card lacks the eligible tag."
	_refresh()


func _select(index: int) -> void:
	if index < source.size():
		selected.clear()
		selected.select(game, &"hand", source.cards[index].instance_id)


func _get_target() -> DeckitCardTarget:
	var target := selected.first()
	if target == null or target.resolve(game) == null:
		status.text = "Select a card still present in the hand."
		return null
	return target


func _make_counter(target: DeckitCardTarget) -> DeckitEffectAction:
	var effect := DeckitCounterEffect.new()
	effect.counter_key = &"charge"
	effect.delta = 1
	return DeckitEffectAction.new().configure(effect, target, &"demo")


func _effect(toggle_face: bool) -> void:
	var target := _get_target()
	if target == null:
		return
	var action: DeckitEffectAction
	if toggle_face:
		action = DeckitEffectAction.new().configure(DeckitFaceEffect.new(), target, &"demo")
	else:
		action = _make_counter(target)
	game.perform(action)
	_refresh()


func _conditional() -> void:
	var target := _get_target()
	if target == null:
		return
	var action := _make_counter(target)
	action.conditions.append(condition)
	game.perform(action)
	_refresh()


func _sequence() -> void:
	var target := _get_target()
	if target == null:
		return
	var sequence := DeckitActionSequence.new()
	sequence.add_step(DeckitCardAction.new(&"hand", &"table", target.instance_id, &"demo"))
	sequence.add_step(_make_counter(DeckitCardTarget.new(&"table", target.instance_id)))
	var result: bool = sequence.execute(game)
	status.text = "Sequence %s; %d applied; failed index %d." % [
		"accepted" if result else "stopped", sequence.executed_count, sequence.failed_step
	]
	selected.clear()
	_refresh()


func _on_applied(action: DeckitCardAction) -> void:
	status.text = "Applied action on %s." % action.card_instance_id


func _on_rejected(action: DeckitCardAction) -> void:
	status.text = "Rejected action on %s; rules or conditions did not allow it." % action.card_instance_id


func _refresh() -> void:
	visual.refresh()
	cards_list.clear()
	for index in range(source.size()):
		var card := source.cards[index]
		cards_list.add_item("%s | %s | charge:%d | face:%s" % [
			card.definition.display_name,
			card.definition.tags[0],
			card.get_counter(&"charge"),
			"up" if card.face_up else "down"
		])
		var target := selected.first()
		if target != null and target.instance_id == card.instance_id:
			cards_list.select(index)
