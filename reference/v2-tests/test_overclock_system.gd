extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const OverclockSystemScript = preload("res://scripts/systems/OverclockSystem.gd")
const WeaponSystemScript = preload("res://scripts/systems/WeaponSystem.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")

func run(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9108)
	state.weapons["magic_bolt"] = 8
	state.evolved_weapons["magic_bolt"] = "starbreaker_bolt"
	state.evolved_weapon_count = 1
	state.last_evolution_seconds = 300.0
	state.elapsed_seconds = 420.0
	var system = OverclockSystemScript.new()
	var events: Array = []
	t.assert_true(system.apply_option(state, "magic_bolt", "meteor_swarm", events), "overclock should apply to evolved weapon")
	t.assert_true(not system.apply_option(state, "magic_bolt", "meteor_swarm", events), "same overclock should not duplicate")
	t.assert_true(system.apply_option(state, "magic_bolt", "supernova", events), "second overclock should apply")
	t.assert_true(not system.apply_option(state, "magic_bolt", "comet_orbit", events), "third overclock should be blocked")
	state.enemies.append(EnemyScript.new("slime", state.enemy_defs.get("slime", {}), state.player_position + Vector2(120, 0)))
	WeaponSystemScript.new().process(state, 1.0, events)
	t.assert_true(state.projectiles.size() >= 6, "meteor swarm should increase projectile count")
