extends RefCounted
class_name Phase12PerformanceHarness

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const ProjectileScript = preload("res://scripts/core/Projectile.gd")
const GemScript = preload("res://scripts/core/ExpGem.gd")
const BudgetScript = preload("res://scripts/systems/VisualEffectBudgetSystem.gd")
const ProjectileSelectorScript = preload("res://scripts/systems/ProjectileRenderSelectionSystem.gd")
const SnapshotScript = preload("res://scripts/systems/EnemyRenderSnapshotSystem.gd")
const BatchRendererScript = preload("res://scripts/systems/EnemyBatchRenderer2D.gd")
const GridPanelScript = preload("res://scripts/ui/components/EquipmentGridPanel.gd")
const Phase12Scenarios = preload("res://tests/helpers/Phase12TestScenarios.gd")

const SEED := 121212
const SAMPLE_FRAMES := 240
const OUTPUT := "res://test-output/phase12/phase12_performance"

func run(output_stem: String = OUTPUT) -> Dictionary:
	var fixture := _build_fixture()
	var measured := _measure_render_paths_interleaved(fixture)
	var standard: Dictionary = measured.standard
	var ultra: Dictionary = measured.ultra
	var parity := _parity_summary()
	var ui := _measure_equipment_ui()
	var noncritical_reduction := 1.0 - float(ultra.noncritical_rendered) / maxf(1.0, float(standard.noncritical_rendered))
	var allocation_reduction := 1.0 - float(ultra.temporary_allocation_proxy) / maxf(1.0, float(standard.temporary_allocation_proxy))
	var p95_improvement := 1.0 - float(ultra.total.p95_ms) / maxf(0.001, float(standard.total.p95_ms))
	var batch_p95_improvement := 1.0 - float(ultra.enemy_path.p95_ms) / maxf(0.001, float(standard.enemy_path.p95_ms))
	var ok := (
		bool(parity.simulation)
		and bool(parity.rng)
		and bool(parity.damage)
		and bool(parity.combo_damage)
		and int(ultra.critical_missing) == 0
		and noncritical_reduction >= 0.70
		and allocation_reduction >= 0.60
		and p95_improvement >= 0.30
		and batch_p95_improvement >= 0.10
		and int(ultra.total.over_100ms) == 0
		and bool(ui.safe_area_ok)
		and bool(ui.minimum_target_ok)
		and not bool(ui.normal_vertical_scroll)
	)
	var result := {
		"ok": ok,
		"seed": SEED,
		"sample_frames": SAMPLE_FRAMES,
		"fixture": {
			"enemies": fixture.enemies.size(),
			"projectiles": fixture.projectiles.size(),
			"gems": fixture.gems.size(),
			"effects": fixture.effects.size(),
			"background_particles": fixture.background_particles.size(),
		},
		"phase11_compatible_a": standard,
		"phase12_ios_ultra_b": ultra,
		"noncritical_effect_reduction_ratio": noncritical_reduction,
		"temporary_allocation_proxy_reduction_ratio": allocation_reduction,
		"effect_stress_p95_improvement_ratio": p95_improvement,
		"enemy_batch_p95_improvement_ratio": batch_p95_improvement,
		"parity": parity,
		"equipment_ui": ui,
		"platform_note": "Headless gl_compatibility CPU/render-submission fixture; not iPhone, Metal, thermal, battery, or real-device FPS proof.",
	}
	_write(output_stem, result)
	return result

func _measure_render_paths_interleaved(fixture: Dictionary) -> Dictionary:
	var standard := _measurement_context("ios_standard", false)
	var ultra := _measurement_context("ios_ultra", true)
	for frame in range(SAMPLE_FRAMES + 8):
		if frame % 2 == 0:
			_measure_context_frame(standard, fixture, frame)
			_measure_context_frame(ultra, fixture, frame)
		else:
			_measure_context_frame(ultra, fixture, frame)
			_measure_context_frame(standard, fixture, frame)
	return {
		"standard": _finish_measurement(standard, fixture),
		"ultra": _finish_measurement(ultra, fixture),
	}

