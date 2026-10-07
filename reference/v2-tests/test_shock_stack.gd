extends RefCounted

const ShockStackSystemScript = preload("res://scripts/systems/ShockStackSystem.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")

func run(t) -> void:
	test_lightning_adds_shock_stack(t)
	test_three_stacks_trigger_explosion(t)
	test_lightning_crystal_boosts_explosion_radius(t)

func _state():
	var state = SurvivorState.new()
	state.start_new_run(6060, "shock")
	state.enemies = []
	return state

func test_lightning_adds_shock_stack(t) -> void:
	var state = _state()
	var enemy = EnemyScript.new("slime", state.enemy_defs["slime"], Vector2(100, 100))
	state.enemies.append(enemy)
	ShockStackSystemScript.new().apply_lightning_hit(state, enemy, 10, enemy.position, [])
	t.assert_eq(enemy.shock_stacks, 1, "lightning should add shock stack")

func test_three_stacks_trigger_explosion(t) -> void:
	var state = _state()
	var enemy = EnemyScript.new("slime", state.enemy_defs["slime"], Vector2(100, 100))
	enemy.hp = 999
	state.enemies.append(enemy)
	var system = ShockStackSystemScript.new()
	system.apply_lightning_hit(state, enemy, 10, enemy.position, [])
	system.apply_lightning_hit(state, enemy, 10, enemy.position, [])
	system.apply_lightning_hit(state, enemy, 10, enemy.position, [])
	t.assert_true(state.shock_explosions >= 1, "third shock stack should explode")
	t.assert_eq(enemy.shock_stacks, 0, "shock stacks should reset after explosion")

func test_lightning_crystal_boosts_explosion_radius(t) -> void:
	var state = _state()
	state.field_gimmicks = [{"id": "lightning_crystal", "position": Vector2(100, 100), "radius": 40.0}]
	t.assert_true(ShockStackSystemScript.new().nearby_lightning_crystal_multiplier(state, Vector2(110, 100)) >= 1.30, "near lightning crystal should boost radius")

