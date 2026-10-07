extends SceneTree

const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")

var failures: Array = []
var assertions := 0
var original_settings: Dictionary = {}

const SUITES := [
	"res://tests/test_selection_actions_level_up_only.gd",
	"res://tests/test_selection_actions_hidden_for_core.gd",
	"res://tests/test_selection_actions_hidden_for_chest.gd",
	"res://tests/test_selection_action_charge_integrity.gd",
	"res://tests/test_enemy_render_snapshot_parity.gd",
	"res://tests/test_enemy_visual_batch.gd",
	"res://tests/test_enemy_animation_phase_cache.gd",
	"res://tests/test_enemy_minimal_critical_visibility.gd",
	"res://tests/test_enemy_simulation_unchanged_by_visual_profile.gd",
	"res://tests/test_gem_collection_batch_totals.gd",
	"res://tests/test_gem_collection_visual_budget.gd",
	"res://tests/test_gem_collection_high_value_priority.gd",
	"res://tests/test_gem_collection_no_per_gem_nodes.gd",
	"res://tests/test_gem_collection_no_per_gem_tweens.gd",
	"res://tests/test_global_gem_collection_single_batch.gd",
	"res://tests/test_gem_collection_simulation_parity.gd",
	"res://tests/test_survival_time_japanese_format.gd",
	"res://tests/test_best_survival_display_consistency.gd",
	"res://tests/test_damage_numbers_removed.gd",
	"res://tests/test_legacy_damage_setting_ignored.gd",
	"res://tests/test_touch_haptics_removed.gd",
	"res://tests/test_legacy_haptic_setting_ignored.gd",
	"res://tests/test_pause_seed_display.gd",
	"res://tests/test_pause_seed_copy.gd",
	"res://tests/test_clipboard_headless_safe.gd",
	"res://tests/test_result_weapon_damage_totals.gd",
	"res://tests/test_result_evolution_damage_breakdown.gd",
	"res://tests/test_result_damage_percentage.gd",
	"res://tests/test_result_damage_safe_area.gd",
	"res://tests/auto_play_phase9_enemy_motion_stress.gd",
	"res://tests/auto_play_phase9_gem_collection_burst.gd",
	"res://tests/auto_play_phase9_visual_simulation_parity.gd"
]

func _initialize() -> void:
	var save := SaveSystemScript.new()
	original_settings = save.load_data().get("settings", {}).duplicate(true)
	for suite_path in SUITES:
		print("Running ", suite_path)
		var suite_script = load(suite_path)
		if suite_script == null or not suite_script.can_instantiate():
			failures.append("Suite failed to load: %s" % suite_path)
			continue
		var suite = suite_script.new()
		if suite == null or not suite.has_method("run"):
			failures.append("Suite has no run(t): %s" % suite_path)
			continue
		suite.run(self)
	save.update_settings(original_settings)
	if failures.is_empty():
		print("Phase 9 tests passed: ", assertions)
		quit(0)
	else:
		push_error("%d Phase 9 tests failed." % failures.size())
		for failure in failures:
			push_error(failure)
		quit(1)

func assert_true(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)

func assert_eq(actual, expected, message: String) -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, str(expected), str(actual)])
