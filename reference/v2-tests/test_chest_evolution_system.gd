extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const WeaponSystemScript = preload("res://scripts/systems/WeaponSystem.gd")
const ChestSystemScript = preload("res://scripts/systems/ChestSystem.gd")

func run(t) -> void:
	test_elite_drops_chest(t)
	test_chest_upgrades_owned_item(t)
	test_magic_bolt_evolves(t)

func _state() :
	var state = SurvivorStateScript.new()
	state.start_new_run(66)
	state.enemies = []
	return state

func test_elite_drops_chest(t) -> void:
	var state = _state()
	var elite = EnemyScript.new("elite", state.enemy_defs.get("elite", {}), state.player_position + Vector2(40, 0))
	elite.hp = 1
	state.enemies.append(elite)
	state.weapons["magic_bolt"] = 8
	WeaponSystemScript.new()._damage_enemy(state, elite, 10, [], "test", elite.position)
	t.assert_true(state.chests.size() == 1, "elite defeat should drop chest")

func test_chest_upgrades_owned_item(t) -> void:
	var state = _state()
	state.weapons["ice_orbit"] = 1
	ChestSystemScript.new().open_chest(state, [])
	var upgraded = int(state.weapons.get("magic_bolt", 1)) > 1 or int(state.weapons.get("ice_orbit", 1)) > 1
	t.assert_true(upgraded, "chest should upgrade owned weapon")

func test_magic_bolt_evolves(t) -> void:
	var state = _state()
	state.elapsed_seconds = 300.0
	state.weapons["magic_bolt"] = 8
	state.passives["might"] = 3
	ChestSystemScript.new().open_chest(state, [])
	t.assert_true(state.evolved_magic_bolt, "magic bolt should evolve from chest when conditions are met")
