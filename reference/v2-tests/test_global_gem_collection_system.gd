extends RefCounted

const ExpGemScript = preload("res://scripts/core/ExpGem.gd")
const GlobalGemCollectionSystemScript = preload("res://scripts/systems/GlobalGemCollectionSystem.gd")
const RecallDroneSystemScript = preload("res://scripts/systems/RecallDroneSystem.gd")
const FieldDropSystemScript = preload("res://scripts/systems/FieldDropSystem.gd")

func run(t) -> void:
	test_magnet_collects_all_field_gems(t)
	test_drone_collects_all_field_gems(t)
	test_global_gem_collection_performance(t)

func _add_far_gems(state, count: int) -> void:
	for i in range(count):
		state.gems.append(ExpGemScript.new(Vector2(200.0 + float(i % 50) * 80.0, 200.0 + float(i / 50) * 80.0), 4))

func test_magnet_collects_all_field_gems(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(0, "magnet-all")
	state.gems.clear()
	_add_far_gems(state, 25)
	var drop = {"id": "magnet_ore", "position": state.player_position, "radius": 24.0, "collected": false}
	state.field_drops = [drop]
	var events: Array = []
	FieldDropSystemScript.new().process(state, 0.1, events)
	t.assert_eq(state.gems.size(), 0, "magnet ore should collect all field gems")
	t.assert_eq(state.gems_collected_by_magnet, 25, "magnet collection count should be recorded")
	t.assert_eq(int(state.global_gem_collection_last_metrics.get("missing", -1)), 0, "magnet collection should have no missing gems")
	t.assert_true(not state.gem_ring_effects.is_empty(), "magnet collection should create a ring collection effect")

func test_drone_collects_all_field_gems(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(0, "drone-all")
	state.gems.clear()
	_add_far_gems(state, 30)
	state.recall_drone_ready = true
	var events: Array = []
	t.assert_true(RecallDroneSystemScript.new().activate(state, events), "drone should activate")
	t.assert_eq(state.gems.size(), 0, "recall drone should collect all field gems")
	t.assert_eq(state.gems_collected_by_drone, 30, "drone collection count should be recorded")
	t.assert_eq(int(state.global_gem_collection_last_metrics.get("collected", 0)), 30, "drone metrics should record collected count")

func test_global_gem_collection_performance(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(0, "global-performance")
	state.gems.clear()
	_add_far_gems(state, 500)
	var result = GlobalGemCollectionSystemScript.new().collect_all(state, [], "magnet")
	t.assert_eq(int(result.get("count", 0)), 500, "global collector should collect all test gems")
	t.assert_true(int(result.get("batches", 0)) <= 4, "global collector should batch 500 gems near 160 per batch")
	var metrics: Dictionary = result.get("metrics", {})
	t.assert_eq(int(metrics.get("expected_count", 0)), 500, "metrics should record expected gem count")
	t.assert_eq(int(metrics.get("actual_exp", 0)), int(metrics.get("expected_exp", -1)), "metrics should record exact EXP transaction")
	t.assert_true(int(metrics.get("proxy_nodes", 0)) <= 4, "Phase 9 ring effect should use at most four representative gems")
