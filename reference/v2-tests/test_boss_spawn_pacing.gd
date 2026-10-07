extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemySpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")

func run(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9102)
	var spawner = EnemySpawnerScript.new()
	var events: Array = []
	state.elapsed_seconds = 300.0
	spawner.process(state, 0.0, events)
	t.assert_eq(_boss_count(state), 1, "5min should spawn one boss")
	var first_boss = state.active_boss()
	state.elapsed_seconds = 600.0
	spawner.process(state, 0.0, events)
	t.assert_eq(_boss_count(state), 1, "10min should not spawn second boss while one is alive")
	t.assert_true(state.boss_enrage_count > 0, "existing boss should enrage instead of duplicate spawning")
	t.assert_true(first_boss.max_hp > int(state.boss_defs["boss_5"].get("hp", 0)), "enraged boss should become tougher")
	state.enemies.clear()
	state.elapsed_seconds = 900.0
	spawner.process(state, 0.0, events)
	t.assert_eq(_boss_count(state), 1, "15min should spawn exactly one boss after previous is gone")
	t.assert_true(state.boss_spawned_minutes.has(5) and state.boss_spawned_minutes.has(10) and state.boss_spawned_minutes.has(15), "boss checkpoints should be tracked once")

func _boss_count(state) -> int:
	var count = 0
	for enemy in state.enemies:
		if enemy.boss:
			count += 1
	return count

