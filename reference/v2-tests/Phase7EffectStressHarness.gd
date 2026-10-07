extends RefCounted
class_name Phase7EffectStressHarness

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const ProjectileScript = preload("res://scripts/core/Projectile.gd")
const GemScript = preload("res://scripts/core/ExpGem.gd")
const BudgetScript = preload("res://scripts/systems/VisualEffectBudgetSystem.gd")
const SelectorScript = preload("res://scripts/systems/ProjectileRenderSelectionSystem.gd")
const FIXTURE_PATH := "res://tests/fixtures/ios_effect_stress_scenarios.json"

func run(output_stem: String, scenario_filter: String = "", profile_id: String = "ios_standard") -> Dictionary:
	var fixture: Dictionary = _json(FIXTURE_PATH)
	var results: Array = []
	for scenario in fixture.get("scenarios", []):
		if scenario_filter != "" and String(scenario.get("id", "")) != scenario_filter:
			continue
		results.append(_run_scenario(fixture, scenario, profile_id))
	var summary := _aggregate(fixture, results)
	_write(output_stem, summary)
	return summary

func _run_scenario(fixture: Dictionary, scenario: Dictionary, profile_id: String) -> Dictionary:
	print("[phase7] scenario start: ", String(scenario.get("id", "")))
	var state = StateScript.new()
	var seed := int(fixture.get("seed", 70707)) + String(scenario.get("id", "")).hash()
	state.start_new_run(seed)
	state.configure_render_profile(profile_id, true)
	state.player_position = state.field_size * 0.5
	state.camera_position = state.player_position
	var weapons: Array = scenario.get("weapons", [])
	_populate_simulation(state, fixture, weapons)
	print("[phase7] populated: enemies=", state.enemies.size(), " projectiles=", state.projectiles.size(), " gems=", state.gems.size())
	var before_hash := _simulation_hash(state)
	var budget = BudgetScript.new()
	budget.set_profile(profile_id)
	budget.configure_metrics(true)
	var selector = SelectorScript.new()
	var duration := int(fixture.get("duration_seconds", 20))
	var sample_hz := 2
	var frames := duration * sample_hz
	var commands_per_frame := int(scenario.get("commands_per_frame", 32))
	var baseline_frame_times: Array[float] = _run_phase6_equivalent_baseline(
		state,
		weapons,
		commands_per_frame,
		frames
	)
	var frame_times: Array[float] = []
	var critical_created := 0
	var critical_rendered := 0
	var peak_rendered_projectiles := 0
	var peak_rendered_effects := 0
	for frame in range(frames):
		var started := Time.get_ticks_usec()
		state.elapsed_seconds = float(frame) / float(sample_hz)
		for command_index in range(commands_per_frame):
			var weapon_id := String(weapons[command_index % weapons.size()])
			var cell := command_index % 6
			var pos: Vector2 = state.player_position + Vector2(float(cell % 3) * 24.0, float(cell / 3) * 24.0)
			state.add_hit_flash({
				"pos": pos,
				"source": weapon_id,
				"life": 0.18,
				"radius": 34.0 + float(command_index % 5) * 7.0,
				"evolved": true,
				"signature": command_index % 4 == 0,
			})
		state.add_hit_flash({
			"pos": state.player_position,
			"source": "boss_warning",
			"effect_kind": "boss_warning",
			"life": 0.18,
			"radius": 96.0,
			"critical": true,
		})
		critical_created += 1
		var rendered_projectiles: Array = selector.select(
			state.projectiles,
			state.camera_position,
			Vector2(1280, 720),
			budget.rendered_limit("projectiles", 190)
		)
		for projectile in rendered_projectiles:
			state.weapon_effect(projectile.kind)
		var rendered_effects: Array = budget.select_visual_items(
			state.hit_flashes,
			state.camera_position,
			Vector2(1280, 720),
			budget.rendered_limit("effects", 96)
		)
		peak_rendered_projectiles = maxi(peak_rendered_projectiles, rendered_projectiles.size())
		peak_rendered_effects = maxi(peak_rendered_effects, rendered_effects.size())
		var critical_visible_this_frame := false
		for command in rendered_effects:
			if int(command.get("priority", 2)) == 0:
				critical_visible_this_frame = true
		if critical_visible_this_frame:
			critical_rendered += 1
		if frame % 12 == 11:
			_release_visuals(state)
		frame_times.append(float(Time.get_ticks_usec() - started) / 1000.0)
	var after_hash := _simulation_hash(state)
	print("[phase7] scenario complete: ", String(scenario.get("id", "")))
	var command_metrics: Dictionary = state.visual_effect_command_buffer.snapshot()
	var raw_commands := int(command_metrics.get("created", 0))
	var accepted_commands := int(command_metrics.get("accepted", 0))
	var coalesced_commands := int(command_metrics.get("coalesced", 0))
	var rejected_commands := int(command_metrics.get("rejected", 0))
	var reduction := 1.0 - float(accepted_commands) / maxf(1.0, float(raw_commands))
	var baseline_p95 := _percentile(baseline_frame_times, 0.95)
	var after_p95 := _percentile(frame_times, 0.95)
	return {
		"id": String(scenario.get("id", "")),
		"seed": seed,
		"duration_seconds": duration,
		"enemy_count": state.enemies.size(),
		"simulation_projectiles": state.projectiles.size(),
		"simulation_gems": state.gems.size(),
		"raw_visual_commands": raw_commands,
		"accepted_visual_commands": accepted_commands,
		"coalesced_visual_commands": coalesced_commands,
		"budget_rejected_commands": rejected_commands,
		"visual_command_reduction_ratio": reduction,
		"transient_allocation_proxy_reduction_ratio": reduction,
		"critical_created": critical_created,
		"critical_rendered": critical_rendered,
		"critical_missing": maxi(0, critical_created - critical_rendered),
		"peak_rendered_projectiles": peak_rendered_projectiles,
		"peak_rendered_effects": peak_rendered_effects,
		"frame_time_p50": _percentile(frame_times, 0.50),
		"frame_time_p95": after_p95,
		"frame_time_p99": _percentile(frame_times, 0.99),
		"phase6_equivalent_p95": baseline_p95,
		"p95_improvement_ratio": 1.0 - after_p95 / maxf(0.001, baseline_p95),
		"over_16_67ms": _count_over(frame_times, 16.67),
		"over_33ms": _count_over(frame_times, 33.0),
		"over_100ms": _count_over(frame_times, 100.0),
		"simulation_hash_before": before_hash,
		"simulation_hash_after": after_hash,
		"simulation_parity": before_hash == after_hash,
		"pool": state.pool_manager.health_report(),
	}

