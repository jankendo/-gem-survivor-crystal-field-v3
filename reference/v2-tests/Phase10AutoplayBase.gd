extends SceneTree

const Helper = preload("res://tests/helpers/Phase10TestScenarios.gd")
const Perf = preload("res://tests/Phase10PerformanceHarness.gd")

var failures: Array = []
var assertions := 0

func scenario_id() -> String:
	return "performance"

func _initialize() -> void:
	var helper = Helper.new()
	match scenario_id():
		"gem":
			helper.gem_persistence(self)
			helper.global_collection_exact(self)
		"elite", "boss":
			helper.enemy_all_tier_ultralite(self)
			helper.enemy_spawn_prewarm(self)
		"heaven":
			helper.warp_flow(self, "heaven")
		"hell":
			helper.warp_flow(self, "hell")
		"roundtrip":
			helper.warp_flow(self, "heaven")
			helper.warp_flow(self, "hell")
		"placement":
			helper.warp_placement_100_seed(self)
		_:
			var summary := Perf.new().run()
			assert_true(bool(summary.get("ok", false)), "performance harness parity")
	if failures.is_empty():
		print("Phase 10 autoplay passed: ", scenario_id(), " assertions=", assertions)
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
		failures.append("%s expected=%s actual=%s" % [message, str(expected), str(actual)])
