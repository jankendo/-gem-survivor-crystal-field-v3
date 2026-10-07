extends RefCounted

func run(t) -> void:
	var result = ResultView.new()
	result._ready()
	result.show_summary({
		"score": 12345,
		"best_score": 20000,
		"kills": 321,
		"survival_time": 612.0,
		"level": 18,
		"currency_earned": 240,
		"mastery": {"level": 3, "points": 900},
		"progress_deltas": [{"label": "武器解放", "delta": 1, "current": 2, "target": 5}]
	})
	t.assert_true(result.lines.text.find("今回の成果") >= 0, "result should summarize outcomes")
	t.assert_true(result.lines.text.find("成長") >= 0, "result should summarize growth")
	t.assert_true(result.lines.text.find("次の目標") >= 0, "result should show next goal")
	result.free()