func _run_phase6_equivalent_baseline(
		state,
		weapons: Array,
		commands_per_frame: int,
		frames: int
	) -> Array[float]:
	var frame_times: Array[float] = []
	for _frame in range(frames):
		var started := Time.get_ticks_usec()
		var commands: Array = []
		for command_index in range(commands_per_frame):
			var weapon_id := String(weapons[command_index % weapons.size()])
			commands.append({
				"pos": state.player_position + Vector2(float(command_index % 3) * 24.0, float(command_index % 2) * 24.0),
				"source": weapon_id,
				"life": 0.18,
				"radius": 34.0 + float(command_index % 5) * 7.0,
			})
		var copied_projectiles: Array = state.projectiles.duplicate()
		for index in range(mini(190, copied_projectiles.size())):
			var projectile = copied_projectiles[index]
			var definition: Dictionary = state.weapon_defs.get(projectile.kind, {})
			var effect_id := String(definition.get("effect_id", projectile.kind))
			var data: Dictionary = state.weapon_effect_defs.get(effect_id, {})
			var style: Dictionary = data.get("evolved", {}).duplicate(true)
			if not style.is_empty():
				style["screen_priority"] = data.get("screen_priority", 3)
		for command in commands.duplicate():
			if float(command.get("life", 0.0)) <= 0.0:
				commands.erase(command)
		frame_times.append(float(Time.get_ticks_usec() - started) / 1000.0)
	return frame_times

func _populate_simulation(state, fixture: Dictionary, weapons: Array) -> void:
	var enemy_data: Dictionary = state.enemy_defs.get("slime", {})
	for index in range(int(fixture.get("enemy_count", 600))):
		var angle := TAU * float(index) / float(int(fixture.get("enemy_count", 600)))
		var radius := 140.0 + float(index % 24) * 18.0
		state.enemies.append(state.acquire_enemy([
			"slime",
			enemy_data,
			state.player_position + Vector2(cos(angle), sin(angle)) * radius,
			0,
			1.0,
		]))
	for index in range(int(fixture.get("simulation_projectiles", 500))):
		var weapon_id := String(weapons[index % weapons.size()])
		var angle := TAU * float(index % 120) / 120.0
		state.projectiles.append(ProjectileScript.new(
			weapon_id,
			state.player_position + Vector2(cos(angle), sin(angle)) * (60.0 + float(index % 12) * 20.0),
			Vector2(cos(angle), sin(angle)) * 420.0,
			24,
			2,
			4.0,
			9.0,
			48.0,
			true
		))
	for index in range(int(fixture.get("simulation_gems", 1000))):
		var angle := TAU * float(index % 180) / 180.0
		state.gems.append(GemScript.new(
			state.player_position + Vector2(cos(angle), sin(angle)) * (80.0 + float(index % 30) * 16.0),
			2 + index % 10
		))

