extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const SpawnerScript = preload("res://scripts/systems/EnemySpawner.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const WeaponScript = preload("res://scripts/systems/WeaponSystem.gd")
const PolicyScript = preload("res://scripts/systems/EnemyProjectilePolicySystem.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771603, "no-normal-specials")
	var spawner = SpawnerScript.new()
	var policy = PolicyScript.new()
	for enemy_id in ["shooter", "crystal_sniper"]:
		state.enemies.clear()
		state.enemy_projectiles.clear()
		state.enemy_attack_warnings.clear()
		var enemy = EnemyScript.new(enemy_id, state.enemy_defs[enemy_id], state.player_position + Vector2(220, 0))
		enemy.action_timer = 0.0
		state.enemies.append(enemy)
		var events: Array = []
		for i in range(120):
			spawner.process_enemies(state, 0.05, events)
		t.assert_eq(state.enemy_projectiles.size(), 0, "%s must not create enemy projectiles" % enemy_id)
		for event in events:
			t.assert_true(not String(event.get("type", "")).begins_with("enemy_ground_attack"), "%s must not create ground-target attacks" % enemy_id)
		t.assert_true(not policy.can_emit_projectile(enemy), "%s should be projectile-blocked as trash" % enemy_id)
		t.assert_true(not policy.can_emit_ground_attack(enemy), "%s should be ground-attack-blocked as trash" % enemy_id)
	state.enemies.clear()
	state.bombs.clear()
	var bomber = EnemyScript.new("bomber", state.enemy_defs["bomber"], state.player_position + Vector2(80, 0))
	state.enemies.append(bomber)
	WeaponScript.new()._damage_enemy(state, bomber, 9999, [], "magic_bolt", bomber.position)
	t.assert_eq(state.bombs.size(), 0, "normal bomber must not leave bombs or explosions")
