extends RefCounted

const H = preload("res://tests/helpers/Phase11TestScenarios.gd")
const StateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const GemLifecycleScript = preload("res://scripts/systems/GemLifecycleSystem.gd")
const ComboSystemScript = preload("res://scripts/systems/WeaponComboSystem.gd")
const WeaponSystemScript = preload("res://scripts/systems/WeaponSystem.gd")
const WarpTypeScript = preload("res://scripts/systems/WarpRoomTypeResolver.gd")
const WarpRewardScript = preload("res://scripts/systems/WarpRoomRewardSpawner.gd")
const ChestScript = preload("res://scripts/systems/ChestSystem.gd")
const WarpSystemScript = preload("res://scripts/systems/WarpRoomSystem.gd")
const OUTPUT := "res://test-output/phase11/phase11_performance"

class Collector:
	extends RefCounted
	var failures: Array = []
	var assertions := 0
	func assert_true(condition: bool, message: String) -> void:
		assertions += 1
		if not condition:
			failures.append(message)
	func assert_eq(actual, expected, message: String) -> void:
		assertions += 1
		if actual != expected:
			failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func run(output_stem: String = OUTPUT) -> Dictionary:
	var collector = Collector.new()
	var scenarios = H.new()
	var timings: Dictionary = {}
	for row in [
		["warp_chest_collection", "warp_chest_collection"],
		["room_distribution_10000", "warp_room_type_distribution"],
		["reward_placement_100", "warp_reward_safe_placement"],
		["heaven_loot", "warp_heaven_loot_quantity"],
		["hell_density", "warp_hell_difficulty"],
		["combo_dense_180_frames", "weapon_combo_performance"],
	]:
		var started := Time.get_ticks_usec()
		scenarios.call(String(row[1]), collector)
		timings[String(row[0])] = float(Time.get_ticks_usec() - started) / 1000.0
	var stress := _combo_hell_stress()
	stress["reward_spawn_cpu_ms"] = _reward_spawn_cpu_ms()
	stress["pickup_query_cpu_ms"] = _pickup_query_cpu_ms()
	var summary := {
		"ok": collector.failures.is_empty() and bool(stress.get("ok", false)),
		"seed_contract": "dedicated deterministic streams",
		"assertions": collector.assertions,
		"failures": collector.failures,
		"timings_ms": timings,
		"room_samples": 10000,
		"room_distribution": _distribution_counts(),
		"placement_samples": 100,
		"combo_enemy_fixture": 500,
		"combo_frames": 180,
		"hell_combo_stress": stress,
		"platform_note": "Headless CPU fixture; not iPhone, Metal, thermal, battery, or real-device FPS proof."
	}
	_write(output_stem, summary)
	return summary

func _distribution_counts() -> Dictionary:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/warp_rooms.json"))
	return WarpTypeScript.new().distribution(10000, "distribution", config)

func _reward_spawn_cpu_ms() -> float:
	var state = StateScript.new()
	state.start_new_run(111112, "phase11-reward-micro")
	state.elapsed_seconds = 900.0
	var source: Dictionary = state.map_data.get("rooms", [])[0]
	var cave := source.duplicate(true)
	cave["id"] = "phase11-reward-micro"
	cave["shape"] = "cave_room"
	state.map_data["rooms"] = [cave]
	var warp = WarpSystemScript.new()
	warp.initialize_run(state)
	state.player_position = state.warp_portals[0].get("position", Vector2.ZERO)
	warp.process_entry(state, [])
	state.warp_room_exit_position = state.player_position + Vector2(0, 250)
	var portal := {
		"room_id": "reward-micro",
		"kind": "heaven",
		"reward": {
			"chests": {"min": 6, "max": 6},
			"items": {"min": 12, "max": 12},
			"required_core_count": 1,
			"chest_rarities": [{"id": "normal", "weight": 1.0}],
			"item_pool": ["heal_ore", "magnet_ore", "weapon_core", "passive_core"]
		}
	}
	var started := Time.get_ticks_usec()
	WarpRewardScript.new().spawn(state, portal, [])
	return float(Time.get_ticks_usec() - started) / 1000.0

func _pickup_query_cpu_ms() -> float:
	var state = StateScript.new()
	state.start_new_run(111113, "phase11-pickup-micro")
	var chest_system = ChestScript.new()
	chest_system.drop_chest(state, state.player_position, [], "normal", "phase11-micro")
	state.player_position = state.chests[0].position
	var started := Time.get_ticks_usec()
	chest_system.process_pickups(state, [], 1.0 / 60.0)
	return float(Time.get_ticks_usec() - started) / 1000.0

