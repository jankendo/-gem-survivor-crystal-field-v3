extends SceneTree

func _initialize() -> void:
	var result = ResultView.new()
	root.add_child(result)
	await process_frame
	result.show_summary({
		"score": 24000,
		"best_score": 25000,
		"kills": 700,
		"survival_time": 900.0,
		"level": 24,
		"currency_earned": 520,
		"currency_total": 1800,
		"mastery": {"level": 4, "points": 1600},
		"progress_deltas": [{"label": "探索ランク", "delta": 1, "current": 2, "target": 5}]
	})
	if result.lines.text.find("今回の成果") < 0 or result.lines.text.find("次の目標") < 0:
		push_error("result/status autoplay did not expose outcome and next goal text")
		quit(1)
	print("AutoPlay Result Status UI OK.")
	quit(0)
