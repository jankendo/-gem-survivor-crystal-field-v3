extends RefCounted
class_name Phase6BenchmarkHarness

const SaveSystemScript = preload("res://scripts/systems/SaveSystem.gd")
const MetricsScript = preload("res://scripts/performance/Phase6MetricsSystem.gd")

func run(tree: SceneTree, seconds: float, output_stem: String, label: String, seed: int = 60606) -> Dictionary:
	var save := SaveSystemScript.new()
	var old_settings: Dictionary = save.load_data().get("settings", {}).duplicate(true)
	save.update_settings({
		"touch_ui_mode": "on",
		"touch_tutorial_seen": true,
		"render_quality": "standard",
		"move_control_mode": "dynamic",
		"phase6_benchmark": true
	})
	var main = load("res://scenes/Main.tscn").instantiate()
	tree.root.add_child(main)
	await tree.process_frame
	main.request_start()
	await tree.process_frame
	if bool(main.get("help_visible")) and main.has_method("accept_help"):
		main.accept_help()
		await tree.process_frame
	var game: GameScreen = _find_game(main)
	if game == null:
		var failed := {"ok": false, "error": "GameScreen not found"}
		_write_json(output_stem, failed)
		return failed
	game.set_process(false)
	var metrics = MetricsScript.new()
	metrics.configure(true)
	game.enable_phase6_metrics(metrics)
	game.state.start_new_run(seed)
	game.state.max_hp = 999999
	game.state.hp = 999999
	game.state.weapons["magic_bolt"] = 6
	game.state.weapons["ice_orbit"] = 5
	var delta := 1.0 / 60.0
	var target_frames := int(round(seconds / delta))
	var frame_ms: Array = []
	var rows: Array = []
	for i in range(target_frames):
		_drive_touch(game, i)
		var started := Time.get_ticks_usec()
		game._process(delta)
		frame_ms.append(float(Time.get_ticks_usec() - started) / 1000.0)
		if game.state.level_up_pending and not game.state.level_up_options.is_empty():
			game._select_reward(0)
		if game.state.chest_pending:
			game._on_touch_action_started("action_confirm")
		if i % 60 == 59:
			rows.append(_sample_row(game, frame_ms, i + 1))
			game.arena_view.queue_redraw()
			await tree.process_frame
	if game.virtual_joystick != null and game.virtual_joystick.dynamic_system.active():
		game.virtual_joystick.dynamic_system.end_touch(11)
	var summary := _summary(game, frame_ms, rows, label, seed)
	_write_csv(output_stem, rows)
	_write_json(output_stem, summary)
	_write_markdown(output_stem, summary)
	main.queue_free()
	await tree.process_frame
	save.update_settings(old_settings)
	return summary

func _drive_touch(game: GameScreen, frame: int) -> void:
	if game.virtual_joystick == null:
		return
	var point := Vector2(180.0 + float(frame % 5) * 24.0, 120.0 + float(frame % 11) * 42.0)
	if not game.virtual_joystick.dynamic_system.active():
		game.virtual_joystick.dynamic_system.begin_touch(11, point)
	game.virtual_joystick.dynamic_system.drag_touch(11, point + Vector2.RIGHT.rotated(float(frame) * 0.07) * 90.0)
	game.touch_direction = game.virtual_joystick.dynamic_system.direction

func _sample_row(game: GameScreen, frame_ms: Array, frame: int) -> Dictionary:
	var metrics := game.phase6_metrics_snapshot()
	var counters: Dictionary = metrics.get("counters", {})
	var gauges: Dictionary = metrics.get("gauges", {})
	var window := frame_ms.slice(maxi(0, frame_ms.size() - 300), frame_ms.size())
	return {
		"time": game.state.elapsed_seconds,
		"frame": frame,
		"fps": minf(60.0, 1000.0 / maxf(_average(window), 0.001)),
		"frame_time_avg_5s": _average(window),
		"frame_time_p50": _percentile(window, 0.50),
		"frame_time_p95": _percentile(window, 0.95),
		"frame_time_p99": _percentile(window, 0.99),
		"long_frame_count_over_33ms": _count_over(frame_ms, 33.0),
		"enemy_count": game.state.enemies.size(),
		"projectile_count": game.state.projectiles.size() + game.state.enemy_projectiles.size(),
		"effect_count": game.state.hit_flashes.size() + game.state.effect_lines.size() + game.state.floating_texts.size(),
		"gem_count": game.state.gems.size(),
		"process_calls": counters.get("process_calls", 0),
		"refresh_calls": counters.get("refresh_calls", 0),
		"label_text_attempts": counters.get("label_text_attempts", 0),
		"label_text_updates": counters.get("label_text_updates", 0),
		"progress_value_attempts": counters.get("progress_value_attempts", 0),
		"progress_value_updates": counters.get("progress_value_updates", 0),
		"arena_queue_redraw_calls": counters.get("arena_queue_redraw_calls", 0),
		"arena_draw_calls": counters.get("arena_draw_calls", 0),
		"static_terrain_rebuilds": counters.get("static_terrain_rebuilds", 0),
		"static_tile_draw_submissions": counters.get("static_tile_draw_submissions", 0),
		"minimap_draw_calls": counters.get("minimap_draw_calls", 0),
		"minimap_cadence_updates": counters.get("minimap_cadence_updates", 0),
		"minimap_content_draws": counters.get("minimap_content_draws", 0),
		"enemy_spawn": counters.get("event_enemy_spawn", 0),
		"boss_spawn": counters.get("event_boss_spawn", 0),
		"kills": game.state.kills,
		"gems_collected": game.state.gems_collected,
		"max_enemy_count": gauges.get("max_enemy_count", game.state.enemies.size()),
		"max_projectile_count": gauges.get("max_projectile_count", game.state.projectiles.size()),
		"max_gem_count": gauges.get("max_gem_count", game.state.gems.size()),
		"max_effect_count": gauges.get("max_effect_count", game.state.hit_flashes.size() + game.state.effect_lines.size())
	}

