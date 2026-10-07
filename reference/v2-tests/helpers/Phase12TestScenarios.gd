extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const ProfileScript = preload("res://scripts/systems/PerformanceProfileSystem.gd")
const BudgetScript = preload("res://scripts/systems/VisualEffectBudgetSystem.gd")
const WorldScaleScript = preload("res://scripts/systems/WorldRenderScaleSystem.gd")
const LayoutScript = preload("res://scripts/systems/EquipmentGridLayoutSystem.gd")
const IconScript = preload("res://scripts/systems/EquipmentIconResolver.gd")
const ThermalProviderScript = preload("res://scripts/systems/ThermalStateProvider.gd")
const ThermalPolicyScript = preload("res://scripts/systems/ThermalRenderPolicySystem.gd")
const SnapshotScript = preload("res://scripts/systems/EnemyRenderSnapshotSystem.gd")
const BatchScript = preload("res://scripts/systems/EnemyBatchABSystem.gd")
const BatchRendererScript = preload("res://scripts/systems/EnemyBatchRenderer2D.gd")
const UiViewportContractScript = preload("res://scripts/systems/UiViewportContractSystem.gd")
const GridPanelScript = preload("res://scripts/ui/components/EquipmentGridPanel.gd")
const ComboSystemScript = preload("res://scripts/systems/WeaponComboSystem.gd")
const WeaponSystemScript = preload("res://scripts/systems/WeaponSystem.gd")

func ios_ultra_profile_values(t) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/visual_effect_profiles.json"))
	var profile: Dictionary = data.get("profiles", {}).get("ios_ultra", {})
	for pair in [["max_rendered_projectiles", 24], ["max_rendered_gems", 64], ["max_rendered_effects", 8], ["persistent_area_animation_hz", 3], ["minimap_update_hz", 2], ["world_stretch_shrink", 2]]:
		t.assert_eq(profile.get(pair[0]), pair[1], "ios_ultra %s" % pair[0])
	t.assert_eq(float(profile.get("arc_segment_scale", 0.0)), 0.20, "ios_ultra arc scale")
	t.assert_true(bool(profile.get("minimal", false)) and bool(profile.get("ultra", false)), "ios_ultra flags")

func ios_ultra_simulation_parity(t) -> void:
	var standard := _initial_signature("ios_standard")
	var ultra := _initial_signature("ios_ultra")
	t.assert_eq(ultra, standard, "render profile must not mutate initial simulation")

func ios_ultra_rng_parity(t) -> void:
	t.assert_eq(_combat_summary("ios_ultra").rng, _combat_summary("ios_standard").rng, "RNG digest parity")

func ios_ultra_damage_parity(t) -> void:
	t.assert_eq(_combat_summary("ios_ultra").total_damage, _combat_summary("ios_standard").total_damage, "total damage parity")

func ios_ultra_combo_damage_parity(t) -> void:
	t.assert_eq(_combat_summary("ios_ultra").combo_damage, _combat_summary("ios_standard").combo_damage, "combo damage parity")

func ios_ultra_enemy_count_parity(t) -> void:
	var a := _combat_summary("ios_standard")
	var b := _combat_summary("ios_ultra")
	t.assert_eq(b.enemy_count, a.enemy_count, "enemy count parity")
	t.assert_eq(b.enemy_ids, a.enemy_ids, "enemy identity parity")

func ios_ultra_reward_parity(t) -> void:
	var a: RefCounted = _state("ios_standard")
	var b: RefCounted = _state("ios_ultra")
	t.assert_eq([b.score, b.exp, b.chests.size(), b.field_drops.size()], [a.score, a.exp, a.chests.size(), a.field_drops.size()], "reward state parity")

func ios_ultra_critical_visuals(t) -> void:
	var budget = BudgetScript.new()
	budget.set_profile("ios_ultra")
	var items := [
		{"pos": Vector2.ZERO, "priority": 0, "id": "boss"},
		{"pos": Vector2.ONE, "priority": 0, "id": "warning"},
		{"pos": Vector2(2, 2), "priority": 2, "id": "normal"},
	]
	var selected := budget.select_visual_items(items, Vector2.ZERO, Vector2(100, 100), 1)
	t.assert_true(selected.any(func(item): return item.id == "boss"), "boss critical retained")
	t.assert_true(selected.any(func(item): return item.id == "warning"), "warning critical retained")

