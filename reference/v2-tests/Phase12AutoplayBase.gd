extends SceneTree

const H12 = preload("res://tests/helpers/Phase12TestScenarios.gd")
const H11 = preload("res://tests/helpers/Phase11TestScenarios.gd")
const Phase7Harness = preload("res://tests/Phase7EffectStressHarness.gd")
const Phase12Performance = preload("res://tests/Phase12PerformanceHarness.gd")
const StateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const WeaponSystemScript = preload("res://scripts/systems/WeaponSystem.gd")
const ComboExecutorScript = preload("res://scripts/systems/ComboAttackExecutor.gd")

var failures: Array = []
var assertions := 0

func scenario_id() -> String:
	return ""

func _initialize() -> void:
	var id := scenario_id()
	var started := Time.get_ticks_usec()
	match id:
		"all_evolved_weapon_effects":
			var result: Dictionary = Phase7Harness.new().run("res://test-output/phase12/autoplay/all_evolved_weapon_effects", "", "ios_ultra")
			assert_true(bool(result.ok), "all evolved effect fixture")
			assert_eq(int(result.critical_missing), 0, "all evolved critical visuals")
		"all_16_combo_patterns":
			_all_combo_pattern_parity()
		"combo_3pair_hell":
			H11.new().weapon_combo_performance(self)
			H12.new().ios_ultra_combo_damage_parity(self)
			H12.new().ios_ultra_enemy_count_parity(self)
		"heaven_loot":
			H11.new().warp_heaven_loot_quantity(self)
			H11.new().warp_reward_safe_placement(self)
		"enemy_600":
			H12.new().enemy_batch_visual_parity(self)
			H12.new().enemy_batch_performance(self)
			var result: Dictionary = Phase12Performance.new().run("res://test-output/phase12/autoplay/enemy_600_performance")
			assert_true(bool(result.ok), "600 enemy performance fixture")
		"warp_roundtrip":
			H11.new().warp_normal_room_flow(self)
			H11.new().weapon_combo_determinism(self)
		"proxy_15min":
			_fifteen_minute_proxy()
		"standard_ultra_deterministic":
			H12.new().ios_ultra_simulation_parity(self)
			H12.new().ios_ultra_rng_parity(self)
			H12.new().ios_ultra_damage_parity(self)
			H12.new().ios_ultra_combo_damage_parity(self)
			H12.new().ios_ultra_enemy_count_parity(self)
			H12.new().ios_ultra_reward_parity(self)
		_:
			failures.append("Unknown Phase 12 autoplay scenario: %s" % id)
	var report := {
		"scenario": id,
		"seed": 121212,
		"ok": failures.is_empty(),
		"assertions": assertions,
		"failures": failures,
		"duration_ms": float(Time.get_ticks_usec() - started) / 1000.0,
	}
	var directory := "res://test-output/phase12/autoplay"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file := FileAccess.open("%s/%s.json" % [directory, id], FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
	print("Phase 12 autoplay ", id, ": ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func _all_combo_pattern_parity() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapon_combo_attacks.json"))
	var combos: Array = parsed.get("combos", [])
	assert_eq(combos.size(), 16, "all sixteen combo patterns loaded")
	for index in range(combos.size()):
		var combo: Dictionary = combos[index]
		var standard := _execute_combo(combo, "ios_standard", 121212 + index)
		var ultra := _execute_combo(combo, "ios_ultra", 121212 + index)
		assert_true(bool(standard.fired) and bool(ultra.fired), "%s fires" % String(combo.get("id", "combo")))
		assert_eq(ultra.simulation, standard.simulation, "%s standard/ultra simulation" % String(combo.get("id", "combo")))

func _execute_combo(combo: Dictionary, profile_id: String, seed: int) -> Dictionary:
	var state = StateScript.new()
	state.start_new_run(seed, "phase12-all-combo")
	state.configure_render_profile(profile_id)
	state.player_position = Vector2(3200, 3200)
	state.camera_position = state.player_position
	state.weapons = {String(combo.weapon_a): 8, String(combo.weapon_b): 8}
	state.weapon_combo_runtime = {"damage": {}, "activations": {String(combo.id): 0}}
	for enemy_index in range(40):
		var data := {"hp": 1000000, "damage": 10, "radius": 18.0, "elite": enemy_index % 13 == 0}
		state.enemies.append(EnemyScript.new("slime", data, state.player_position + Vector2(enemy_index % 8 * 52 - 182, enemy_index / 8 * 54 - 108)))
	var weapon = WeaponSystemScript.new()
	weapon.enemy_grid.rebuild(state.enemies)
	var result: Dictionary = ComboExecutorScript.new().execute(state, combo, [], weapon)
	return {"fired": result.get("fired", false), "simulation": _simulation_signature(state)}

func _fifteen_minute_proxy() -> void:
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapon_combo_attacks.json"))
	var combo: Dictionary = parsed.get("combos", [])[1]
	var standard = _proxy_state("ios_standard", combo)
	var ultra = _proxy_state("ios_ultra", combo)
	var standard_weapon = WeaponSystemScript.new()
	var ultra_weapon = WeaponSystemScript.new()
	standard_weapon.enemy_grid.rebuild(standard.enemies)
	ultra_weapon.enemy_grid.rebuild(ultra.enemies)
	var executor = ComboExecutorScript.new()
	for second in range(900):
		standard.elapsed_seconds = float(second + 1)
		ultra.elapsed_seconds = float(second + 1)
		standard.weapon_combo_runtime.activations[String(combo.id)] = second
		ultra.weapon_combo_runtime.activations[String(combo.id)] = second
		executor.execute(standard, combo, [], standard_weapon)
		executor.execute(ultra, combo, [], ultra_weapon)
	assert_eq(standard.elapsed_seconds, 900.0, "15 minute proxy elapsed")
	assert_eq(_simulation_signature(ultra), _simulation_signature(standard), "15 minute standard/ultra parity")

func _proxy_state(profile_id: String, combo: Dictionary):
	var state = StateScript.new()
	state.start_new_run(121212, "phase12-15min")
	state.configure_render_profile(profile_id)
	state.player_position = Vector2(3200, 3200)
	state.weapons = {String(combo.weapon_a): 8, String(combo.weapon_b): 8}
	state.weapon_combo_runtime = {"damage": {}, "activations": {String(combo.id): 0}}
	for index in range(80):
		state.enemies.append(EnemyScript.new("slime", {"hp": 100000000, "damage": 10, "radius": 18.0}, state.player_position + Vector2(index % 10 * 42 - 189, index / 10 * 42 - 147)))
	return state

func _simulation_signature(state) -> int:
	var enemies: Array = []
	for enemy in state.enemies:
		enemies.append([enemy.type, enemy.position, enemy.hp, enemy.slow_timer])
	var projectiles: Array = []
	for projectile in state.projectiles:
		projectiles.append([projectile.kind, projectile.position, projectile.velocity, projectile.damage, projectile.pierce_left, projectile.lifetime])
	var bombs: Array = []
	for bomb in state.bombs:
		bombs.append([bomb.position, bomb.damage, bomb.lifetime, bomb.radius, bomb.splash_radius])
	return [enemies, projectiles, bombs, state.damage_by_category, state.weapon_combo_runtime.get("damage", {}), state.rng.snapshot(), state.score, state.exp, state.kills].hash()

func assert_true(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)

func assert_eq(actual, expected, message: String) -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
