extends RefCounted

const DebugOverlaySystemScript = preload("res://scripts/systems/DebugOverlaySystem.gd")

func run(t) -> void:
	var overlay = DebugOverlaySystemScript.new()
	overlay.configure({"developer_overlay": true}, "iOS", false)
	t.assert_true(not overlay.should_show(), "iOS must never show the developer overlay")
	t.assert_eq(overlay.overlay_text(), "", "iOS overlay text must stay empty")
	t.assert_true(not overlay.toggle_hidden(), "hidden desktop command must not enable iOS overlay")

	overlay.configure({"developer_overlay": true}, "Windows", true)
	t.assert_true(not overlay.should_show(), "release builds must suppress developer overlay")

	overlay.configure({"developer_overlay": true}, "Windows", false)
	t.assert_true(not overlay.should_show(), "desktop overlay must default to hidden")
	t.assert_true(overlay.toggle_hidden(), "desktop Ctrl+F12 path may unlock the overlay")
	t.assert_true(overlay.overlay_text().contains("FPS"), "desktop debug overlay should contain diagnostics only after unlock")

