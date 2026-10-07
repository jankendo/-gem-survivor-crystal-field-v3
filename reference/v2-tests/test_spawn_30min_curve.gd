extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemySpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")

func run(t) -> void:
	test_spawn_curve_reaches_30_minutes(t)
	test_new_enemy_unlocks(t)
	test_boss_spawns_at_five_minutes(t)

func test_spawn_curve_reaches_30_minutes(t) -> void:
	var spawner = EnemySpawnerScript.new()
	t.assert_true(spawner.spawn_count(1800.0) > spawner.spawn_count(60.0), "30-minute spawn count should be higher than early run")
	t.assert_true(spawner.spawn_interval(1800.0) < spawner.spawn_interval(60.0), "30-minute spawn interval should be shorter")

func test_new_enemy_unlocks(t) -> void:
	var unlocks = {
		"splitter": 420.0,
		"charger": 600.0,
		"shooter": 720.0,
		"shield_bug": 900.0,
		"healer": 1080.0,
		"crystal_golem": 1200.0,
		"reaper": 1500.0
	}
	for enemy_type in unlocks.keys():
		var state = SurvivorStateScript.new()
		state.start_new_run(610 + int(unlocks[enemy_type]))
		state.elapsed_seconds = float(unlocks[enemy_type])
		t.assert_true(_can_pick(state, String(enemy_type)), "%s should unlock at %.0f seconds" % [enemy_type, float(unlocks[enemy_type])])

func test_boss_spawns_at_five_minutes(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(609)
	state.elapsed_seconds = 300.0
	var events: Array = []
	EnemySpawnerScript.new().process(state, 0.1, events)
	t.assert_true(state.boss_spawned_minutes.has(5), "5-minute boss should be marked spawned")
	var found = false
	for enemy in state.enemies:
		if enemy.boss:
			found = true
	t.assert_true(found, "boss enemy should be in enemy list")

func _can_pick(state, enemy_type: String) -> bool:
	var spawner = EnemySpawnerScript.new()
	for i in range(240):
		if spawner.pick_enemy_type(state) == enemy_type:
			return true
	return false