func ios_ultra_effect_budget(t) -> void:
	var budget = BudgetScript.new()
	budget.set_profile("ios_ultra")
	t.assert_eq(budget.rendered_limit("projectiles", 999), 24, "projectile visual cap")
	t.assert_eq(budget.rendered_limit("gems", 999), 64, "gem visual cap")
	t.assert_eq(budget.rendered_limit("effects", 999), 8, "effect visual cap")
	t.assert_true(not budget.feature_enabled("decorative"), "decorative disabled")

func ios_ultra_unbudgeted_effect_audit(t) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/ArenaView.gd")
	for token in ["player_magnet_ring", "field_item_pulse", "translucent_area_fill", "representative_limit", "adaptive_arc_segments"]:
		t.assert_true(source.contains(token), "ArenaView routes %s through profile contract" % token)
	var regex := RegEx.new()
	regex.compile("draw_arc\\([^\\n]*, (24|28|32|40|48|64),")
	t.assert_eq(regex.search(source), null, "large hard-coded arc segments removed")

func world_render_shrink_layout(t) -> void:
	var contract := WorldScaleScript.new().contract("ios_ultra", Vector2(1280, 720))
	t.assert_eq(contract.world_size, Vector2i(640, 360), "ultra world resolution")
	t.assert_eq(contract.stretch_shrink, 2, "ultra stretch shrink")
	t.assert_eq(contract.logical_world_size, Vector2(1280, 720), "ultra preserves standard field of view")
	t.assert_eq(contract.render_camera_zoom, 0.5, "ultra compensates camera zoom for viewport shrink")
	t.assert_true(contract.ui_in_root and contract.disable_3d, "UI/root and 2D contract")

func world_render_touch_mapping(t) -> void:
	var system = WorldScaleScript.new()
	var root_pos := Vector2(880, 420)
	var world_pos := system.map_root_to_world(root_pos, 2)
	t.assert_eq(system.map_world_to_root(world_pos, 2), root_pos, "touch coordinate roundtrip")

func ios_ultra_ui_text_scale_parity(t) -> void:
	var contract = UiViewportContractScript.new()
	var layout := {"ui_scale_min": 0.86, "ui_scale_max": 1.18, "safe_margin": 24.0}
	var fonts := {"hud": 17, "pause": 26, "reward": 28, "equipment": 15, "touch": 20}
	var standard := contract.geometry_snapshot(Vector2(1280, 720), 1.0, layout, fonts)
	var ultra := contract.geometry_snapshot(Vector2(1280, 720), 1.0, layout, fonts)
	var wrong_world := contract.geometry_snapshot(Vector2(640, 360), 1.0, layout, fonts)
	t.assert_true(contract.same_geometry(standard, ultra), "standard and ultra root UI geometry match")
	t.assert_true(not contract.same_geometry(standard, wrong_world), "world viewport fixture detects UI scale contamination")
	t.assert_eq(standard.font_sizes, ultra.font_sizes, "all major UI font sizes match")

func ios_ultra_ui_root_viewport_contract(t) -> void:
	var contract = UiViewportContractScript.new()
	var holder := Control.new()
	t.root.add_child(holder)
	var world_viewport := SubViewport.new()
	world_viewport.size = Vector2i(640, 360)
	holder.add_child(world_viewport)
	var world_control := Control.new()
	world_viewport.add_child(world_control)
	var root_size: Vector2 = t.root.get_visible_rect().size
	var resolved: Vector2 = contract.root_viewport_size(world_control, Vector2(1, 1))
	t.assert_true(resolved.is_equal_approx(root_size), "UI contract resolves main root viewport")
	t.assert_true(not resolved.is_equal_approx(Vector2(640, 360)), "world internal size never becomes UI viewport")
	t.assert_eq(contract.world_ui_contract().ui_parent, "root_viewport", "UI remains outside world viewport")
	holder.free()

