extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const V2MomentumSystemScript = preload("res://scripts/systems/V2MomentumSystem.gd")

func run(t) -> void:
	test_global_collection_duplicate_is_suppressed(t)
	test_evolution_duplicate_is_suppressed(t)
	test_boss_defeat_duplicate_is_suppressed(t)

func test_global_collection_duplicate_is_suppressed(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(7)
	state.elapsed_seconds = 30.0
	var system = V2MomentumSystemScript.new()
	var events := [
		{"type": "global_gem_collection", "source": "magnet", "count": 60, "exp": 120},
		{"type": "global_gem_collection", "source": "magnet", "count": 60, "exp": 120}
	]
	system.process(state, 0.1, events)
	t.assert_eq(int(state.v2_momentum_trigger_counts.get("global_gem_collection", 0)), 1, "same global collection should count once")
	t.assert_eq(int(state.v2_momentum_suppressed_duplicates), 1, "same global collection should increment duplicate suppression")

func test_evolution_duplicate_is_suppressed(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(8)
	state.elapsed_seconds = 90.0
	var system = V2MomentumSystemScript.new()
	var events := [
		{"type": "evolution", "weapon": "magic_bolt", "evolution": "starbreaker_bolt"},
		{"type": "evolution", "weapon": "magic_bolt", "evolution": "starbreaker_bolt"}
	]
	system.process(state, 0.1, events)
	t.assert_eq(int(state.v2_momentum_trigger_counts.get("evolution", 0)), 1, "same evolution should count once")
	t.assert_eq(int(state.v2_momentum_suppressed_duplicates), 1, "same evolution should increment duplicate suppression")

func test_boss_defeat_duplicate_is_suppressed(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9)
	state.elapsed_seconds = 310.0
	var system = V2MomentumSystemScript.new()
	var events := [
		{"type": "enemy_die", "enemy": "boss_5", "kills": 1},
		{"type": "enemy_die", "enemy": "boss_5", "kills": 1}
	]
	system.process(state, 0.1, events)
	t.assert_eq(int(state.v2_momentum_trigger_counts.get("boss_defeat", 0)), 1, "same boss defeat should count once")
	t.assert_eq(int(state.v2_momentum_suppressed_duplicates), 1, "same boss defeat should increment duplicate suppression")
