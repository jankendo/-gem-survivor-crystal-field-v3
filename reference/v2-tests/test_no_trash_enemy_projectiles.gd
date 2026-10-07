extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const SpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const PolicyScript = preload("res://scripts/systems/EnemyProjectilePolicySystem.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(99117, "no-trash-projectiles")
	var spawner = SpawnerScript.new()
	var policy = PolicyScript.new()
	var events: Array = []
	for enemy_id in ["shooter", "crystal_sniper"]:
		state.enemies.clear()
		state.enemy_projectiles.clear()
		var enemy = EnemyScript.new(enemy_id, state.enemy_defs[enemy_id], state.player_position + Vector2(220, 0))
		enemy.action_timer = 0.0
		state.enemies.append(enemy)
		for i in range(80):
			spawner.process_enemies(state, 0.05, events)
		t.assert_eq(state.enemy_projectiles.size(), 0, "%s must never create a projectile" % enemy_id)
		t.assert_true(not policy.can_emit_projectile(enemy), "%s must be classified as trash" % enemy_id)
	var boss_data: Dictionary = state.boss_defs.values()[0].duplicate(true)
	boss_data["boss"] = true
	boss_data["elite"] = true
	var boss = EnemyScript.new("policy_boss", boss_data, state.player_position + Vector2(220, 0))
	t.assert_true(policy.can_emit_projectile(boss), "boss projectiles must remain allowed")
