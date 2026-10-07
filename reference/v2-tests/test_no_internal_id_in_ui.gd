extends RefCounted

const JapaneseTextSystemScript = preload("res://scripts/systems/JapaneseTextSystem.gd")

func run(t) -> void:
	var ja = JapaneseTextSystemScript.new()
	t.assert_eq(ja.safe_label("laser_lance", "武器"), "武器", "internal snake_case id should not be displayed directly")
	t.assert_eq(ja.safe_label("光槍", "武器"), "光槍", "Japanese display name should be preserved")
