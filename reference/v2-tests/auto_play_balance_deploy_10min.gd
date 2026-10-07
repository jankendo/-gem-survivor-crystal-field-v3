extends SceneTree

const Harness = preload("res://tests/helpers/BalanceAutoPlayHarness.gd")
const Assertions = preload("res://tests/helpers/BalanceAutoPlayAssertions.gd")

func _initialize() -> void:
	var metrics = await Harness.new().run(self, {
		"category": "deploy", "seed": 8816,
		"weapons": {"rune_gate": 6, "guardian_wall": 5},
		"passives": {"area": 3, "cooldown": 2, "armor": 3, "room_mastery": 2},
		"hp": 21000
	})
	Assertions.new().finish(self, "deploy", metrics)
