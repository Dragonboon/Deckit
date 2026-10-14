## One actionable build problem; use code for localization or custom UI.
class_name DeckitDeckIssue extends RefCounted

enum Severity { ERROR, WARNING }

var severity: Severity = Severity.ERROR
var code: StringName = &""
var message: String = ""
var card_id: StringName = &""
var section_id: StringName = &""


func _init(
	issue_code: StringName = &"",
	description: String = "",
	card: StringName = &"",
	section: StringName = &"",
	level: Severity = Severity.ERROR
) -> void:
	code = issue_code
	message = description
	card_id = card
	section_id = section
	severity = level
