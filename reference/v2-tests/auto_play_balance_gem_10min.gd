extends SceneTree

const Harness = preload("res://tests/helpers/BalanceAutoPlayHarness.gd")
const Assertions = preload("res://tests/helpers/BalanceAutoPlayAssertions.gd")

func _initialize() -> void:
	var metrics = await Harness.new().run(self, {
		"category": "gem", "seed": 8817, "strategy": "retreat",
		"weapons": {"gem_turret": 6, "coin_orbit": 5},
		"passives": {"magnet": 3, "crystal_wallet": 3, "cooldown": 2, "armor": 2},
		"hp": 20000
	})
	Assertions.new().finish(self, "gem", metrics)
