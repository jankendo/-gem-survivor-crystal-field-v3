extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const GemScript = preload("res://scripts/core/ExpGem.gd")
const LevelUpScript = preload("res://scripts/systems/LevelUpSystem.gd")
const SelectionActionScript = preload("res://scripts/systems/SelectionActionSystem.gd")
const SelectionContextScript = preload("res://scripts/systems/SelectionContextSystem.gd")
const RewardPopupScript = preload("res://scripts/ui/RewardPopup.gd")
const EnemyAnimationPhaseCacheScript = preload("res://scripts/systems/EnemyAnimationPhaseCache.gd")
const GemCollectionVisualBatchScript = preload("res://scripts/systems/GemCollectionVisualBatchSystem.gd")
const GlobalGemCollectionScript = preload("res://scripts/systems/GlobalGemCollectionSystem.gd")
const PerformanceProfileScript = preload("res://scripts/systems/PerformanceProfileSystem.gd")
const EffectiveSettingsResolverScript = preload("res://scripts/systems/EffectiveSettingsResolver.gd")
const TouchControlScript = preload("res://scripts/systems/TouchControlSystem.gd")
const JaText = preload("res://scripts/ui/JaText.gd")
const TitleControllerScript = preload("res://scripts/ui/main/TitleScreenController.gd")
const ResultDamageFormatterScript = preload("res://scripts/systems/ResultDamageFormatter.gd")
const GameScreenScript = preload("res://scripts/ui/GameScreen.gd")
const Phase10HelperScript = preload("res://tests/helpers/Phase10TestScenarios.gd")

func state(seed: int = 90909, text: String = "phase9") -> Object:
	var s = StateScript.new()
	s.start_new_run(seed, text)
	return s

func selection_level_up_only(t) -> void:
	var s = state()
	var selection = SelectionActionScript.new()
	selection.begin_run(s, {"currency_sink_levels": {"levelup_reroll_capacity": 1, "selection_skip_charm": 1, "selection_seal_art": 1}, "stats": {}})
	s.level_up_pending = true
	s.selection_context = SelectionContextScript.LEVEL_UP
	s.level_up_options = LevelUpScript.new().prepare_options(s, 3)
	var before_reroll := int(s.selection_reroll_remaining)
	var events: Array = []
	t.assert_true(selection.consume_reroll(s, events), "LEVEL_UP should allow reroll")
	t.assert_eq(s.selection_reroll_remaining, before_reroll - 1, "LEVEL_UP reroll consumes one charge")
	t.assert_true(bool(selection.controls_for(s).get("level_up_actions", false)), "LEVEL_UP controls expose actions")

func selection_hidden_for_context(t, context: String) -> void:
	var s = state()
	var selection = SelectionActionScript.new()
	selection.begin_run(s, {"currency_sink_levels": {"levelup_reroll_capacity": 2, "selection_skip_charm": 2, "selection_seal_art": 2}, "stats": {}})
	s.level_up_pending = true
	s.selection_context = context
	s.level_up_options = LevelUpScript.new().prepare_options(s, 3)
	var before := [s.selection_reroll_remaining, s.selection_skip_remaining, s.selection_seal_remaining]
	var events: Array = []
	t.assert_true(not selection.consume_reroll(s, events), "%s must not reroll" % context)
	t.assert_true(not selection.skip_current(s, events), "%s must not skip" % context)
	t.assert_true(not selection.seal_option(s, "weapon:magic_bolt", events), "%s must not seal" % context)
	t.assert_eq([s.selection_reroll_remaining, s.selection_skip_remaining, s.selection_seal_remaining], before, "%s charges unchanged" % context)
	t.assert_true(not bool(selection.controls_for(s).get("level_up_actions", true)), "%s controls hide actions" % context)

func reward_popup_hides_level_actions(t) -> void:
	var popup = RewardPopupScript.new()
	popup._ready()
	popup.show_options([{"uid": "core_decline:weapon", "kind": "decline", "name_ja": "取得しない", "description_ja": "見送り"}], {"context": SelectionContextScript.WEAPON_CORE, "level_up_actions": false, "can_decline": true, "decline_text": "取得しない", "title": "コアの中身を選択"}, true)
	for child in popup.list.get_children():
		if child is Button:
			for word in ["再抽選", "封印", "スキップ"]:
				t.assert_true(String(child.text).find(word) < 0, "non-level selection hides %s" % word)
	popup.queue_free()