func _release_visuals(state) -> void:
	for item in state.hit_flashes:
		state.release_runtime("hit_flash", item)
	state.hit_flashes.clear()

func _simulation_hash(state) -> int:
	var projectile_rows: Array = []
	for projectile in state.projectiles:
		projectile_rows.append([projectile.kind, projectile.position, projectile.damage, projectile.lifetime])
	var gem_rows: Array = []
	for gem in state.gems:
		gem_rows.append([gem.position, gem.value, gem.attracting])
	var enemy_rows: Array = []
	for enemy in state.enemies:
		enemy_rows.append([enemy.type, enemy.position, enemy.hp, enemy.boss, enemy.splits])
	return [projectile_rows, gem_rows, enemy_rows, state.rng.snapshot(), state.score, state.exp, state.kills].hash()

func _aggregate(fixture: Dictionary, results: Array) -> Dictionary:
	var all_parity := true
	var total_raw := 0
	var total_accepted := 0
	var total_coalesced := 0
	var total_rejected := 0
	var critical_missing := 0
	var p95_max := 0.0
	var p99_max := 0.0
	var baseline_p95_max := 0.0
	var p95_improvement_min := INF
	var over_100 := 0
	for result in results:
		all_parity = all_parity and bool(result.simulation_parity)
		total_raw += int(result.raw_visual_commands)
		total_accepted += int(result.accepted_visual_commands)
		total_coalesced += int(result.coalesced_visual_commands)
		total_rejected += int(result.budget_rejected_commands)
		critical_missing += int(result.critical_missing)
		p95_max = maxf(p95_max, float(result.frame_time_p95))
		p99_max = maxf(p99_max, float(result.frame_time_p99))
		baseline_p95_max = maxf(baseline_p95_max, float(result.phase6_equivalent_p95))
		p95_improvement_min = minf(p95_improvement_min, float(result.p95_improvement_ratio))
		over_100 += int(result.over_100ms)
	return {
		"ok": all_parity and critical_missing == 0,
		"godot_version": Engine.get_version_info().get("string", ""),
		"renderer": RenderingServer.get_current_rendering_method(),
		"fixture": fixture,
		"scenario_count": results.size(),
		"scenarios": results,
		"raw_visual_commands": total_raw,
		"accepted_visual_commands": total_accepted,
		"coalesced_visual_commands": total_coalesced,
		"budget_rejected_commands": total_rejected,
		"visual_command_reduction_ratio": 1.0 - float(total_accepted) / maxf(1.0, float(total_raw)),
		"transient_allocation_proxy_reduction_ratio": 1.0 - float(total_accepted) / maxf(1.0, float(total_raw)),
		"critical_missing": critical_missing,
		"simulation_parity": all_parity,
		"max_p95_ms": p95_max,
		"max_p99_ms": p99_max,
		"phase6_equivalent_max_p95_ms": baseline_p95_max,
		"minimum_p95_improvement_ratio": p95_improvement_min if results.size() > 0 else 0.0,
		"over_100ms": over_100,
	}

func _percentile(values: Array[float], ratio: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(ceil(float(sorted.size()) * ratio)) - 1, 0, sorted.size() - 1)])

func _count_over(values: Array[float], threshold: float) -> int:
	var count := 0
	for value in values:
		if value > threshold:
			count += 1
	return count

func _json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _write(stem: String, summary: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(stem.get_base_dir()))
	var json_file := FileAccess.open("%s.json" % stem, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify(summary, "\t"))
	var markdown := FileAccess.open("%s.md" % stem, FileAccess.WRITE)
	if markdown == null:
		return
	markdown.store_line("# Phase 7 iOS Evolved Effect Stress")
	markdown.store_line("")
	for key in ["scenario_count", "raw_visual_commands", "accepted_visual_commands", "coalesced_visual_commands", "budget_rejected_commands", "visual_command_reduction_ratio", "critical_missing", "simulation_parity", "max_p95_ms", "max_p99_ms", "over_100ms"]:
		markdown.store_line("- %s: %s" % [key, str(summary.get(key, ""))])
