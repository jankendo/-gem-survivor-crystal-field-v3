extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const ProfileScript = preload("res://scripts/systems/PerformanceProfileSystem.gd")
const SpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")

func run(t) -> void:
	var base = StateScript.new()
	base.start_new_run(50502)
	var base_enemy_cap := base.max_enemies()
	var profiles := [
		["Windows", "low"],
		["Windows", "standard"],
		["Windows", "high"],
		["iOS", "low"],
		["iOS", "standard"],
		["iOS", "high"]
	]
	for profile in profiles:
		var state = StateScript.new()
		state.start_new_run(50502)
		ProfileScript.new().apply_to_state(state, {"render_quality": profile[1]}, profile[0])
		t.assert_eq(state.max_enemies(), base_enemy_cap, "%s %s profile must not reduce enemy count" % [profile[0], profile[1]])
	var spawner = SpawnerScript.new()
	t.assert_eq(spawner.spawn_count(1800.0), spawner.spawn_count(1800.0), "spawn curve should stay platform independent")
	t.assert_eq(spawner.spawn_interval(1800.0), spawner.spawn_interval(1800.0), "spawn interval should stay platform independent")
