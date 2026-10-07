extends SceneTree

const Harness = preload("res://tests/helpers/BalanceAutoPlayHarness.gd")
const Assertions = preload("res://tests/helpers/BalanceAutoPlayAssertions.gd")

func _initialize() -> void:
	var metrics = await Harness.new().run(self, {
		"category": "lightning", "seed": 8813,
		"weapons": {"thunder_chain": 6, "echo_bell": 5},
		"passives": {"cooldown": 3, "area": 3, "might": 2, "choke_point": 2},
		"hp": 20000
	})
	Assertions.new().finish(self, "lightning", metrics)
