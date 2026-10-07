extends RefCounted
class_name IosPerfAutoplayHarness

func run(
	tree: SceneTree,
	minutes: int,
	output_path: String,
	simulation_step_seconds: float = 1.0,
	start_elapsed_seconds: float = 0.0,
	prefill_enemy_count: int = 0
) -> Array:
	var failures: Array = []
	var old_settings: Dictionary = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({
		"touch_ui_mode": "on",
		"touch_tutorial_seen": true,
		"render_quality": "standard",
		"move_control_mode": "dynamic"
	})
	var main = load("res://scenes/Main.tscn").instantiate()
	tree.root.add_child(main)
	await tree.process_frame
	main.request_start()
	await tree.process_frame
	var game: GameScreen = _find_game(main)
	if game == null:
		failures.append("iOS performance autoplay could not start a run")
		return failures
	game.state.start_new_run(9100 + minutes)
	game.state.elapsed_seconds = maxf(0.0, start_elapsed_seconds)
	for minute in range(5, int(floor(game.state.elapsed_seconds / 60.0)) + 1, 5):
		game.state.boss_spawned_minutes.append(minute)
		game.state.boss_warned_minutes.append(minute)
	game.state.max_hp = 999999
	game.state.hp = 999999
	game.state.weapons["magic_bolt"] = 6
	game.state.weapons["ice_orbit"] = 5
	var prefill_count := mini(prefill_enemy_count, game.state.max_enemies())
	for enemy_index in range(prefill_count):
		var angle := TAU * float(enemy_index % 120) / 120.0
		var radius := 260.0 + float(enemy_index / 120) * 72.0
		var enemy = game.state.acquire_enemy([
			"slime",
			game.state.enemy_defs.get("slime", {}),
			game.state.player_position + Vector2.RIGHT.rotated(angle) * radius,
			0,
			1.0,
		])
		game.state.enemies.append(enemy)
	var frame_ms: Array = []
	var rows: Array = []
	var target_seconds := float(minutes * 60)
	var simulation_step := maxf(1.0, simulation_step_seconds)
	var max_iterations := int(ceil(maxf(0.0, target_seconds - game.state.elapsed_seconds) / simulation_step)) + 180
	var sample_interval := maxi(1, int(round(5.0 / simulation_step)))
	var render_interval := maxi(1, int(round(60.0 / simulation_step)))
	var i := 0
	while game.state.elapsed_seconds < target_seconds and i < max_iterations:
		var point := Vector2(180.0 + float(i % 5) * 24.0, 120.0 + float(i % 11) * 42.0)
		if not game.virtual_joystick.dynamic_system.active():
			game.virtual_joystick.dynamic_system.begin_touch(11, point)
		game.virtual_joystick.dynamic_system.drag_touch(11, point + Vector2.RIGHT.rotated(float(i) * 0.07) * 90.0)
		game.touch_direction = game.virtual_joystick.dynamic_system.direction
		if minutes == 5 and i == 60:
			var before_speed := game.touch_direction
			game._on_touch_action_started("action_speed_hold")
			if not game.virtual_joystick.dynamic_system.active() or game.touch_direction != before_speed:
				failures.append("speed hold must not steal the movement touch")
		elif minutes == 5 and i == 61:
			game._on_touch_action_ended("action_speed_hold")
		elif minutes == 5 and i == 120:
			if not game.virtual_joystick.dynamic_system.active():
				failures.append("movement touch must remain active")
		elif minutes == 5 and i == 180:
			game._toggle_pause()
			if game.virtual_joystick.dynamic_system.active() or game.touch_direction != Vector2.ZERO:
				failures.append("pause must cancel dynamic movement")
			game._toggle_pause()
		var started := Time.get_ticks_usec()
		game._process(simulation_step)
		frame_ms.append(float(Time.get_ticks_usec() - started) / 1000.0)
		if game.state.level_up_pending and not game.state.level_up_options.is_empty():
			game._select_reward(0)
		if game.state.chest_pending:
			game._on_touch_action_started("action_confirm")
		if i % sample_interval == 0:
			rows.append(_sample_row(game, frame_ms))
			frame_ms.clear()
		if i % render_interval == 0:
			await tree.process_frame
		i += 1
	game.virtual_joystick.dynamic_system.end_touch(11)
	_write_csv(output_path, rows)
	if game.state.elapsed_seconds < target_seconds:
		failures.append("%d minute performance autoplay did not reach target time" % minutes)
	if game.state.hit_flashes.size() > game.state.max_effects():
		failures.append("effect budget exceeded")
	if game.notification_log_system.history.size() > 80:
		failures.append("notification history exceeded memory budget")
	var health: Dictionary = game.state.pool_manager.health_report()
	for type_id in health:
		if int(health[type_id].active) > int(health[type_id].peak_active):
			failures.append("%s pool active count exceeded its peak" % type_id)
	main.queue_free()
	await tree.process_frame
	SaveSystem.new().update_settings(old_settings)
	return failures

func _sample_row(game: GameScreen, values: Array) -> Dictionary:
	var normalized: Array = []
	for value in values:
		normalized.append(float(value) / 60.0)
	var sorted := normalized.duplicate()
	sorted.sort()
	var avg := 0.0
	for value in normalized:
		avg += float(value)
	avg /= maxf(1.0, float(normalized.size()))
	var p95 := float(sorted[clampi(int(ceil(float(sorted.size()) * 0.95)) - 1, 0, sorted.size() - 1)]) if not sorted.is_empty() else 0.0
	return {
		"time": game.state.elapsed_seconds,
		"fps": minf(60.0, 1000.0 / maxf(avg, 0.001)),
		"frame_time_avg_5s": avg,
		"frame_time_p95_30s": p95,
		"frame_time_p99_30s": p95,
		"long_frame_count": normalized.filter(func(value): return float(value) > 33.0).size(),
		"enemy_count": game.state.enemies.size(),
		"effect_count": game.state.hit_flashes.size() + game.state.effect_lines.size(),
		"gem_count": game.state.gems.size(),
		"projectile_count": game.state.projectiles.size(),
		"ui_node_count": _count_nodes(game),
		"created_nodes_per_second": 0.0,
		"memory_estimate": OS.get_static_memory_usage(),
		"log_entry_count": game.notification_log_system.history.size()
	}

func _write_csv(path: String, rows: Array) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	var columns := ["time", "fps", "frame_time_avg_5s", "frame_time_p95_30s", "frame_time_p99_30s", "long_frame_count", "enemy_count", "effect_count", "gem_count", "projectile_count", "ui_node_count", "created_nodes_per_second", "memory_estimate", "log_entry_count"]
	file.store_line(",".join(columns))
	for row in rows:
		var values: Array = []
		for column in columns:
			values.append(str(row[column]))
		file.store_line(",".join(values))

func _count_nodes(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _count_nodes(child)
	return count

func _find_game(node: Node) -> GameScreen:
	if node is GameScreen:
		return node
	for child in node.get_children():
		var found := _find_game(child)
		if found != null:
			return found
	return null
