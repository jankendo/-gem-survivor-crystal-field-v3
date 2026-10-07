extends RefCounted

const Resolver = preload("res://scripts/systems/EffectiveSettingsResolver.gd")

func run(t) -> void:
	var stored := {"battery_saver": true, "effect_density": "high", "background_particles": true}
	var resolver = Resolver.new()
	resolver.resolve(stored)
	t.assert_eq(stored.get("effect_density"), "high", "effective settings must not mutate stored effect density")
	t.assert_true(bool(stored.get("background_particles")), "effective settings must not mutate stored particles")
	stored["battery_saver"] = false
	t.assert_eq(resolver.resolve(stored).get("effect_density"), "high", "disabling battery saver must restore stored values")
