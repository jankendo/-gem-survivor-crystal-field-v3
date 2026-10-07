extends RefCounted

const Resolver = preload("res://scripts/systems/EffectiveSettingsResolver.gd")

func run(t) -> void:
	var effective := Resolver.new().resolve({"battery_saver": true, "effect_density": "high", "touch_haptics": true})
	t.assert_eq(effective.get("effect_density"), "minimal", "battery saver must force minimal effects at runtime")
	t.assert_eq(effective.get("target_render_fps"), 30, "battery saver must target 30 fps")
	t.assert_true(not bool(effective.get("touch_haptics", true)), "battery saver must disable haptics")
