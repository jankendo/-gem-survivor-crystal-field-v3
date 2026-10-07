extends RefCounted

const ProgressionRecommendationSystemScript = preload("res://scripts/systems/ProgressionRecommendationSystem.gd")
const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")

func run(t) -> void:
	var data := SaveSystemScript.new("user://test_progression_recommendation.save").load_data()
	var actions: Array = ProgressionRecommendationSystemScript.new().next_actions(data)
	t.assert_true(actions.size() >= 1, "progression recommendation should provide at least one next action")
	t.assert_true(String(actions[0]).find("クリスタル貨") >= 0 or String(actions[0]).find("ショップ") >= 0, "recommendation should guide shop or currency loop")