func enemy_snapshot_and_batch(t) -> void:
	Phase10HelperScript.new().enemy_all_tier_ultralite(t)

func enemy_phase_cache(t) -> void:
	var cache = EnemyAnimationPhaseCacheScript.new()
	var p1 := cache.phase_for("slime", 10.00, 8, 8)
	var p2 := cache.phase_for("slime", 10.01, 8, 8)
	t.assert_eq(p1, p2, "phase cache quantizes nearby frames")
	t.assert_true(p1 >= 0 and p1 < 8, "phase index stays inside steps")

func gem_collection_batch(t) -> void:
	var s = state()
	s.gems.clear()
	for i in range(120):
		s.gems.append(GemScript.new(Vector2(100 + i * 3, 200 + i), 2 + i % 5))
	var result := GlobalGemCollectionScript.new().collect_all(s, [], "magnet", 1.0)
	var metrics: Dictionary = result.get("metrics", {})
	t.assert_eq(int(result.get("count", 0)), 120, "all simulation gems are collected")
	t.assert_eq(s.gems.size(), 0, "collection empties simulation gems")
	t.assert_eq(int(result.get("exp", 0)), int(metrics.get("actual_exp", -1)), "EXP remains exact")
	t.assert_true(int(metrics.get("proxy_nodes", 99)) <= 4, "visual representatives are bounded")

func gem_visual_batch_priority(t) -> void:
	var batch := GemCollectionVisualBatchScript.new().make_batch("magnet", [Vector2.ZERO, Vector2.ONE, Vector2(2, 2), Vector2(3, 3), Vector2(4, 4)], 1200, 4800, Vector2(9, 9), 4)
	t.assert_eq(int(batch.get("representative_count", -1)), 4, "representative count is capped")
	t.assert_eq(String(batch.get("priority", "")), "signature", "large collection remains signature priority")

func time_and_removed_settings(t) -> void:
	t.assert_eq(JaText.format_time(125.0), "02:05", "survival time uses minute-second format")
	var lines: Array = TitleControllerScript.new().status_lines({"stats": {"best_survival": 452.0}, "crystal_currency": 5}, "ノア", "攻撃")
	t.assert_true(String(lines[2]).find("07:32") >= 0, "best survival uses minute-second format")
	var profile = PerformanceProfileScript.new()
	t.assert_true(not bool(profile.ui_limits({"damage_numbers": true}, "Windows").get("damage_numbers_enabled", true)), "damage numbers remain removed")
	var touch = TouchControlScript.new()
	touch.configure({"touch_ui_mode": "on", "touch_haptics": true}, "iOS")
	t.assert_true(not touch.feedback_light() and touch.haptic_count == 0, "haptics remain removed")
	var effective := EffectiveSettingsResolverScript.new().resolve({"battery_saver": true, "damage_numbers": true, "touch_haptics": true})
	t.assert_true(not bool(effective.get("damage_numbers", true)) and not bool(effective.get("touch_haptics", true)), "removed settings stay disabled")

func seed_copy_contract(t) -> void:
	var game = GameScreenScript.new()
	game.state = state(12345, "seed-copy")
	t.assert_eq(game._current_seed_text(), "seed-copy", "pause seed text uses map seed text")
	t.assert_true(game.copy_current_seed_to_clipboard(), "seed copy is headless safe")
	game.free()

func result_damage_lines(t) -> void:
	var lines: Array = ResultDamageFormatterScript.new().weapon_damage_lines({"weapon_damage_by_id": {"magic_bolt": 300, "ice_orbit": 100}}, 4)
	t.assert_true(lines.size() >= 3, "damage formatter returns rows")
	t.assert_true(String(lines[1]).find("300") >= 0 and String(lines[1]).find("75.0%") >= 0, "damage row includes total and percentage")