func ios_ultra_runtime_profile_ui_stability(t) -> void:
	var contract = UiViewportContractScript.new()
	var root_node := Node.new()
	t.root.add_child(root_node)
	var instance_id := root_node.get_instance_id()
	var layout := {"ui_scale_min": 0.86, "ui_scale_max": 1.18, "safe_margin": 24.0}
	var fonts := {"hud": 17, "pause": 26, "notification": 16, "equipment": 15}
	var first := contract.geometry_snapshot(Vector2(1280, 720), 1.0, layout, fonts)
	for profile in ["ios_standard", "ios_ultra", "ios_standard", "ios_ultra"]:
		var current := contract.geometry_snapshot(Vector2(1280, 720), 1.0, layout, fonts)
		t.assert_true(contract.same_geometry(first, current), "profile %s keeps UI geometry" % profile)
	t.assert_eq(root_node.get_instance_id(), instance_id, "profile transition keeps node identity")
	var source := FileAccess.get_file_as_string("res://scripts/ui/GameScreen.gd")
	var transition_start := source.find("func _apply_runtime_render_profile")
	t.assert_true(transition_start >= 0 and not source.substr(transition_start).contains("_build_ui()"), "profile transition does not rebuild UI")
	root_node.free()

func ios_ultra_modal_text_scale_parity(t) -> void:
	var contract = UiViewportContractScript.new()
	var layout := {"ui_scale_min": 0.86, "ui_scale_max": 1.18, "safe_margin": 24.0}
	var modal_fonts := {"pause_title": 26, "pause_body": 18, "reward_title": 28, "equipment_detail": 19, "button": 20}
	var standard := contract.geometry_snapshot(Vector2(1280, 720), 1.0, layout, modal_fonts)
	var ultra := contract.geometry_snapshot(Vector2(1280, 720), 1.0, layout, modal_fonts)
	t.assert_true(contract.same_geometry(standard, ultra), "pause reward equipment and touch font geometry match")
	t.assert_eq(contract.world_ui_contract().profile_changes_rebuild_ui, false, "modal profile change is presentation-only")

func equipment_grid_all_slots_visible(t) -> void:
	var panel = _grid_panel()
	t.assert_eq(panel.weapon_cells.size(), 6, "six weapon slots")
	t.assert_eq(panel.passive_cells.size(), 6, "six passive slots")
	panel.free()

func equipment_grid_safe_area(t) -> void:
	var layout := LayoutScript.new().layout(Vector2(1280, 720), Rect2(64, 20, 1152, 680), true)
	t.assert_true(layout.safe_area_ok, "grid safe area")
	var panel = _grid_panel(Vector2(844, 390), Rect2(47, 0, 750, 369))
	t.assert_eq(panel.root_layout.columns, 1, "narrow equipment detail moves below")
	panel.free()

func equipment_grid_minimum_touch_target(t) -> void:
	var layout := LayoutScript.new().layout(Vector2(1280, 720), Rect2(64, 20, 1152, 680), true)
	t.assert_true(float(layout.cell_extent) >= 44.0 and bool(layout.touch_target_ok), "44 point target")

func equipment_grid_detail_selection(t) -> void:
	var panel = _grid_panel()
	panel.focus_kind("weapon")
	t.assert_true(panel.detail_panel != null and panel.selected_id != "", "detail selection available")
	panel.focus_kind("passive")
	t.assert_true(panel.selected_kind == "passive" and panel.source_state.passives.has(panel.selected_id), "passive focus updates detail selection")
	panel.free()

func equipment_grid_keyboard_navigation(t) -> void:
	var panel = _grid_panel()
	for cell in panel.weapon_cells + panel.passive_cells:
		t.assert_eq(cell.focus_mode, Control.FOCUS_ALL, "cell keyboard focus")
	panel.free()

func equipment_grid_no_normal_scroll(t) -> void:
	var panel = _grid_panel()
	t.assert_true(not panel.normal_capacity_uses_vertical_scroll(), "6+6 needs no vertical scroll")
	panel.free()

func equipment_grid_overcap_paging(t) -> void:
	var layout = LayoutScript.new()
	t.assert_eq(layout.page_count(13), 3, "overcap page count")
	t.assert_eq(layout.page_slice(range(13), 2).size(), 1, "last overcap page")
	var panel = _grid_panel(Vector2(1280, 720), Rect2(64, 20, 1152, 680), 13)
	t.assert_true(panel.weapon_next_button.visible, "overcap next page control visible")
	panel.change_page("weapon", 1)
	t.assert_eq(panel.weapon_page, 1, "overcap page switch")
	panel.free()

func equipment_grid_dirty_update(t) -> void:
	var panel = _grid_panel()
	var before: int = panel.update_count
	t.assert_true(not panel.refresh(), "unchanged grid skips rebuild")
	t.assert_eq(panel.update_count, before, "dirty update count unchanged")
	panel.free()