func _combo_hell_stress() -> Dictionary:
	var state = StateScript.new()
	state.start_new_run(111111, "phase11-hell-combo")
	state.weapons = {
		"magic_bolt": 8, "bomb_seed": 8,
		"ice_orbit": 8, "thunder_chain": 8,
		"blade_fan": 8, "frost_wall": 8
	}
	state.player_position = Vector2(3300, 3300)
	state.camera_position = state.player_position
	for index in range(500):
		var elite := index % 50 == 0
		var split := index % 37 == 0
		var data := {
			"hp": 100000,
			"damage": 18,
			"radius": 28.0 if elite else 18.0,
			"elite": elite,
			"splits": 2 if split else 0,
			"split_type": "slime" if split else ""
		}
		var pos: Vector2 = state.player_position + Vector2(index % 25 * 30 - 360, index / 25 * 30 - 285)
		state.enemies.append(EnemyScript.new("elite" if elite else ("splitter" if split else "slime"), data, pos))
	state.enemies.append(EnemyScript.new("slime_king", {
		"hp": 500000, "damage": 30, "radius": 54.0, "boss": true, "elite": true,
		"behavior": "summoner", "summon_type": "slime"
	}, state.player_position + Vector2(240, 0)))
	var lifecycle = GemLifecycleScript.new()
	for index in range(1200):
		lifecycle.spawn(state, state.player_position + Vector2(index % 40 * 14 - 280, index / 40 * 14 - 210), 1 + index % 7)
	var weapon = WeaponSystemScript.new()
	weapon.enemy_grid.rebuild(state.enemies)
	var combos = ComboSystemScript.new()
	combos.initialize(state)
	var frame_times: Array[float] = []
	var damage_before := int(state.damage_by_category.get("weapon_combo", 0))
	var rng_before: int = state.rng.stream_seed("weapon_combo_pattern", "phase11-hash")
	for frame in range(180):
		for combo_id in state.weapon_combo_runtime.get("active", {}).keys():
			state.weapon_combo_runtime.cooldowns[combo_id] = 0.0
		var started := Time.get_ticks_usec()
		combos.process(state, 1.0 / 60.0, [], weapon)
		frame_times.append(float(Time.get_ticks_usec() - started) / 1000.0)
	var combo_damage := int(state.damage_by_category.get("weapon_combo", 0)) - damage_before
	var tracked_damage := 0
	for value in state.weapon_combo_runtime.get("damage", {}).values():
		tracked_damage += int(value)
	var rng_after: int = state.rng.stream_seed("weapon_combo_pattern", "phase11-hash")
	var pool: Dictionary = state.pool_manager.health_report()
	return {
		"ok": _count_over(frame_times, 100.0) == 0 and combo_damage == tracked_damage and rng_before == rng_after,
		"seed": 111111,
		"enemy_count": state.enemies.size(),
		"elite_count": 11,
		"boss_count": 1,
		"split_archetype_count": 14,
		"gem_count": state.gems.size(),
		"active_combo_count": state.weapon_combo_runtime.get("active", {}).size(),
		"frame_p50_ms": _percentile(frame_times, 0.50),
		"frame_p95_ms": _percentile(frame_times, 0.95),
		"frame_p99_ms": _percentile(frame_times, 0.99),
		"frame_max_ms": _max(frame_times),
		"over_33ms": _count_over(frame_times, 33.0),
		"over_100ms": _count_over(frame_times, 100.0),
		"combo_resolve_cpu_ms": float(state.weapon_combo_runtime.get("resolve_cpu_usec", 0)) / 1000.0,
		"combo_attack_cpu_ms": float(state.weapon_combo_runtime.get("attack_cpu_usec", 0)) / 1000.0,
		"combo_visual_cpu_ms": 0.0,
		"reward_spawn_cpu_ms": 0.0,
		"pickup_query_cpu_ms": 0.0,
		"temporary_allocation_proxy": state.projectiles.size() + state.effect_lines.size() + state.hit_flashes.size(),
		"projectile_count": state.projectiles.size(),
		"visual_command_count": int(state.weapon_combo_runtime.get("visual_commands", 0)),
		"pool": pool,
		"damage_hash": state.weapon_combo_runtime.get("damage", {}).hash(),
		"damage_parity": combo_damage == tracked_damage,
		"rng_hash_before": rng_before,
		"rng_hash_after": rng_after,
		"rng_parity": rng_before == rng_after
	}

func _percentile(values: Array[float], ratio: float) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[clampi(int(floor(float(sorted.size() - 1) * ratio)), 0, sorted.size() - 1)] if not sorted.is_empty() else 0.0

func _max(values: Array[float]) -> float:
	var result := 0.0
	for value in values:
		result = maxf(result, value)
	return result

func _count_over(values: Array[float], limit: float) -> int:
	var count := 0
	for value in values:
		if value > limit:
			count += 1
	return count

func _write(stem: String, summary: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(stem.get_base_dir()))
	var json := FileAccess.open("%s.json" % stem, FileAccess.WRITE)
	if json != null:
		json.store_string(JSON.stringify(summary, "\t"))
	var markdown := FileAccess.open("%s.md" % stem, FileAccess.WRITE)
	if markdown != null:
		markdown.store_line("# Phase 11 Combo and Warp Stress")
		markdown.store_line("")
		markdown.store_line(String(summary.platform_note))
		for key in summary.keys():
			if key != "platform_note":
				markdown.store_line("- %s: %s" % [key, str(summary[key])])
