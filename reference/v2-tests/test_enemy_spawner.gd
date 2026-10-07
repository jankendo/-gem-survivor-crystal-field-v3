extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemySpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")

func run(t) -> void:
	test_spawn_count_increases(t)
	test_bat_after_one_minute(t)
	test_golem_after_three_and_half_minutes(t)
	test_elite_after_five_minutes(t)

func test_spawn_count_increases(t) -> void:
	var spawner = EnemySpawnerScript.new()
	t.assert_true(spawner.spawn_count(300.0) > spawner.spawn_count(10.0), "enemy density should increase over time")

func test_bat_after_one_minute(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(55)
	state.elapsed_seconds = 60.0
	t.assert_true(_can_pick(state, "bat"), "bat should appear after 1 minute")

func test_golem_after_three_and_half_minutes(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(56)
	state.elapsed_seconds = 210.0
	t.assert_true(_can_pick(state, "golem"), "golem should appear after 3.5 minutes")

func test_elite_after_five_minutes(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(57)
	state.elapsed_seconds = 300.0
	t.assert_true(_can_pick(state, "elite"), "elite should appear after 5 minutes")

func _can_pick(state, enemy_type: String) -> bool:
	var spawner = EnemySpawnerScript.new()
	for i in range(120):
		if spawner.pick_enemy_type(state) == enemy_type:
			return true
	return false
