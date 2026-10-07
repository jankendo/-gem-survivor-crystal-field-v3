extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const SpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(50501)
	state.balance_data["max_enemies"] = 3
	var originals: Array = []
	for i in range(3):
		var enemy = state.acquire_enemy(["slime", state.enemy_defs.get("slime", {}), state.player_position + Vector2(i * 30, 0), 0, 1.0])
		state.enemies.append(enemy)
		originals.append(enemy)
	var boss_id := String(state.boss_defs.keys()[0])
	var events: Array = []
	var boss = SpawnerScript.new().spawn_boss(state, boss_id, events, 5)
	t.assert_true(boss != null, "boss should spawn even when runtime enemy list is full")
	t.assert_eq(state.enemies.size(), 4, "boss spawn should not delete existing enemies")
	for enemy in originals:
		t.assert_true(state.enemies.has(enemy), "boss spawn should preserve every existing enemy")
	t.assert_true(events.any(func(event): return String(event.get("type", "")) == "boss_spawn"), "boss spawn event should be emitted")
