extends RefCounted

const DefaultsScript = preload("res://scripts/systems/IosDefaultSettingsSystem.gd")
const OptimizerScript = preload("res://scripts/systems/IosEnergyOptimizer.gd")

func run(t) -> void:
	var defaults = DefaultsScript.new()
	var settings = defaults.apply_defaults({}, "iOS")
	t.assert_true(bool(settings.get("battery_saver", false)), "iOS default should enable battery saver")
	t.assert_eq(int(settings.get("target_fps", 0)), 30, "iOS default should target 30 fps")
	t.assert_eq(String(settings.get("render_quality", "")), "low", "iOS default should use low render quality")
	t.assert_true(not bool(settings.get("background_particles", true)), "iOS default should reduce background particles")
	t.assert_true(bool(settings.get("notch_protection", false)), "iOS default should enable Safe Play Area notch protection")
	t.assert_true(not bool(settings.get("touch_hit_test_debug", true)), "iOS default should keep touch debug off")
	t.assert_true(not bool(settings.get("touch_action_audit", true)), "iOS default should keep touch audit off")
	var optimizer = OptimizerScript.new()
	optimizer.configure(settings)
	t.assert_eq(int(optimizer.budget.get("target_fps", 0)), 30, "battery saver budget should be selected by iOS defaults")
