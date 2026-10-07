extends RefCounted

func run(t) -> void:
	var settings: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/ui_layout.json"))
	t.assert_true(settings is Dictionary, "UI layout data should be readable")
	t.assert_true(FileAccess.file_exists("res://data/localization_ja.json"), "Japanese localization data should exist for readable UI")
