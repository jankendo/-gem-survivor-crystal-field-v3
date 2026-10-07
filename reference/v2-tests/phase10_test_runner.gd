extends SceneTree

const SUITES := [
	"res://tests/test_gem_persistence.gd",
	"res://tests/test_gem_lifecycle_removal_reasons.gd",
	"res://tests/test_gem_visual_simulation_separation.gd",
	"res://tests/test_scan_feature_removed.gd",
	"res://tests/test_scan_save_migration.gd",
	"res://tests/test_warp_room_seed_determinism.gd",
	"res://tests/test_warp_room_portal_placement.gd",
	"res://tests/test_warp_room_heaven_flow.gd",
	"res://tests/test_warp_room_hell_flow.gd",
	"res://tests/test_warp_room_return_state.gd",
	"res://tests/test_warp_room_reward_once.gd",
	"res://tests/test_warp_room_no_softlock.gd",
	"res://tests/test_enemy_all_tier_ultralite.gd",
	"res://tests/test_enemy_spawn_prewarm.gd",
	"res://tests/test_enemy_visual_simulation_parity.gd",
	"res://tests/test_ios_touch_layout_without_scan.gd",
]

var failures: Array = []
var assertions := 0

func _initialize() -> void:
	for path in SUITES:
		var script = load(path)
		if script == null or not script.can_instantiate():
			failures.append("Suite failed to load: %s" % path)
			continue
		var suite = script.new()
		if suite == null or not suite.has_method("run"):
			failures.append("Suite has no run(t): %s" % path)
			continue
		suite.run(self)
	if failures.is_empty():
		print("Phase 10 tests passed: ", assertions)
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
