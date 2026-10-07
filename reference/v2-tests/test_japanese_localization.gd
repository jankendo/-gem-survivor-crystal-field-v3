extends RefCounted

const JapaneseTextSystemScript = preload("res://scripts/systems/JapaneseTextSystem.gd")

func run(t) -> void:
	var ja = JapaneseTextSystemScript.new()
	t.assert_eq(ja.term("Momentum"), "ラッシュ", "Momentum should be localized as ラッシュ")
	t.assert_eq(ja.term("READY"), "使用可能", "READY should be localized as 使用可能")
	t.assert_true(ja.text("concept").find("結晶迷宮") >= 0, "concept text should be Japanese")
