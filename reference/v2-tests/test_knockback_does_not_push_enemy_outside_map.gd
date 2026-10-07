extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const KnockbackScript = preload("res://scripts/systems/KnockbackResolver.gd")
const RecoveryScript = preload("res://scripts/systems/EnemyPositionRecoverySystem.gd")

func run(t) -> void:
	test_knockback_stays_walkable(t)
	test_recovery_returns_invalid_enemy_to_floor(t)

func test_knockback_stays_walkable(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771611, "knockback-wall")
	var boundary = _boundary_target(state)
	t.assert_true(boundary.has("position"), "test should find a walkable boundary cell")
	if not boundary.has("position"):
		return
	var enemy = state.acquire_enemy(["slime", state.enemy_defs.get("slime", {}), boundary["position"], 0, 1.0])
	state.enemies.append(enemy)
	var events: Array = []
	KnockbackScript.new().apply(state, enemy, boundary["direction"], 360.0, events, "test_wall")
	t.assert_true(state.is_walkable_position(enemy.position, enemy.radius), "knockback should not leave enemy outside walkable floor")

func test_recovery_returns_invalid_enemy_to_floor(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771612, "enemy-recovery")
	var enemy = state.acquire_enemy(["slime", state.enemy_defs.get("slime", {}), Vector2(-5000, -5000), 0, 1.0])
	state.enemies.append(enemy)
	var events: Array = []
	t.assert_true(RecoveryScript.new().recover_enemy(state, enemy, events, "test_invalid"), "invalid enemy should be recovered")
	t.assert_true(state.is_walkable_position(enemy.position, enemy.radius), "recovered enemy should be on walkable floor")
	t.assert_true(enemy.special_phase == "" and enemy.charge_timer <= 0.0, "recovery should clear stuck enemy action state")

func _boundary_target(state) -> Dictionary:
	var tile = state.tile_collision_system
	var directions = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for raw_cell in state.map_data.get("walkable_cells", []):
		var parts = String(raw_cell).split(",")
		if parts.size() != 2:
			continue
		var cell = Vector2i(int(parts[0]), int(parts[1]))
		var pos = tile.cell_to_world(state.map_data, cell)
		if not state.is_walkable_position(pos, 18.0):
			continue
		for dir in directions:
			var next = cell + dir
			if not tile.is_walkable(state.map_data, tile.cell_to_world(state.map_data, next), 18.0):
				return {"position": pos, "direction": Vector2(dir)}
	return {}
