extends RefCounted

func run(t) -> void:
	test_project_window_settings(t)
	test_target_resolutions_fit_base_canvas(t)
	test_core_layout_scenes_instantiate(t)

func test_project_window_settings(t) -> void:
	t.assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1280, "viewport width should be 1280")
	t.assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 720, "viewport height should be 720")
	t.assert_eq(String(ProjectSettings.get_setting("display/window/stretch/mode")), "canvas_items", "stretch mode should be canvas_items")
	t.assert_eq(String(ProjectSettings.get_setting("display/window/stretch/aspect")), "keep", "stretch aspect should be keep")

func test_core_layout_scenes_instantiate(t) -> void:
	for path in ["res://scenes/Main.tscn", "res://scenes/Game.tscn", "res://scenes/Result.tscn", "res://scenes/RewardPopup.tscn"]:
		var packed: PackedScene = load(path)
		var node: Node = packed.instantiate()
		t.assert_true(node != null, "%s should instantiate" % path)
		node.free()

func test_target_resolutions_fit_base_canvas(t) -> void:
	var base := Vector2(1280, 720)
	var targets := [
		Vector2(1280, 720),
		Vector2(1366, 768),
		Vector2(1600, 900),
		Vector2(1920, 1080)
	]
	for i in range(targets.size()):
		var target: Vector2 = targets[i]
		var scale: float = minf(target.x / base.x, target.y / base.y)
		t.assert_true(scale >= 1.0, "%s should not shrink below base UI scale" % str(target))
		t.assert_true(base.x * scale <= target.x + 1.0, "%s should fit width with keep aspect" % str(target))
		t.assert_true(base.y * scale <= target.y + 1.0, "%s should fit height with keep aspect" % str(target))
