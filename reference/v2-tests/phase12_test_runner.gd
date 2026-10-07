extends SceneTree

const SUITES := [
	"test_ios_ultra_profile_values.gd", "test_ios_ultra_simulation_parity.gd", "test_ios_ultra_rng_parity.gd",
	"test_ios_ultra_damage_parity.gd", "test_ios_ultra_combo_damage_parity.gd", "test_ios_ultra_enemy_count_parity.gd",
	"test_ios_ultra_reward_parity.gd", "test_ios_ultra_critical_visuals.gd", "test_ios_ultra_effect_budget.gd",
	"test_ios_ultra_unbudgeted_effect_audit.gd", "test_world_render_shrink_layout.gd", "test_world_render_touch_mapping.gd",
	"test_ios_ultra_ui_text_scale_parity.gd", "test_ios_ultra_ui_root_viewport_contract.gd",
	"test_ios_ultra_runtime_profile_ui_stability.gd", "test_ios_ultra_modal_text_scale_parity.gd",
	"test_equipment_grid_all_slots_visible.gd", "test_equipment_grid_safe_area.gd", "test_equipment_grid_minimum_touch_target.gd",
	"test_equipment_grid_detail_selection.gd", "test_equipment_grid_keyboard_navigation.gd", "test_equipment_grid_no_normal_scroll.gd",
	"test_equipment_grid_overcap_paging.gd", "test_equipment_grid_dirty_update.gd", "test_equipment_icon_fallback.gd",
	"test_thermal_profile_transition.gd", "test_low_power_mode_effective_settings.gd", "test_thermal_does_not_mutate_saved_settings.gd",
	"test_enemy_batch_visual_parity.gd", "test_enemy_batch_performance.gd",
	"test_ios_ultra_all_enemy_types_visible.gd", "test_ios_ultra_enemy_instance_alpha.gd",
	"test_ios_ultra_enemy_bucket_membership_refresh.gd", "test_ios_ultra_enemy_slot_reuse.gd",
	"test_ios_ultra_enemy_spawn_despawn_visibility.gd", "test_ios_ultra_enemy_cadence_contract.gd",
]

var failures: Array = []
var assertions := 0

func _initialize() -> void:
	for file_name in SUITES:
		var path := "res://tests/%s" % file_name
		var before := assertions
		var script = load(path)
		if script == null or not script.can_instantiate():
			failures.append("Suite failed to load: %s" % path)
			continue
		var suite = script.new()
		suite.run(self)
		if assertions == before:
			failures.append("Suite executed no assertions: %s" % path)
	if failures.is_empty():
		print("Phase 12 tests passed: ", assertions)
		quit(0)
	else:
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
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
