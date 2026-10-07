extends SceneTree

const OUT_DIR := "res://test-output/screenshots/v2_phase2"

var sizes := [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(1334, 750),
	Vector2i(2556, 1179),
	Vector2i(2732, 2048)
]
var screen_ids := [
	"title",
	"character_select",
	"shop",
	"collection",
	"run_hud",
	"momentum_hud",
	"level_up",
	"pause",
	"boss_warning",
	"result"
]
var rows: Array = []
var failures: Array = []
var old_settings: Dictionary = {}

func _initialize() -> void:
	await _run()
	SaveSystem.new().update_settings(old_settings)
	_write_report()
	if failures.is_empty():
		print("V2 Phase 2 screenshot QA OK: %d captures." % rows.size())
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _run() -> void:
	old_settings = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for size in sizes:
		var touch: bool = size.x >= 1334 and size.y <= 2048 and size.x != 1600 and size.x != 1920
		SaveSystem.new().update_settings({
			"touch_ui_mode": "on" if touch else "off",
			"touch_tutorial_seen": true,
			"safe_area_margin": 22.0 if touch else 0.0
		})
		SaveSystem.new().save_help_seen(true)
		for screen_id in screen_ids:
			await _capture_screen(size, screen_id, touch)

func _capture_screen(size: Vector2i, screen_id: String, touch: bool) -> void:
	root.size = size
	DisplayServer.window_set_size(size)
	var node: Node = await _build_screen(screen_id)
	if node == null:
		failures.append("%s %s could not build" % [str(size), screen_id])
		return
	root.add_child(node)
	await process_frame
	await process_frame
	var check: Dictionary = _layout_checks(node, size, screen_id, touch)
	var file_name: String = "%s_%dx%d.png" % [screen_id, size.x, size.y]
	var path: String = "%s/%s" % [OUT_DIR, file_name]
	var png_result: int = _save_diagnostic_png(path, size, screen_id, check)
	if png_result != OK:
		failures.append("%s failed to save PNG: %s" % [screen_id, str(png_result)])
	check["screen"] = screen_id
	check["size"] = {"w": size.x, "h": size.y}
	check["path"] = path
	rows.append(check)
	node.queue_free()
	await process_frame

func _save_diagnostic_png(path: String, size: Vector2i, screen_id: String, check: Dictionary) -> int:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.03, 0.05, 0.09, 1.0))
	var margin := int(maxi(18, size.y / 42))
	var accent := _screen_color(screen_id)
	image.fill_rect(Rect2i(margin, margin, size.x - margin * 2, maxi(6, size.y / 90)), accent)
	match screen_id:
		"title", "character_select", "shop", "collection":
			_draw_rect(image, Rect2i(margin, margin * 3, int(size.x * 0.28), size.y - margin * 5), Color(0.08, 0.14, 0.24, 1.0))
			_draw_rect(image, Rect2i(int(size.x * 0.34), margin * 3, size.x - int(size.x * 0.38), size.y - margin * 5), Color(0.06, 0.12, 0.20, 1.0))
		"run_hud", "momentum_hud", "level_up", "pause", "boss_warning":
			_draw_rect(image, Rect2i(margin, margin * 3, int(size.x * 0.26), int(size.y * 0.18)), Color(0.07, 0.14, 0.22, 1.0))
			_draw_rect(image, Rect2i(int(size.x * 0.30), margin * 4, int(size.x * 0.40), int(size.y * 0.10)), Color(0.10, 0.08, 0.22, 1.0))
			_draw_rect(image, Rect2i(int(size.x * 0.68), int(size.y * 0.68), int(size.x * 0.24), int(size.y * 0.22)), Color(0.06, 0.12, 0.20, 1.0))
		"result":
			_draw_rect(image, Rect2i(int(size.x * 0.18), margin * 3, int(size.x * 0.64), int(size.y * 0.68)), Color(0.07, 0.12, 0.21, 1.0))
			_draw_rect(image, Rect2i(int(size.x * 0.18), int(size.y * 0.78), int(size.x * 0.64), int(size.y * 0.10)), Color(0.10, 0.13, 0.22, 1.0))
	var safe_color: Color = Color(0.1, 0.85, 1.0, 0.22) if bool(check.get("passed", false)) else Color(1.0, 0.18, 0.32, 0.35)
	_draw_rect(image, Rect2i(margin, margin, size.x - margin * 2, size.y - margin * 2), safe_color, false)
	return image.save_png(path)

func _screen_color(screen_id: String) -> Color:
	var hash_value: int = abs(screen_id.hash())
	var hue: float = float(hash_value % 360) / 360.0
	return Color.from_hsv(hue, 0.62, 0.96, 1.0)

func _draw_rect(image: Image, rect: Rect2i, color: Color, filled: bool = true) -> void:
	if filled:
		image.fill_rect(rect, color)
		return
	var thickness := 3
	image.fill_rect(Rect2i(rect.position, Vector2i(rect.size.x, thickness)), color)
	image.fill_rect(Rect2i(Vector2i(rect.position.x, rect.end.y - thickness), Vector2i(rect.size.x, thickness)), color)
	image.fill_rect(Rect2i(rect.position, Vector2i(thickness, rect.size.y)), color)
	image.fill_rect(Rect2i(Vector2i(rect.end.x - thickness, rect.position.y), Vector2i(thickness, rect.size.y)), color)

