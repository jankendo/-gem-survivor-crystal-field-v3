extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemySpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")

func run(t) -> void:
	test_all_boss_minutes_spawn(t)
	test_boss_pattern_fires_projectiles(t)

func test_all_boss_minutes_spawn(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(710)
	var spawner = EnemySpawnerScript.new()
	for minute in [5, 10, 15, 20, 25, 30]:
		state.elapsed_seconds = float(minute * 60)
		spawner._process_boss_schedule(state, [])
		t.assert_true(state.boss_spawned_minutes.has(minute), "boss should spawn at minute %d" % minute)

func test_boss_pattern_fires_projectiles(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(711)
	var spawner = EnemySpawnerScript.new()
	var boss = spawner.spawn_boss(state, "boss_30", [])
	boss.action_timer = 0.0
	var events: Array = []
	spawner._process_boss_special(state, boss, 0.2, events)
	t.assert_true(state.enemy_projectiles.size() > 0, "30-minute boss should fire bullet pattern")
	t.assert_true(events.size() > 0, "boss pattern should emit events")
