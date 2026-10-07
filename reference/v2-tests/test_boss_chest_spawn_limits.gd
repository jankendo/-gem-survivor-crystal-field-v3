extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemySpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")
const WeaponSystemScript = preload("res://scripts/systems/WeaponSystem.gd")

func run(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9106)
	var spawner = EnemySpawnerScript.new()
	var events: Array = []
	state.elapsed_seconds = 300.0
	spawner.process(state, 0.0, events)
	t.assert_eq(_boss_count(state), 1, "boss should appear at 5min")
	state.elapsed_seconds = 600.0
	spawner.process(state, 0.0, events)
	t.assert_eq(_boss_count(state), 1, "boss simultaneous spawn should be blocked")
	var boss = state.active_boss()
	if boss != null:
		WeaponSystemScript.new()._damage_enemy(state, boss, boss.hp + 9999, events, "test", boss.position)
	t.assert_true(state.chests.size() == 1, "boss defeat should guarantee one chest")
	for i in range(5):
		state.add_chest(preload("res://scripts/core/Chest.gd").new(state.player_position + Vector2(i * 10, 0)))
	t.assert_true(state.chests.size() <= 3, "chest cap should still hold after manual add attempts")

func _boss_count(state) -> int:
	var count = 0
	for enemy in state.enemies:
		if enemy.boss:
			count += 1
	return count

