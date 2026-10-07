extends RefCounted

func run(t) -> void:
	test_result_summary_prioritizes_momentum_and_next_actions(t)

func test_result_summary_prioritizes_momentum_and_next_actions(t) -> void:
	var result = load("res://scenes/Result.tscn").instantiate()
	result._ready()
	result.show_summary({
		"score": 10000,
		"best_score": 12000,
		"survival_time": 605.0,
		"level": 18,
		"kills": 640,
		"boss_defeats": 1,
		"max_weapon": "魔弾 Lv5",
		"evolved_weapon_ids": ["starbreaker_bolt"],
		"synergy_history": ["gem_engine"],
		"v2_peak_momentum_tier": 3,
		"v2_momentum_triggers": 4,
		"v2_momentum_active_time_total": 38.0,
		"v2_momentum_score_bonus": 420,
		"v2_momentum_main_trigger": "boss_defeat",
		"v2_momentum_suppressed_duplicates": 2,
		"v2_momentum_trigger_counts": {"boss_defeat": 1, "evolution": 1, "kill_streak": 2},
		"currency_earned": 150,
		"currency_total": 400
	})
	var text: String = result.lines.text
	t.assert_true(text.find("生存時間") < text.find("ラッシュ成果"), "result should show core summary before rush details")
	t.assert_true(text.find("ラッシュ最高段階：III") >= 0, "result should show peak rush tier")
	t.assert_true(text.find("ラッシュスコア：+420") >= 0, "result should show rush score bonus")
	t.assert_true(text.find("最多発動要因：ボス撃破") >= 0, "result should show main momentum trigger")
	t.assert_true(_find_button(result, "もう一度") != null, "result should keep retry as primary next action")
	result.free()

func _find_button(node: Node, label_part: String) -> Button:
	if node is Button and (node as Button).text.find(label_part) >= 0:
		return node as Button
	for child in node.get_children():
		var found = _find_button(child, label_part)
		if found != null:
			return found
	return null
