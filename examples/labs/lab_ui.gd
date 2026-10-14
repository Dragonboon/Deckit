## Example-only scene helpers. This file does not belong to the plugin.
class_name DeckitLabUI extends RefCounted

const HUB: String = "res://examples/labs/lab_hub.tscn"


static func page(root: Control, page_heading: String, summary: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	scroll.add_child(margin)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title := Label.new()
	title.text = page_heading
	title.add_theme_font_size_override("font_size", 23)
	column.add_child(title)

	var description := Label.new()
	description.text = summary
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)

	var home := Button.new()
	home.text = "← All labs"
	home.pressed.connect(func() -> void: root.get_tree().change_scene_to_file(HUB))
	column.add_child(home)
	return column


static func heading(parent: Node, value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", 16)
	parent.add_child(label)
	return label


static func button(parent: Node, value: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = value
	result.pressed.connect(callback)
	parent.add_child(result)
	return result


static func controls(parent: Node) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	parent.add_child(flow)
	return flow


static func info(parent: Node, message: String) -> Label:
	var result := Label.new()
	result.text = message
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(result)
	return result
