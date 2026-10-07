extends RefCounted

const ProgressionRecommendationSystemScript = preload("res://scripts/systems/ProgressionRecommendationSystem.gd")

func run(t) -> void:
	var text := ProgressionRecommendationSystemScript.new().objective_text({
		"name_ja": "進化核",
		"position": Vector2(300, 0),
		"danger": 4,
		"reward_ja": "進化核"
	}, Vector2.ZERO)
	t.assert_true(text.find("危険度") >= 0 and text.find("報酬") >= 0 and text.find("距離") >= 0, "objective text should show distance, risk, and reward")
