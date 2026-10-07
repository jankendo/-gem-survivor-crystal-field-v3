extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const V2HudPresenterScript = preload("res://scripts/systems/V2HudPresenter.gd")

func run(t) -> void:
	test_hud_suffix_contains_score_and_crystals(t)
	test_momentum_text_uses_active_state(t)
	test_result_highlights_include_build_summary(t)

func test_hud_suffix_contains_score_and_crystals(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(11)
	state.score = 12345
	state.crystals_destroyed = 7
	var presenter = V2HudPresenterScript.new()
	var text := presenter.top_hud_suffix(state)
	t.assert_true(text.find("スコア") >= 0, "hud suffix should include score label")
	t.assert_true(text.find("結晶") >= 0, "hud suffix should include crystal label")

func test_momentum_text_uses_active_state(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(11)
	state.v2_momentum_timer = 9.0
	state.v2_momentum_label = "連続撃破"
	state.v2_momentum_score_multiplier = 1.08
	var presenter = V2HudPresenterScript.new()
	var text := presenter.momentum_text(state)
	t.assert_true(text.find("ラッシュ") >= 0, "momentum text should show compact rush state")
	t.assert_true(text.find("1.08") >= 0, "momentum text should show multiplier")

func test_result_highlights_include_build_summary(t) -> void:
	var presenter = V2HudPresenterScript.new()
	var lines := presenter.result_highlights({
		"max_weapon": "魔弾 Lv5",
		"evolved_weapon_count": 1,
		"synergy_history": ["gem_engine"],
		"v2_peak_momentum_tier": 2,
		"v2_momentum_triggers": 3,
		"v2_best_kill_streak": 50,
		"v2_no_damage_best": 65.0
	})
	t.assert_true(lines.size() >= 3, "result highlights should include momentum, streak, and build lines")
	t.assert_true(String(lines.back()).find("今回のビルド") >= 0, "last highlight should summarize build")
