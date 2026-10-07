extends SceneTree

const RendererScript = preload("res://scripts/systems/EnemyBatchRenderer2D.gd")
const BACKGROUND := Color(0.01, 0.015, 0.025)

class RenderProbe:
	extends Control
	var renderer

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.015, 0.025), true)
		renderer.submit(get_canvas_item())

func _initialize() -> void:
	var fallback_renderer = RendererScript.new()
	var snapshot := _snapshot()
	fallback_renderer.update_snapshot(snapshot, Vector2(320, 180), 1.0)
	if DisplayServer.get_name() == "headless" or OS.has_feature("headless"):
		var report: Dictionary = fallback_renderer.validation_report(snapshot)
		var drawable := fallback_renderer.has_drawable_meshes()
		print("PHASE12_RENDER_PROBE_HEADLESS drawable_meshes=%s missing=%d transparent=%d invalid_mesh=%d invalid_texture=%d invalid_transform=%d" % [str(drawable), int(report.missing_body_count), int(report.transparent_body_count), int(report.invalid_mesh_count), int(report.invalid_texture_count), int(report.invalid_transform_count)])
		quit(0 if drawable and int(report.missing_body_count) == 0 and int(report.transparent_body_count) == 0 and int(report.invalid_mesh_count) == 0 and int(report.invalid_texture_count) == 0 and int(report.invalid_transform_count) == 0 else 1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var probe := RenderProbe.new()
	probe.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(probe)
	probe.renderer = fallback_renderer
	probe.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var enemy_pixels := 0
	var missing_ids := PackedStringArray()
	var transparent_ids := PackedStringArray()
	for fixture in snapshot.probe_boxes:
		var count := _foreground_pixels(image, fixture.rect)
		enemy_pixels += count
		if count == 0:
			missing_ids.append(String(fixture.id))
	var report: Dictionary = fallback_renderer.validation_report(snapshot)
	for index in report.transparent_indices:
		if int(index) >= 0 and int(index) < snapshot.type_ids.size():
			transparent_ids.append(String(snapshot.type_ids[int(index)]))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output/phase12"))
	image.save_png("res://test-output/phase12/ultra_enemy_render_probe.png")
	print("PHASE12_RENDER_PROBE enemy_pixels=%d size=%dx%d expected=%d detected=%d missing=%s transparent=%s invalid_mesh=%d invalid_texture=%d invalid_transform=%d critical_missing=%d" % [enemy_pixels, image.get_width(), image.get_height(), int(report.expected_body_count), int(report.detected_body_count), ",".join(missing_ids), ",".join(transparent_ids), int(report.invalid_mesh_count), int(report.invalid_texture_count), int(report.invalid_transform_count), int(report.critical_missing)])
	quit(0 if missing_ids.is_empty() and transparent_ids.is_empty() and int(report.missing_body_count) == 0 and int(report.transparent_body_count) == 0 and int(report.invalid_mesh_count) == 0 and int(report.invalid_texture_count) == 0 and int(report.invalid_transform_count) == 0 and int(report.critical_missing) == 0 else 1)

func _snapshot() -> Dictionary:
	var enemy_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies.json"))
	var ids: Array = enemy_data.keys()
	ids.sort()
	ids.append("boss")
	var positions := PackedVector2Array()
	var radii := PackedFloat32Array()
	var hp_ratios := PackedFloat32Array()
	var type_ids := PackedStringArray()
	var flags := PackedInt32Array()
	var phases := PackedInt32Array()
	var probe_boxes: Array = []
	for index in range(ids.size()):
		var id := String(ids[index])
		var spec: Dictionary = enemy_data.get(id, {"radius": 34.0, "elite": false})
		var pos := Vector2(72.0 + float(index % 8) * 72.0, 64.0 + float(index / 8) * 78.0)
		var radius := float(spec.get("radius", 18.0))
		var flag := 0
		if bool(spec.get("elite", false)):
			flag |= 1
		if id == "boss":
			flag |= 2
		if index == 0 or id == "boss":
			flag |= 8
		positions.append(pos)
		radii.append(radius)
		hp_ratios.append(1.0)
		type_ids.append(id)
		flags.append(flag)
		phases.append(0)
		probe_boxes.append({"id": id, "rect": Rect2(pos - Vector2(34, 34), Vector2(68, 68))})
	return {
		"positions": positions,
		"radii": radii,
		"hp_ratios": hp_ratios,
		"type_ids": type_ids,
		"flags": flags,
		"phases": phases,
		"visible_count": ids.size(),
		"critical_missing": 0,
		"probe_boxes": probe_boxes,
	}

func _foreground_pixels(image: Image, rect: Rect2) -> int:
	var clipped := rect.intersection(Rect2(Vector2.ZERO, Vector2(image.get_width(), image.get_height())))
	var count := 0
	for y in range(int(clipped.position.y), int(clipped.end.y)):
		for x in range(int(clipped.position.x), int(clipped.end.x)):
			var color := image.get_pixel(x, y)
			var difference := absf(color.r - BACKGROUND.r) + absf(color.g - BACKGROUND.g) + absf(color.b - BACKGROUND.b)
			if difference > 0.12:
				count += 1
	return count
