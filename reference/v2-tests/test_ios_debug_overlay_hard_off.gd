extends RefCounted

const DebugOverlayPolicySystemScript = preload("res://scripts/systems/DebugOverlayPolicySystem.gd")

func run(t) -> void:
	var policy = DebugOverlayPolicySystemScript.new()
	policy.configure({"developer_mode": true}, "iOS", false, true, false)
	t.assert_true(not policy.can_create_overlay_node(), "iOS must not create a debug overlay node")
	t.assert_true(not policy.should_show(), "iOS must keep developer diagnostics hidden")
	t.assert_true(not policy.toggle_hidden(), "iOS must ignore the desktop debug shortcut")
	for term in policy.FORBIDDEN_IOS_TEXT:
		t.assert_true(policy.normal_ui_contains_forbidden_text(String(term)), "iOS forbidden text must include %s" % term)

	policy.configure({"developer_mode": true}, "Windows", true, false, false)
	t.assert_true(not policy.can_create_overlay_node(), "release builds must not create a debug overlay node")

	policy.configure({"developer_mode": true}, "Windows", false, true, true)
	t.assert_true(not policy.can_create_overlay_node(), "desktop touch preview must not create a debug overlay node")

	policy.configure({"developer_mode": false}, "Windows", false, false, false)
	t.assert_true(policy.can_create_overlay_node(), "desktop debug builds may create a hidden inert overlay node")
	t.assert_true(not policy.should_show(), "desktop default must keep diagnostics hidden")
	t.assert_true(policy.toggle_hidden(), "Ctrl+F12 may explicitly unlock diagnostics on desktop only")

	var old_settings: Dictionary = SaveSystem.new().load_data().get("settings", {}).duplicate(true)
	SaveSystem.new().update_settings({"touch_ui_mode": "on", "developer_mode": true, "developer_overlay": true})
	var game = load("res://scenes/Game.tscn").instantiate()
	game._ready()
	t.assert_true(game.debug_overlay_label == null, "touch mode must not instantiate the developer overlay Control")
	game._toggle_pause()
	t.assert_true(game.debug_overlay_label == null, "pause must not recreate the developer overlay")
	game._toggle_expanded_map()
	t.assert_true(game.debug_overlay_label == null, "expanded map must not recreate the developer overlay")
	game.free()
	SaveSystem.new().update_settings(old_settings)
