extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const WeaponSystemScript = preload("res://scripts/systems/WeaponSystem.gd")

func run(t) -> void:
	test_magic_bolt_targets_nearest(t)
	test_ice_orbit_damages_nearby(t)
	test_thunder_chain_hits_multiple(t)
	test_bomb_seed_explodes(t)

func _state() :
	var state = SurvivorStateScript.new()
	state.start_new_run(22)
	state.enemies = []
	return state

func _enemy(state, enemy_type: String, pos: Vector2) :
	return EnemyScript.new(enemy_type, state.enemy_defs.get(enemy_type, {}), pos)

func test_magic_bolt_targets_nearest(t) -> void:
	var state = _state()
	state.enemies.append(_enemy(state, "slime", state.player_position + Vector2(120, 0)))
	WeaponSystemScript.new().process(state, 0.7, [])
	t.assert_true(state.projectiles.size() > 0, "magic bolt should create projectile")
	t.assert_true((state.projectiles[0].velocity.normalized()).dot(Vector2.RIGHT) > 0.8, "projectile should aim toward nearest enemy")

func test_ice_orbit_damages_nearby(t) -> void:
	var state = _state()
	state.weapons["ice_orbit"] = 1
	var enemy = _enemy(state, "slime", state.player_position + Vector2(80, 0))
	state.enemies.append(enemy)
	WeaponSystemScript.new().process(state, 0.3, [])
	t.assert_true(enemy.hp < enemy.max_hp, "ice orbit should damage nearby enemy")

func test_thunder_chain_hits_multiple(t) -> void:
	var state = _state()
	state.weapons["thunder_chain"] = 4
	var a = _enemy(state, "slime", state.player_position + Vector2(100, 0))
	var b = _enemy(state, "slime", state.player_position + Vector2(170, 0))
	state.enemies.append(a)
	state.enemies.append(b)
	WeaponSystemScript.new().process(state, 1.5, [])
	t.assert_true(a.hp < a.max_hp and b.hp < b.max_hp, "thunder chain should hit chained enemies")

func test_bomb_seed_explodes(t) -> void:
	var state = _state()
	state.weapons["bomb_seed"] = 3
	var enemy = _enemy(state, "slime", state.player_position + Vector2(70, 0))
	state.enemies.append(enemy)
	var system = WeaponSystemScript.new()
	system.process(state, 2.5, [])
	for bomb in state.bombs:
		bomb.position = enemy.position
	system.process(state, 1.0, [])
	t.assert_true(state.enemies.size() == 0 or enemy.hp < enemy.max_hp, "bomb seed should explode and damage enemy")