func _summary(game: GameScreen, frame_ms: Array, rows: Array, label: String, seed: int) -> Dictionary:
	var metrics := game.phase6_metrics_snapshot()
	var counters: Dictionary = metrics.get("counters", {})
	var gauges: Dictionary = metrics.get("gauges", {})
	return {
		"ok": true,
		"label": label,
		"commit_sha": _git_sha(),
		"godot_version": Engine.get_version_info(),
		"project_features": ProjectSettings.get_setting("application/config/features", PackedStringArray()),
		"project_rendering_method": ProjectSettings.get_setting("rendering/renderer/rendering_method", ""),
		"runtime_rendering_method": _rendering_method(),
		"runtime_rendering_driver": _rendering_driver(),
		"benchmark_seed": seed,
		"duration_seconds": game.state.elapsed_seconds,
		"average_fps": minf(60.0, 1000.0 / maxf(_average(frame_ms), 0.001)),
		"frame_time_p50": _percentile(frame_ms, 0.50),
		"frame_time_p95": _percentile(frame_ms, 0.95),
		"frame_time_p99": _percentile(frame_ms, 0.99),
		"long_frame_count_over_33ms": _count_over(frame_ms, 33.0),
		"enemy_spawn": counters.get("event_enemy_spawn", 0),
		"boss_spawn": counters.get("event_boss_spawn", 0),
		"alive": game.state.enemies.size(),
		"kills": game.state.kills,
		"gems_collected": game.state.gems_collected,
		"max_enemy_count": gauges.get("max_enemy_count", game.state.enemies.size()),
		"max_projectile_count": gauges.get("max_projectile_count", game.state.projectiles.size()),
		"max_gem_count": gauges.get("max_gem_count", game.state.gems.size()),
		"max_effect_count": gauges.get("max_effect_count", game.state.hit_flashes.size() + game.state.effect_lines.size()),
		"metrics": metrics,
		"sample_count": rows.size()
	}

func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())

func _percentile(values: Array, ratio: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(ceil(float(sorted.size()) * ratio)) - 1, 0, sorted.size() - 1)])

func _count_over(values: Array, threshold: float) -> int:
	var count := 0
	for value in values:
		if float(value) > threshold:
			count += 1
	return count

func _write_csv(stem: String, rows: Array) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(stem.get_base_dir()))
	var path := "%s.csv" % stem
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	if rows.is_empty():
		return
	var columns: Array = rows[0].keys()
	file.store_line(",".join(columns))
	for row in rows:
		var values: Array = []
		for column in columns:
			values.append(str(row[column]))
		file.store_line(",".join(values))

func _write_json(stem: String, summary: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(stem.get_base_dir()))
	var file := FileAccess.open("%s.json" % stem, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(summary, "\t"))

func _write_markdown(stem: String, summary: Dictionary) -> void:
	var file := FileAccess.open("%s.md" % stem, FileAccess.WRITE)
	if file == null:
		return
	file.store_line("# Phase 6 Benchmark")
	file.store_line("")
	for key in ["label", "commit_sha", "project_rendering_method", "runtime_rendering_method", "runtime_rendering_driver", "benchmark_seed", "average_fps", "frame_time_p50", "frame_time_p95", "frame_time_p99", "long_frame_count_over_33ms", "enemy_spawn", "boss_spawn", "alive", "kills", "max_enemy_count", "max_projectile_count", "max_gem_count", "max_effect_count"]:
		var value := str(summary.get(key, ""))
		file.store_line("- %s: %s" % [key, value if value != "" else "unavailable"])

func _rendering_method() -> String:
	if RenderingServer.has_method("get_current_rendering_method"):
		return String(RenderingServer.call("get_current_rendering_method"))
	return ""

func _rendering_driver() -> String:
	if RenderingServer.has_method("get_current_rendering_driver_name"):
		return String(RenderingServer.call("get_current_rendering_driver_name"))
	return ""

func _git_sha() -> String:
	var output: Array = []
	var code := OS.execute("git", ["rev-parse", "HEAD"], output, true)
	if code == 0 and not output.is_empty():
		return String(output[0]).strip_edges()
	return OS.get_environment("GITHUB_SHA")

func _find_game(node: Node) -> GameScreen:
	if node is GameScreen:
		return node as GameScreen
	for child in node.get_children():
		var found := _find_game(child)
		if found != null:
			return found
	return null