func _build_screen(screen_id: String) -> Node:
	match screen_id:
		"title":
			var main = load("res://scenes/Main.tscn").instantiate()
			await process_frame
			return main
		"character_select":
			var main = load("res://scenes/Main.tscn").instantiate()
			root.add_child(main)
			await process_frame
			main.show_character_select()
			root.remove_child(main)
			return main
		"shop":
			var main = load("res://scenes/Main.tscn").instantiate()
			root.add_child(main)
			await process_frame
			main.show_shop()
			root.remove_child(main)
			return main
		"collection":
			var main = load("res://scenes/Main.tscn").instantiate()
			root.add_child(main)
			await process_frame
			main.show_collection()
			root.remove_child(main)
			return main
		"run_hud", "momentum_hud", "level_up", "pause", "boss_warning":
			var game = load("res://scenes/Game.tscn").instantiate()
			root.add_child(game)
			await process_frame
			if screen_id == "momentum_hud":
				game.state.v2_momentum_timer = 6.4
				game.state.v2_momentum_tier = 2
				game.state.v2_momentum_score_multiplier = 1.08
				game.state.v2_momentum_reason = "連続撃破"
				game._refresh()
			elif screen_id == "level_up":
				game.state.level_up_options = game.level_up_system.prepare_options(game.state, 3)
				game.state.level_up_pending = true
				game._refresh()
			elif screen_id == "pause":
				game._toggle_pause()
			elif screen_id == "boss_warning":
				game.boss_alert_label.text = "ボス接近"
				game.boss_alert_label.visible = true
				game.v2_feedback_director.ingest({"type": "boss_warning", "message": "ボス接近"}, 300.0)
				game._refresh_v2_phase2_hud()
			root.remove_child(game)
			return game
		"result":
			var result = load("res://scenes/Result.tscn").instantiate()
			root.add_child(result)
			await process_frame
			result.show_summary({
				"score": 12345,
				"best_score": 20000,
				"survival_time": 612.0,
				"level": 19,
				"kills": 680,
				"boss_defeats": 1,
				"max_weapon": "魔弾 Lv5",
				"evolved_weapon_ids": ["starbreaker_bolt"],
				"synergy_history": ["gem_engine"],
				"v2_peak_momentum_tier": 3,
				"v2_momentum_triggers": 5,
				"v2_momentum_active_time_total": 42.0,
				"v2_momentum_score_bonus": 520,
				"v2_momentum_main_trigger": "boss_defeat",
				"v2_momentum_trigger_counts": {"boss_defeat": 1, "kill_streak": 4},
				"currency_earned": 180,
				"currency_total": 520
			})
			root.remove_child(result)
			return result
	return null

func _layout_checks(node: Node, size: Vector2i, screen_id: String, touch: bool) -> Dictionary:
	var controls: Array = []
	_collect_controls(node, controls)
	var min_button := INF
	var narrow_labels := 0
	var offscreen := 0
	for control in controls:
		var rect: Rect2 = control.get_global_rect()
		if control is Button:
			min_button = minf(min_button, minf(rect.size.x, rect.size.y))
		if control is Label and String((control as Label).text).length() > 6 and rect.size.x < 42.0:
			narrow_labels += 1
		if rect.size.x < 0.0 or rect.size.y < 0.0:
			offscreen += 1
		if rect.position.x < -24.0 or rect.position.y < -24.0 or rect.end.x > float(size.x) + 24.0 or rect.end.y > float(size.y) + 24.0:
			offscreen += 1
	var overlap := false
	if screen_id == "momentum_hud" and node is GameScreen:
		overlap = (node as GameScreen).v2_momentum_panel.get_global_rect().intersects((node as GameScreen).v2_feedback_panel.get_global_rect())
	if min_button == INF:
		min_button = 0.0
	var passed := min_button >= (52.0 if touch else 38.0) and not overlap
	if not passed:
		failures.append("%s %s layout failed: min_button=%.1f overlap=%s" % [screen_id, str(size), min_button, str(overlap)])
	return {
		"touch_profile": touch,
		"control_count": controls.size(),
		"min_button_extent": min_button,
		"narrow_label_count": narrow_labels,
		"offscreen_count": offscreen,
		"momentum_feedback_overlap": overlap,
		"passed": passed
	}

func _collect_controls(node: Node, output: Array) -> void:
	if node is Control and (node as Control).visible:
		output.append(node)
	for child in node.get_children():
		_collect_controls(child, output)

func _write_report() -> void:
	var json_path := "%s/phase2_screenshot_manifest.json" % OUT_DIR
	var md_path := "%s/phase2_screenshot_report.md" % OUT_DIR
	var file := FileAccess.open(json_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures": rows, "failures": failures}, "\t"))
	var lines := [
		"# V2 Phase 2 Screenshot QA",
		"",
		"Built the actual title, character select, shop, collection, run HUD, Momentum HUD, level-up, pause, boss warning, and result scenes across Windows and iOS landscape profiles. PNG files are headless diagnostic captures because this runner uses Godot's dummy renderer; JSON/Markdown rows contain the layout checks from the live scene tree.",
		""
	]
	for row in rows:
		var size: Dictionary = row.get("size", {})
		lines.append("- %s %dx%d: %s, controls=%d, min_button=%.1f, offscreen=%d, narrow_labels=%d" % [
			String(row.get("screen", "")),
			int(size.get("w", 0)),
			int(size.get("h", 0)),
			"PASS" if bool(row.get("passed", false)) else "FAIL",
			int(row.get("control_count", 0)),
			float(row.get("min_button_extent", 0.0)),
			int(row.get("offscreen_count", 0)),
			int(row.get("narrow_label_count", 0))
		])
	if not failures.is_empty():
		lines.append("")
		lines.append("## Failures")
		for failure in failures:
			lines.append("- %s" % failure)
	var report := FileAccess.open(md_path, FileAccess.WRITE)
	report.store_string("\n".join(lines))
