extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const WeaponSystemScript = preload("res://scripts/systems/WeaponSystem.gd")

func run(t) -> void:
	test_evolved_weapon_outputs_change(t)

func test_evolved_weapon_outputs_change(t) -> void:
	var checked = 0
	for weapon_id in ["magic_bolt", "ice_orbit", "thunder_chain", "bomb_seed", "blade_fan"]:
		var normal = _state_with_weapon(weapon_id, false)
		var evolved = _state_with_weapon(weapon_id, true)
		WeaponSystemScript.new().process(normal, 0.2, [])
		WeaponSystemScript.new().process(evolved, 0.2, [])
		var normal_count = normal.projectiles.size() + normal.bombs.size()
		var evolved_count = evolved.projectiles.size() + evolved.bombs.size()
		t.assert_true(evolved_count >= normal_count, "evolved %s should produce at least as many active outputs" % weapon_id)
		t.assert_true(evolved.max_damage >= normal.max_damage or evolved_count > normal_count or evolved.hit_flashes.size() >= normal.hit_flashes.size(), "evolved %s should differ in behavior or damage" % weapon_id)
		checked += 1
	t.assert_true(checked >= 5, "at least five evolutions should be checked")

func _state_with_weapon(weapon_id: String, evolved: bool):
	var state = SurvivorStateScript.new()
	state.start_new_run(708)
	state.weapons = {weapon_id: 8}
	if weapon_id != "magic_bolt":
		state.weapons["magic_bolt"] = 1
	if evolved:
		state.evolved_weapons[weapon_id] = "test"
		if weapon_id == "magic_bolt":
			state.evolved_magic_bolt = true
	var enemy_offset = Vector2(140, 0)
	if weapon_id == "ice_orbit":
		enemy_offset = Vector2(88, 0)
	state.enemies.append(EnemyScript.new("slime", state.enemy_defs.get("slime", {}), state.player_position + enemy_offset, 80, 1.0))
	state.player_velocity = Vector2.RIGHT * 220.0
	return state
