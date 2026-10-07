extends RefCounted

func run(t) -> void:
	var result = preload("res://scripts/ui/ResultView.gd").new()
	var text := result._progress_delta_text([
		{"label": "敵撃破", "delta": 12, "current": 42, "target": 100, "value_type": "number"},
		{"label": "生存時間", "delta": 30, "current": 452, "target": 600, "value_type": "time"}
	])
	t.assert_true(text.contains("敵撃破 +12 → 42 / 100"), "result should show numeric progress delta")
	t.assert_true(text.contains("生存時間 +0:30 → 7:32 / 10:00"), "result should show time progress delta")
	result.free()
