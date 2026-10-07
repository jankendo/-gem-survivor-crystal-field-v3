extends SceneTree

const Harness = preload("res://tests/helpers/BalanceAutoPlayHarness.gd")
const Assertions = preload("res://tests/helpers/BalanceAutoPlayAssertions.gd")

func _initialize() -> void:
	var metrics = await Harness.new().run(self, {
		"category": "melee", "seed": 8812, "strategy": "melee",
		"weapons": {"soul_scythe": 6, "corridor_blade": 5},
		"passives": {"might": 3, "area": 3, "armor": 3, "regen": 2},
		"hp": 22000
	})
	var failures: Array = []
	if int(metrics.damage_taken) <= 0:
		failures.append("melee build should demonstrate contact-risk damage")
	Assertions.new().finish(self, "melee", metrics, failures)
