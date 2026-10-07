extends RefCounted

func run(t) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/Main.gd")
	var start := source.find("func _on_setting_choice_selected")
	var block := source.substr(start, 140)
	t.assert_true(block.contains("_update_setting(key, value)"), "choice must save the selected value")
	t.assert_true(not block.contains("show_settings()"), "ordinary choice must not rebuild settings")
