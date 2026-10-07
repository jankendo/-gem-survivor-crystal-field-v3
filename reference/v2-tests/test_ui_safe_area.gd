extends RefCounted

const UiSafeAreaSystemScript = preload("res://scripts/systems/UiSafeAreaSystem.gd")

func run(t) -> void:
	test_safe_rect_contains_main_hud_at_target_resolutions(t)
	test_ui_scale_is_clamped_and_applied(t)
	test_indicator_area_stays_inside_screen(t)

func test_safe_rect_contains_main_hud_at_target_resolutions(t) -> void:
	var system = UiSafeAreaSystemScript.new()
	var layout = JSON.parse_string(FileAccess.open("res://data/ui_layout.json", FileAccess.READ).get_as_text())
	for pair in layout["supported_resolutions"]:
		var size = Vector2(float(pair[0]), float(pair[1]))
		var safe = system.safe_rect(size, layout)
		var hud = Rect2(Vector2(float(layout.get("hud_side_margin", 28)), float(layout.get("hud_top_margin", 18))), Vector2(size.x - 56.0, 130.0))
		t.assert_true(safe.encloses(hud.grow(-8.0)), "safe area should contain HUD for %s" % str(size))

func test_ui_scale_is_clamped_and_applied(t) -> void:
	var system = UiSafeAreaSystemScript.new()
	var layout = JSON.parse_string(FileAccess.open("res://data/ui_layout.json", FileAccess.READ).get_as_text())
	t.assert_true(system.ui_scale_for(Vector2(1280, 720), 1.0, layout) <= 1.0, "small screen scale should not exceed 1")
	t.assert_true(system.ui_scale_for(Vector2(1920, 1080), 1.3, layout) <= float(layout.get("ui_scale_max", 1.18)), "large requested scale should clamp")

func test_indicator_area_stays_inside_screen(t) -> void:
	var system = UiSafeAreaSystemScript.new()
	var layout = JSON.parse_string(FileAccess.open("res://data/ui_layout.json", FileAccess.READ).get_as_text())
	var safe = system.safe_rect(Vector2(1280, 720), layout)
	var indicator = Rect2(Vector2(64, 82), Vector2(180, 52))
	t.assert_true(safe.encloses(indicator), "indicator should fit inside safe area")

