extends RefCounted

func run(t) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/GameScreen.gd")
	t.assert_true(source.contains("speed_lock_system.begin_press()"), "touch press must begin speed lock")
	t.assert_true(source.contains("speed_lock_system.end_press()"), "touch release must finish speed lock")
	t.assert_true(source.contains("speed_lock_system.display_text()"), "touch button must display lock state")
