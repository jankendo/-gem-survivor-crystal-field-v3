extends RefCounted

func run(t) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/Main.gd")
	t.assert_true(source.contains('summary.get("debug_progress_blocked", false)'), "manual result path must keep debug progress blocking")
	t.assert_true(source.contains('"currency_earned": 0'), "blocked result must not grant currency")
