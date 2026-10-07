extends SceneTree

const Harness = preload("res://tests/helpers/BalanceAutoPlayHarness.gd")
const Assertions = preload("res://tests/helpers/BalanceAutoPlayAssertions.gd")

func _initialize() -> void:
	var metrics = await Harness.new().run(self, {
		"category": "explosion", "seed": 8815,
		"weapons": {"bomb_seed": 6, "magma_core": 5},
		"passives": {"area": 3, "projectile_count": 2, "might": 2, "armor": 2},
		"hp": 20000
	})
	Assertions.new().finish(self, "explosion", metrics)
