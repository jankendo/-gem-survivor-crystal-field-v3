extends RefCounted

const Resolver = preload("res://scripts/systems/EffectiveSettingsResolver.gd")

func run(t) -> void:
	var stored := {"battery_saver": true, "enemy_count": 600, "spawn_rate": 4.0, "reward_multiplier": 1.0, "seed": 60606}
	var effective := Resolver.new().resolve(stored)
	for key in ["enemy_count", "spawn_rate", "reward_multiplier", "seed"]:
		t.assert_eq(effective.get(key), stored.get(key), "battery saver must preserve simulation key %s" % key)
