extends RefCounted

const FieldGimmickSystemScript = preload("res://scripts/systems/FieldGimmickSystem.gd")
const ShockStackSystemScript = preload("res://scripts/systems/ShockStackSystem.gd")
const ProjectileScript = preload("res://scripts/core/Projectile.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")

func run(t) -> void:
	test_reflect_crystal_reflects_projectile(t)
	test_lightning_crystal_extends_shock_radius(t)
	test_explosive_vein_explodes(t)
	test_healing_spring_heals(t)
	test_spawn_rift_spawns_enemy(t)
	test_sealed_pillar_opens_when_clear(t)

func _state():
	var state = SurvivorState.new()
	state.start_new_run(3131, "gimmick")
	state.field_gimmicks = []
	return state

func test_reflect_crystal_reflects_projectile(t) -> void:
	var state = _state()
	var system = FieldGimmickSystemScript.new()
	state.field_gimmicks.append({"id": "reflect_crystal", "position": Vector2(100, 100), "radius": 40.0, "hp": 80})
	var p = ProjectileScript.new("magic_bolt", Vector2(130, 100), Vector2(100, 0), 1, 0, 1.0, 8.0, 0.0, false)
	system.reflect_projectile_if_needed(state, p, [])
	t.assert_true(p.velocity.x < 0.0, "reflect crystal should bounce projectile")

func test_lightning_crystal_extends_shock_radius(t) -> void:
	var state = _state()
	state.field_gimmicks.append({"id": "lightning_crystal", "position": Vector2(100, 100), "radius": 40.0, "hp": 90})
	var shock = ShockStackSystemScript.new()
	t.assert_true(shock.nearby_lightning_crystal_multiplier(state, Vector2(120, 100)) > 1.0, "lightning crystal should boost shock radius")

func test_explosive_vein_explodes(t) -> void:
	var state = _state()
	var system = FieldGimmickSystemScript.new()
	var events: Array = []
	state.field_gimmicks.append({"id": "explosive_vein", "position": Vector2(200, 200), "radius": 38.0, "hp": 5})
	system.damage_gimmicks_in_radius(state, Vector2(200, 200), 60.0, 10, events, "magic_bolt")
	t.assert_true(_has_event(events, "gimmick_explosion"), "explosive vein should explode when destroyed")

func test_healing_spring_heals(t) -> void:
	var state = _state()
	var system = FieldGimmickSystemScript.new()
	var events: Array = []
	state.hp = 10
	state.player_position = Vector2(300, 300)
	state.field_gimmicks.append({"id": "healing_spring", "position": Vector2(300, 300), "radius": 38.0, "hp": 9999})
	system.process(state, 0.1, events)
	t.assert_true(state.hp > 10, "healing spring should heal player")

func test_spawn_rift_spawns_enemy(t) -> void:
	var state = _state()
	var system = FieldGimmickSystemScript.new()
	state.elapsed_seconds = 400.0
	state.player_position = Vector2(500, 500)
	state.field_gimmicks.append({"id": "spawn_rift", "position": Vector2(520, 500), "radius": 38.0, "hp": 140})
	system.process(state, 0.1, [])
	t.assert_true(state.enemies.size() > 0, "spawn rift should spawn enemies near player")

func test_sealed_pillar_opens_when_clear(t) -> void:
	var state = _state()
	var system = FieldGimmickSystemScript.new()
	var events: Array = []
	state.elapsed_seconds = 400.0
	state.player_position = Vector2(700, 700)
	state.field_gimmicks.append({"id": "sealed_chest_pillar", "position": Vector2(700, 700), "radius": 38.0, "hp": 120})
	system.process(state, 0.1, events)
	t.assert_true(state.chests.size() > 0 or _has_event(events, "gimmick_open"), "sealed pillar should open when clear")

func _has_event(events: Array, event_type: String) -> bool:
	for event in events:
		if String(event.get("type", "")) == event_type:
			return true
	return false