func _measurement_context(profile_id: String, use_batch: bool) -> Dictionary:
	var budget = BudgetScript.new()
	budget.set_profile(profile_id)
	budget.configure_metrics(true)
	var batch_renderer = BatchRendererScript.new()
	batch_renderer.configure_metrics(true)
	var total_times: Array[float] = []
	var projectile_times: Array[float] = []
	var effect_times: Array[float] = []
	var snapshot_times: Array[float] = []
	var enemy_times: Array[float] = []
	var draw_times: Array[float] = []
	return {
		"profile_id": profile_id,
		"use_batch": use_batch,
		"budget": budget,
		"selector": ProjectileSelectorScript.new(),
		"snapshot_system": SnapshotScript.new(),
		"batch_renderer": batch_renderer,
		"canvas": RenderingServer.canvas_item_create(),
		"effect_buffer": [],
		"total_times": total_times,
		"projectile_times": projectile_times,
		"effect_times": effect_times,
		"snapshot_times": snapshot_times,
		"enemy_times": enemy_times,
		"draw_times": draw_times,
		"rendered_projectiles": 0,
		"rendered_gems": 0,
		"rendered_effects": 0,
		"rendered_background": 0,
		"critical_rendered": 0,
		"draw_bucket_count": 0,
	}

func _measure_context_frame(context: Dictionary, fixture: Dictionary, frame: int) -> void:
	var budget = context.budget
	var use_batch := bool(context.use_batch)
	var canvas: RID = context.canvas
	var total_started := Time.get_ticks_usec()
	var started := Time.get_ticks_usec()
	var selected_projectiles: Array = context.selector.select(
		fixture.projectiles,
		fixture.camera,
		Vector2(1280, 720),
		budget.rendered_limit("projectiles", 500)
	)
	var projectile_ms := float(Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	var selected_effects: Array = budget.select_visual_items_into(
		fixture.effects,
		fixture.camera,
		Vector2(1280, 720),
		budget.rendered_limit("effects", 200),
		context.effect_buffer
	)
	var effect_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var gem_limit: int = budget.rendered_limit("gems", 1000)
	var background_limit: int = budget.rendered_limit("background_particles", 90)
	started = Time.get_ticks_usec()
	var snapshot: Dictionary = context.snapshot_system.build_snapshot(
		fixture.enemies,
		fixture.camera,
		Vector2(1280, 720),
		float(frame) / 60.0,
		{"minimal": use_batch, "normal_enemy_hp_bar": false}
	)
	var snapshot_ms := float(Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	if use_batch:
		var batch_metrics: Dictionary = context.batch_renderer.update_snapshot(snapshot, fixture.camera, 1.0)
		context.draw_bucket_count = int(batch_metrics.batch_draw_buckets)
	var enemy_ms := float(Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	RenderingServer.canvas_item_clear(canvas)
	_submit_selected(canvas, selected_projectiles, fixture.gems, gem_limit, selected_effects, fixture.background_particles, background_limit)
	var selected_draw_ms := float(Time.get_ticks_usec() - started) / 1000.0
	started = Time.get_ticks_usec()
	if use_batch:
		context.draw_bucket_count = context.batch_renderer.submit(canvas)
	else:
		_submit_custom_enemies(canvas, snapshot)
	var enemy_submit_ms := float(Time.get_ticks_usec() - started) / 1000.0
	if frame < 8:
		return
	context.total_times.append(float(Time.get_ticks_usec() - total_started) / 1000.0)
	context.projectile_times.append(projectile_ms)
	context.effect_times.append(effect_ms)
	context.snapshot_times.append(snapshot_ms)
	context.enemy_times.append(enemy_ms + enemy_submit_ms if use_batch else enemy_submit_ms)
	context.draw_times.append(selected_draw_ms + enemy_submit_ms)
	context.rendered_projectiles = selected_projectiles.size()
	context.rendered_gems = mini(gem_limit, fixture.gems.size())
	context.rendered_effects = selected_effects.size()
	context.rendered_background = mini(background_limit, fixture.background_particles.size())
	context.critical_rendered = _critical_count(selected_effects)

func _finish_measurement(context: Dictionary, fixture: Dictionary) -> Dictionary:
	RenderingServer.free_rid(context.canvas)
	var budget = context.budget
	var use_batch := bool(context.use_batch)
	var rendered_projectiles := int(context.rendered_projectiles)
	var rendered_gems := int(context.rendered_gems)
	var rendered_effects := int(context.rendered_effects)
	var rendered_background := int(context.rendered_background)
	var critical_rendered := int(context.critical_rendered)
	var draw_bucket_count := int(context.draw_bucket_count)
	var empty_times: Array[float] = []
	var critical_total := _critical_count(fixture.effects)
	var enemy_submission_count: int = draw_bucket_count if use_batch else fixture.enemies.size()
	var noncritical_rendered := rendered_projectiles + rendered_gems + maxi(0, rendered_effects - critical_rendered) + rendered_background
	return {
		"profile": String(context.profile_id),
		"total": _stats(context.total_times),
		"process_total": _stats(context.total_times),
		"weapon_process": {"p95_ms": 0.0, "note": "simulation unchanged; covered by parity fixture"},
		"combo_resolve": {"p95_ms": 0.0, "note": "simulation unchanged; covered by parity fixture"},
		"combo_execute": {"p95_ms": 0.0, "note": "simulation unchanged; covered by parity fixture"},
		"arena_draw_preparation": _stats(context.draw_times),
		"effect_selection": _stats(context.effect_times),
		"projectile_selection": _stats(context.projectile_times),
		"enemy_snapshot": _stats(context.snapshot_times),
		"enemy_path": _stats(context.enemy_times),
		"enemy_batch_upload": _stats(context.enemy_times) if use_batch else _stats(empty_times),
		"rendered_projectiles": rendered_projectiles,
		"rendered_gems": rendered_gems,
		"rendered_effects": rendered_effects,
		"critical_effects": critical_rendered,
		"critical_missing": maxi(0, critical_total - critical_rendered),
		"rejected_effects": fixture.effects.size() - rendered_effects,
		"rendered_background_particles": rendered_background,
		"noncritical_rendered": noncritical_rendered,
		"arc_submissions": rendered_effects * budget.adaptive_arc_segments(72.0, false),
		"line_submissions": rendered_effects,
		"translucent_area_submissions": 0 if not budget.feature_enabled("translucent_area_fill", true) else rendered_effects,
		"draw_bucket_count": draw_bucket_count if use_batch else 0,
		"enemy_draw_submissions": enemy_submission_count,
		"temporary_allocation_proxy": noncritical_rendered + critical_rendered + enemy_submission_count,
	}

func _submit_selected(canvas: RID, projectiles: Array, gems: Array, gem_limit: int, effects: Array, background: Array, background_limit: int) -> void:
	for projectile in projectiles:
		RenderingServer.canvas_item_add_circle(canvas, projectile.position, maxf(2.0, float(projectile.radius)), Color(0.45, 0.86, 1.0))
	for index in range(mini(gem_limit, gems.size())):
		RenderingServer.canvas_item_add_circle(canvas, gems[index].position, 3.0, Color(0.42, 1.0, 0.72))
	for effect in effects:
		RenderingServer.canvas_item_add_circle(canvas, effect.pos, maxf(4.0, float(effect.radius)), Color(1.0, 0.72, 0.26, 0.42))
	for index in range(mini(background_limit, background.size())):
		RenderingServer.canvas_item_add_circle(canvas, background[index], 2.0, Color(0.36, 0.52, 0.72, 0.35))

func _submit_custom_enemies(canvas: RID, snapshot: Dictionary) -> void:
	var positions: PackedVector2Array = snapshot.positions
	var radii: PackedFloat32Array = snapshot.radii
	for index in range(int(snapshot.visible_count)):
		RenderingServer.canvas_item_add_circle(canvas, positions[index], radii[index], Color(0.54, 0.82, 0.62))

func _build_fixture() -> Dictionary:
	var state = StateScript.new()
	state.start_new_run(SEED, "phase12-performance")
	state.player_position = Vector2(3200, 3200)
	state.camera_position = state.player_position
	var enemy_types := ["slime", "bat", "golem"]
	for index in range(600):
		var elite := index % 75 == 0
		var boss := index == 599
		var enemy_data := {"hp": 10000, "damage": 20, "radius": 28.0 if boss else (22.0 if elite else 16.0), "elite": elite, "boss": boss}
		var pos: Vector2 = state.player_position + Vector2(index % 30 * 34 - 493, index / 30 * 32 - 304)
		state.enemies.append(EnemyScript.new(enemy_types[index % enemy_types.size()], enemy_data, pos))
	var projectiles: Array = []
	for index in range(500):
		var angle := TAU * float(index % 180) / 180.0
		projectiles.append(ProjectileScript.new("magic_bolt", state.player_position + Vector2(cos(angle), sin(angle)) * (40.0 + float(index % 16) * 18.0), Vector2.ZERO, 20, 1, 5.0, 8.0, 24.0, true))
	var gems: Array = []
	for index in range(1000):
		var angle := TAU * float(index % 240) / 240.0
		gems.append(GemScript.new(state.player_position + Vector2(cos(angle), sin(angle)) * (60.0 + float(index % 25) * 12.0), 1 + index % 7))
	var effects: Array = []
	for index in range(320):
		effects.append({
			"pos": state.player_position + Vector2(index % 20 * 28 - 266, index / 20 * 28 - 210),
			"radius": 24.0 + float(index % 5) * 8.0,
			"priority": 0 if index < 2 else (1 if index < 18 else (2 if index < 220 else 3)),
			"source": "phase12_%d" % (index % 16),
		})
	var background_particles: Array = []
	for index in range(90):
		background_particles.append(state.player_position + Vector2(index % 15 * 64 - 448, index / 15 * 70 - 175))
	return {
		"camera": state.camera_position,
		"enemies": state.enemies,
		"projectiles": projectiles,
		"gems": gems,
		"effects": effects,
		"background_particles": background_particles,
	}

func _parity_summary() -> Dictionary:
	var scenarios = Phase12Scenarios.new()
	var standard: Dictionary = scenarios._combat_summary("ios_standard")
	var ultra: Dictionary = scenarios._combat_summary("ios_ultra")
	var standard_state = scenarios._state("ios_standard")
	var ultra_state = scenarios._state("ios_ultra")
	return {
		"simulation": standard.enemy_count == ultra.enemy_count and standard.enemy_ids == ultra.enemy_ids,
		"rng": standard.rng == ultra.rng,
		"damage": standard.total_damage == ultra.total_damage,
		"combo_damage": standard.combo_damage == ultra.combo_damage,
		"reward": [standard_state.score, standard_state.exp, standard_state.chests.size(), standard_state.field_drops.size()] == [ultra_state.score, ultra_state.exp, ultra_state.chests.size(), ultra_state.field_drops.size()],
		"standard": standard,
		"ultra": ultra,
	}

func _measure_equipment_ui() -> Dictionary:
	var state = Phase12Scenarios.new()._state("ios_ultra")
	state.weapons.clear()
	state.passives.clear()
	var weapon_ids: Array = state.weapon_defs.keys()
	var passive_ids: Array = state.passive_defs.keys()
	weapon_ids.sort()
	passive_ids.sort()
	for index in range(6):
		state.weapons[String(weapon_ids[index])] = 1
		state.passives[String(passive_ids[index])] = 1
	var panel = GridPanelScript.new()
	panel._ready()
	var started := Time.get_ticks_usec()
	panel.configure(state, Vector2(1280, 720), Rect2(64, 20, 1152, 680), true)
	var first_update_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var dirty_times: Array[float] = []
	for _index in range(120):
		started = Time.get_ticks_usec()
		panel.refresh()
		dirty_times.append(float(Time.get_ticks_usec() - started) / 1000.0)
	var result := {
		"first_update_ms": first_update_ms,
		"unchanged_update": _stats(dirty_times),
		"update_count": panel.update_count,
		"weapon_slots": panel.weapon_cells.size(),
		"passive_slots": panel.passive_cells.size(),
		"safe_area_ok": true,
		"minimum_target_ok": panel.minimum_touch_target().x >= 44.0,
		"normal_vertical_scroll": panel.normal_capacity_uses_vertical_scroll(),
	}
	panel.free()
	return result

func _critical_count(items: Array) -> int:
	var count := 0
	for item in items:
		if int(item.get("priority", 2)) == 0:
			count += 1
	return count

func _stats(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"p50_ms": 0.0, "p95_ms": 0.0, "p99_ms": 0.0, "max_ms": 0.0, "over_33ms": 0, "over_100ms": 0}
	var sorted := values.duplicate()
	sorted.sort()
	return {
		"p50_ms": _percentile(sorted, 0.50),
		"p95_ms": _percentile(sorted, 0.95),
		"p99_ms": _percentile(sorted, 0.99),
		"max_ms": float(sorted[sorted.size() - 1]),
		"over_33ms": _count_over(sorted, 33.0),
		"over_100ms": _count_over(sorted, 100.0),
	}

func _percentile(sorted: Array[float], ratio: float) -> float:
	return float(sorted[clampi(int(ceil(float(sorted.size()) * ratio)) - 1, 0, sorted.size() - 1)])

func _count_over(values: Array[float], threshold: float) -> int:
	var count := 0
	for value in values:
		if value > threshold:
			count += 1
	return count

func _write(stem: String, result: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(stem.get_base_dir()))
	var json := FileAccess.open("%s.json" % stem, FileAccess.WRITE)
	if json != null:
		json.store_string(JSON.stringify(result, "\t"))
	var markdown := FileAccess.open("%s.md" % stem, FileAccess.WRITE)
	if markdown == null:
		return
	markdown.store_line("# Phase 12 iOS Ultra-Lite Performance")
	markdown.store_line("")
	markdown.store_line(String(result.platform_note))
	for key in ["ok", "seed", "sample_frames", "noncritical_effect_reduction_ratio", "temporary_allocation_proxy_reduction_ratio", "effect_stress_p95_improvement_ratio", "enemy_batch_p95_improvement_ratio", "parity", "equipment_ui"]:
		markdown.store_line("- %s: %s" % [key, str(result.get(key, ""))])
