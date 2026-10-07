extends SceneTree

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const WeaponScript = preload("res://scripts/systems/WeaponSystem.gd")

const CANDIDATES := [
	"ice_orbit",
	"blade_fan",
	"corridor_blade",
	"magic_bolt",
	"relic_chain",
	"black_hole",
	"gravity_anchor",
	"frost_wall",
	"rune_gate",
	"mine_lantern"
]

func _initialize() -> void:
	var rows: Array = []
	for weapon_id in CANDIDATES:
		rows.append(_audit_weapon(weapon_id))
	var output := "res://test-output/balance_candidate_runs.json"
	var absolute := ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("could not write candidate balance audit")
		quit(1)
		return
	file.store_string(JSON.stringify({"simulated_seconds": 600, "runs": rows}, "\t"))
	print("Balance candidate audit: ", rows)
	quit(0)

func _audit_weapon(weapon_id: String) -> Dictionary:
	var state = StateScript.new()
	state.start_new_run(99000 + CANDIDATES.find(weapon_id), "audit-%s" % weapon_id)
	state.weapons = {weapon_id: 8}
	state.passives = {
		"might": 3,
		"cooldown": 2,
		"area": 2,
		"projectile_count": 1,
		"magnet": 2,
		"max_hp": 2
	}
	state.weapon_pick_counts[weapon_id] = 1
	state.player_velocity = Vector2.RIGHT * 120.0
	state.max_hp = 999999
	state.hp = 999999
	state.balance_data["max_projectiles"] = 320
	state.balance_data["max_effects"] = 120
	_add_targets(state)
	var weapon_system = WeaponScript.new()
	var events: Array = []
	for tick in range(3000):
		state.elapsed_seconds += 0.2
		weapon_system.process(state, 0.2, events)
		events.clear()
	var damage := int(state.weapon_damage_by_id.get(weapon_id, 0))
	return {
		"weapon_id": weapon_id,
		"damage": damage,
		"dps": float(damage) / 600.0,
		"boss_damage": int(state.boss_damage_by_weapon_id.get(weapon_id, 0)),
		"enemy_damage": int(state.enemy_damage_by_weapon_id.get(weapon_id, 0)),
		"pick_count": 1,
		"level": 8,
		"evolved": false,
		"survived": true
	}

func _add_targets(state) -> void:
	var center: Vector2 = state.player_position
	for ring in range(5):
		var radius := 90.0 + float(ring) * 115.0
		for index in range(12):
			var angle := TAU * float(index) / 12.0 + float(ring) * 0.13
			var enemy = EnemyScript.new("audit", {
				"name_ja": "監査標的",
				"hp": 10000000,
				"speed": 0.0,
				"damage": 0,
				"score": 0,
				"exp": 0,
				"radius": 18.0,
				"boss": ring == 1 and index == 0
			}, center + Vector2.RIGHT.rotated(angle) * radius)
			state.enemies.append(enemy)
