extends SceneTree

const Harness = preload("res://tests/helpers/BalanceAutoPlayHarness.gd")
const Assertions = preload("res://tests/helpers/BalanceAutoPlayAssertions.gd")

func _initialize() -> void:
	var metrics = await Harness.new().run(self, {
		"category": "ranged", "seed": 8811, "strategy": "retreat",
		"weapons": {"magic_bolt": 6, "mirror_shard": 5},
		"passives": {"might": 3, "cooldown": 3, "area": 2, "magnet": 2},
		"hp": 20000
	})
	var failures: Array = []
	if int(metrics.damage) > 450000:
		failures.append("ranged safety build exceeds its intended restrained damage ceiling")
	Assertions.new().finish(self, "ranged", metrics, failures)
