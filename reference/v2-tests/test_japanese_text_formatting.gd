extends RefCounted

const JaText = preload("res://scripts/ui/JaText.gd")

func run(t) -> void:
	t.assert_eq(JaText.format_int(1234567), "1,234,567", "Japanese integer formatting should keep readable separators")
	t.assert_true(JaText.HELP_BODY.find("ショップ購入") >= 0, "help should explain shop purchase flow")
	t.assert_true(JaText.SUBTITLE.find("結晶迷宮") >= 0, "subtitle should communicate the exploration concept")
