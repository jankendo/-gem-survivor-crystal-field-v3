extends RefCounted

const BudgetScript = preload("res://scripts/systems/IosRenderBudgetSystem.gd")
const OptimizerScript = preload("res://scripts/systems/IosEnergyOptimizer.gd")
const BackgroundScript = preload("res://scripts/systems/IosBackgroundThrottleSystem.gd")
const TouchScript = preload("res://scripts/systems/TouchControlSystem.gd")

func run(t) -> void:
	var budget = BudgetScript.new()
	var standard: Dictionary = budget.profile("standard")
	var saver: Dictionary = budget.profile("battery_saver")
	t.assert_eq(int(standard.get("target_fps", 0)), 60, "standard profile should target 60 fps")
	t.assert_eq(int(saver.get("target_fps", 0)), 30, "battery saver should target 30 fps")
	t.assert_true(budget.preserves_quality("standard"), "standard profile must preserve quality")
	t.assert_true(not budget.preserves_quality("battery_saver"), "battery saver should reduce rendered quality without changing simulation")
	t.assert_true(float(saver.get("minimap_update_interval", 0.0)) > float(standard.get("minimap_update_interval", 0.0)), "battery saver should reduce update frequency")

	var optimizer = OptimizerScript.new()
	optimizer.configure({"battery_saver": false})
	t.assert_true(optimizer.should_update("hud", "same", "hud_update_interval", 0.1), "first HUD update should run")
	t.assert_true(not optimizer.should_update("hud", "same", "hud_update_interval", 0.1), "unchanged HUD must not update every frame")
	optimizer.tick(0.11)
	t.assert_true(optimizer.should_update("hud", "same", "hud_update_interval", 0.1), "HUD should refresh after its bounded interval")

	var root := Node.new()
	var child := Node.new()
	root.add_child(child)
	BackgroundScript.new().set_branch_active(root, false)
	t.assert_true(not root.is_processing() and not child.is_processing(), "hidden branches should stop process work")
	root.free()

	var touch = TouchScript.new()
	touch.configure({"touch_ui_mode": "on", "touch_haptics": true, "battery_saver": false}, "iOS")
	for i in range(25):
		touch.feedback_light()
	t.assert_eq(touch.haptic_count, 0, "Phase 9 removes touch haptics even when legacy setting is true")
	touch.configure({"touch_ui_mode": "on", "touch_haptics": true, "battery_saver": true}, "iOS")
	for i in range(15):
		touch.feedback_light()
	t.assert_eq(touch.haptic_count, 0, "battery saver must not re-enable haptics")