func equipment_icon_fallback(t) -> void:
	var resolved := IconScript.new().resolve({"name_ja": "魔弾"})
	t.assert_eq(resolved.source, "deterministic_fallback", "fallback source")
	t.assert_eq(resolved.glyph, "魔", "Japanese fallback glyph")

func thermal_profile_transition(t) -> void:
	var policy = ThermalPolicyScript.new()
	t.assert_eq(policy.update("serious", 0.1), "serious", "thermal drops quickly")
	t.assert_eq(policy.update("nominal", 29.0), "serious", "thermal recovery waits")
	t.assert_eq(policy.update("nominal", 1.0), "fair", "thermal recovers one step")

func low_power_mode_effective_settings(t) -> void:
	var effective := ThermalPolicyScript.new().effective_settings({"target_fps": 60, "render_quality": "high"}, true)
	t.assert_eq(effective._effective_render_profile, "ios_ultra", "low power selects ultra")
	t.assert_eq(effective.target_fps, 30, "low power target fps")
	var state = _state("ios_standard")
	var profiles = ProfileScript.new()
	t.assert_eq(profiles.apply_to_state(state, {"render_quality": "standard", "effect_density": "normal", "low_power_mode": false}, "iOS"), "ios_standard", "user base profile remains recoverable")
	t.assert_eq(profiles.apply_to_state(state, effective, "iOS"), "ios_ultra", "effective low power profile is ultra")

func thermal_does_not_mutate_saved_settings(t) -> void:
	var saved := {"target_fps": 60, "render_quality": "high"}
	var before := saved.duplicate(true)
	ThermalPolicyScript.new().effective_settings(saved, true)
	t.assert_eq(saved, before, "thermal does not mutate save")

func enemy_batch_visual_parity(t) -> void:
	var snapshot := _enemy_snapshot(96)
	var buckets := BatchScript.new().bucketize(snapshot)
	var renderer = BatchRendererScript.new()
	t.assert_true(renderer.has_drawable_meshes(), "every enemy batch has a drawable 32px quad mesh")
	var body_count := 0
	for key in ["normal_circle", "normal_diamond", "normal_square", "elite", "boss"]:
		body_count += (buckets[key] as PackedInt32Array).size()
	t.assert_eq(body_count, int(snapshot.visible_count), "every visible enemy has one body bucket")
	t.assert_eq(int(snapshot.critical_missing), 0, "critical enemy parity")

func enemy_batch_performance(t) -> void:
	var snapshot := _enemy_snapshot(600)
	var comparison := BatchScript.new().submission_counts(snapshot)
	t.assert_true(int(comparison.batch_draw_buckets) <= 6, "batch uses at most six buckets")
	t.assert_true(int(comparison.batch_draw_buckets) * 10 <= int(comparison.custom_draw_submissions), "batch submission reduction >=90 percent")
	var canvas := Control.new()
	t.root.add_child(canvas)
	var renderer = BatchRendererScript.new()
	t.assert_true(renderer.has_drawable_meshes(), "batch renderer has a source mesh before submission")
	renderer.configure_metrics(true)
	var metrics := renderer.update_snapshot(snapshot, Vector2(3200, 3200), 1.0)
	var submissions: int = renderer.submit(canvas.get_canvas_item())
	t.assert_eq(int(metrics.critical_missing), 0, "batch upload keeps critical enemies")
	t.assert_true(submissions > 0 and submissions <= 6, "RenderingServer multimesh submission")
	canvas.free()

func _initial_signature(profile_id: String) -> int:
	var state = _state(profile_id)
	return [state.map_signature(), state.rng.snapshot(), state.max_enemies(), state.max_projectiles(), state.max_enemy_projectiles(), state.max_gems(), state.weapons, state.score, state.exp, state.kills].hash()

func _state(profile_id: String):
	var state = StateScript.new()
	state.start_new_run(121212, "phase12-parity")
	state.configure_render_profile(profile_id)
	return state

