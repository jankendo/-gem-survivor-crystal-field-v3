extends SceneTree

const Harness = preload("res://tests/helpers/BalanceAutoPlayHarness.gd")
const Assertions = preload("res://tests/helpers/BalanceAutoPlayAssertions.gd")

func _initialize() -> void:
	var metrics = await Harness.new().run(self, {
		"category": "poison", "seed": 8814,
		"weapons": {"poison_mist": 6, "thorn_seed": 5},
		"passives": {"area": 3, "curse": 2, "poison_vessel": 3, "armor": 2},
		"hp": 20000
	})
	var failures: Array = []
	if int(metrics.damage) <= int(metrics.damage_at_five):
		failures.append("poison build should continue adding meaningful damage after five minutes")
	Assertions.new().finish(self, "poison", metrics, failures)
