extends RefCounted

const V2HudPresenterScript = preload("res://scripts/systems/V2HudPresenter.gd")
const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9301, "")
	state.v2_momentum_timer = 3.0
	state.v2_momentum_tier = 1
	state.v2_momentum_score_multiplier = 1.2
	var text := V2HudPresenterScript.new().momentum_text(state)
	t.assert_true(text.find("ラッシュ") >= 0, "momentum HUD should use Japanese term")
	t.assert_true(text.find("MOMENTUM") < 0, "momentum HUD should not expose English term")