func _combat_summary(profile_id: String) -> Dictionary:
	var state = _state(profile_id)
	state.weapons = {"magic_bolt": 8, "bomb_seed": 8, "ice_orbit": 8, "thunder_chain": 8, "blade_fan": 8, "frost_wall": 8}
	state.player_position = Vector2(3200, 3200)
	for index in range(80):
		var data := {"hp": 10000, "damage": 10, "radius": 18.0, "elite": index % 20 == 0}
		var enemy = EnemyScript.new("slime", data, state.player_position + Vector2(index % 10 * 28 - 126, index / 10 * 28 - 98))
		enemy.set_meta("phase12_id", index)
		state.enemies.append(enemy)
	var weapon = WeaponSystemScript.new()
	weapon.enemy_grid.rebuild(state.enemies)
	var combo = ComboSystemScript.new()
	combo.initialize(state)
	for combo_id in state.weapon_combo_runtime.get("active", {}).keys():
		state.weapon_combo_runtime.cooldowns[combo_id] = 0.0
	combo.process(state, 1.0 / 60.0, [], weapon)
	var combo_damage := 0
	for value in state.weapon_combo_runtime.get("damage", {}).values():
		combo_damage += int(value)
	return {
		"rng": state.rng.snapshot(),
		"total_damage": int(state.damage_by_category.get("weapon_combo", 0)),
		"combo_damage": combo_damage,
		"enemy_count": state.enemies.size(),
		"enemy_ids": range(state.enemies.size()),
	}

func _enemy_snapshot(count: int) -> Dictionary:
	var state = _state("ios_ultra")
	state.player_position = Vector2(3200, 3200)
	for index in range(count):
		var elite := index % 50 == 0
		var boss := index == count - 1
		state.enemies.append(EnemyScript.new("golem" if index % 3 == 0 else ("bat" if index % 3 == 1 else "slime"), {"hp": 100, "damage": 10, "radius": 18.0, "elite": elite, "boss": boss}, state.player_position + Vector2(index % 30 * 20 - 290, index / 30 * 20 - 190)))
	return SnapshotScript.new().build_snapshot(state.enemies, state.player_position, Vector2(1280, 720), 60.0, {"minimal": true})

func ios_ultra_all_enemy_types_visible(t) -> void:
	var snapshot := _enemy_fixture_snapshot()
	var renderer = BatchRendererScript.new()
	renderer.update_snapshot(snapshot, Vector2(320, 180), 1.0)
	var report: Dictionary = renderer.validation_report(snapshot)
	t.assert_eq(int(report.expected_body_count), int(report.detected_body_count), "all enemy types have a visible body slot")
	t.assert_eq(int(report.missing_body_count), 0, "missing enemy bodies")
	t.assert_eq(int(report.transparent_body_count), 0, "transparent enemy bodies")
	t.assert_eq(int(report.invalid_mesh_count), 0, "enemy mesh validity")
	t.assert_eq(int(report.invalid_texture_count), 0, "enemy texture validity")
	t.assert_eq(int(report.invalid_transform_count), 0, "enemy transform validity")

func ios_ultra_enemy_instance_alpha(t) -> void:
	var snapshot := _enemy_fixture_snapshot(["elite", "boss", "ghost"])
	var renderer = BatchRendererScript.new()
	renderer.update_snapshot(snapshot, Vector2(320, 180), 1.0)
	var report: Dictionary = renderer.validation_report(snapshot)
	t.assert_eq(int(report.transparent_body_count), 0, "elite boss status body alpha")
	t.assert_eq(int(report.critical_missing), 0, "critical enemy visual missing")

func ios_ultra_enemy_bucket_membership_refresh(t) -> void:
	var renderer = BatchRendererScript.new()
	var first := _enemy_fixture_snapshot(["slime", "golem", "bat"])
	var second := _enemy_fixture_snapshot(["ghost", "charger", "shooter"])
	renderer.update_snapshot(first, Vector2(320, 180), 1.0)
	renderer.update_snapshot(second, Vector2(320, 180), 1.0)
	var report: Dictionary = renderer.validation_report(second)
	t.assert_eq(int(report.detected_body_count), 3, "membership change immediately refreshes visible bodies")
	t.assert_eq(int(report.missing_body_count), 0, "membership refresh has no missing body")

func ios_ultra_enemy_slot_reuse(t) -> void:
	var renderer = BatchRendererScript.new()
	for ids in [["slime", "ghost"], ["bat", "charger"], [], ["golem", "shield_bug"]]:
		var fixture_ids: Array = ["__empty__"] if ids.is_empty() else ids
		var snapshot := _enemy_fixture_snapshot(fixture_ids)
		renderer.update_snapshot(snapshot, Vector2(320, 180), 1.0)
		var report: Dictionary = renderer.validation_report(snapshot)
		t.assert_eq(int(report.detected_body_count), ids.size(), "slot reuse body count %s" % str(ids))
		t.assert_eq(int(report.transparent_body_count), 0, "slot reuse alpha %s" % str(ids))

