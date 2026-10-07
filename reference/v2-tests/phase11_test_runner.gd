extends SceneTree

const SUITES := [
	"res://tests/test_warp_chest_collection.gd",
	"res://tests/test_warp_chest_reward_once.gd",
	"res://tests/test_warp_room_type_determinism.gd",
	"res://tests/test_warp_room_type_distribution.gd",
	"res://tests/test_warp_room_identity_ui.gd",
	"res://tests/test_warp_normal_room_flow.gd",
	"res://tests/test_warp_heaven_room_flow.gd",
	"res://tests/test_warp_hell_room_flow.gd",
	"res://tests/test_warp_heaven_loot_quantity.gd",
	"res://tests/test_warp_hell_difficulty.gd",
	"res://tests/test_warp_reward_safe_placement.gd",
	"res://tests/test_core_candidates_at_capacity.gd",
	"res://tests/test_core_candidate_randomness.gd",
	"res://tests/test_loadout_replacement_transaction.gd",
	"res://tests/test_loadout_replacement_rollback.gd",
	"res://tests/test_weapon_combo_data_validation.gd",
	"res://tests/test_weapon_combo_activation.gd",
	"res://tests/test_weapon_combo_deactivation.gd",
	"res://tests/test_weapon_combo_evolved_alias.gd",
	"res://tests/test_weapon_combo_determinism.gd",
	"res://tests/test_weapon_combo_damage_attribution.gd",
	"res://tests/test_weapon_combo_no_recursion.gd",
	"res://tests/test_weapon_combo_ui.gd",
	"res://tests/test_weapon_combo_result_summary.gd",
	"res://tests/test_weapon_combo_performance.gd",
	"res://tests/test_ios_warp_combo_layout.gd",
]

var failures: Array = []
var assertions := 0

func _initialize() -> void:
	for path in SUITES:
		print("[phase11] ", path)
		var assertion_start := assertions
		var script = load(path)
		if script == null or not script.can_instantiate():
			failures.append("Suite failed to load: %s" % path)
			continue
		var suite = script.new()
		if suite == null or not suite.has_method("run"):
			failures.append("Suite has no run(t): %s" % path)
			continue
		suite.run(self)
		if assertions == assertion_start:
			failures.append("Suite executed no assertions: %s" % path)
	if failures.is_empty():
		print("Phase 11 tests passed: ", assertions)
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