func ios_ultra_enemy_spawn_despawn_visibility(t) -> void:
	var renderer = BatchRendererScript.new()
	var empty := _enemy_fixture_snapshot(["__empty__"])
	var spawned := _enemy_fixture_snapshot(["splitter", "splitter_child", "reaper"])
	renderer.update_snapshot(empty, Vector2(320, 180), 1.0)
	renderer.update_snapshot(spawned, Vector2(320, 180), 1.0)
	var spawned_report: Dictionary = renderer.validation_report(spawned)
	t.assert_eq(int(spawned_report.detected_body_count), 3, "spawned bodies appear immediately")
	renderer.update_snapshot(empty, Vector2(320, 180), 1.0)
	var empty_report: Dictionary = renderer.validation_report(empty)
	t.assert_eq(int(empty_report.detected_body_count), 0, "despawn clears stale body instances")

func ios_ultra_enemy_cadence_contract(t) -> void:
	var renderer = BatchRendererScript.new()
	var snapshots := [
		_enemy_fixture_snapshot(["slime", "bat", "golem"]),
		_enemy_fixture_snapshot(["slime", "bat", "golem"]),
		_enemy_fixture_snapshot(["ghost", "charger", "shield_bug"]),
		_enemy_fixture_snapshot(["slime", "bat", "golem"]),
	]
	for snapshot in snapshots:
		renderer.update_snapshot(snapshot, Vector2(320, 180), 1.0)
		var report: Dictionary = renderer.validation_report(snapshot)
		t.assert_eq(int(report.missing_body_count), 0, "cadence keeps all bodies visible")
		t.assert_eq(int(report.invalid_transform_count), 0, "cadence keeps valid transforms")

func _enemy_fixture_snapshot(ids: Array = []) -> Dictionary:
	var enemy_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
	var fixture_ids: Array = ids.duplicate()
	var explicit_empty := fixture_ids.size() == 1 and String(fixture_ids[0]) == "__empty__"
	if explicit_empty:
		fixture_ids.clear()
	elif fixture_ids.is_empty():
		fixture_ids = enemy_data.keys()
		fixture_ids.sort()
		fixture_ids.append("boss")
	var positions := PackedVector2Array()
	var radii := PackedFloat32Array()
	var hp_ratios := PackedFloat32Array()
	var type_ids := PackedStringArray()
	var flags := PackedInt32Array()
	var phases := PackedInt32Array()
	for index in range(fixture_ids.size()):
		var type_id := String(fixture_ids[index])
		var spec: Dictionary = enemy_data.get(type_id, {"radius": 28.0, "elite": false})
		positions.append(Vector2(72.0 + float(index % 8) * 72.0, 64.0 + float(index / 8) * 78.0))
		radii.append(float(spec.get("radius", 18.0)))
		hp_ratios.append(1.0)
		type_ids.append(type_id)
		var flag := 0
		if bool(spec.get("elite", false)):
			flag |= 1
		if type_id == "boss":
			flag |= 2
		if index == 0 or type_id == "boss":
			flag |= 8
		flags.append(flag)
		phases.append(0)
	return {
		"positions": positions,
		"radii": radii,
		"hp_ratios": hp_ratios,
		"type_ids": type_ids,
		"flags": flags,
		"phases": phases,
		"visible_count": fixture_ids.size(),
		"critical_missing": 0,
	}

func _grid_panel(viewport_size: Vector2 = Vector2(1280, 720), safe_rect: Rect2 = Rect2(64, 20, 1152, 680), weapon_count: int = 6):
	var state = _state("ios_ultra")
	state.weapons.clear()
	state.passives.clear()
	var weapon_ids: Array = state.weapon_defs.keys()
	var passive_ids: Array = state.passive_defs.keys()
	weapon_ids.sort()
	passive_ids.sort()
	for index in range(mini(weapon_count, weapon_ids.size())):
		state.weapons[String(weapon_ids[index])] = 1 + index % 3
	for index in range(6):
		state.passives[String(passive_ids[index])] = 1 + index % 2
	var panel = GridPanelScript.new()
	panel._ready()
	panel.configure(state, viewport_size, safe_rect, true)
	return panel
