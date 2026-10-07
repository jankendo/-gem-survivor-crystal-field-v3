extends RefCounted

const State = preload("res://scripts/core/SurvivorState.gd")
const Core = preload("res://scripts/systems/CorePickupChoiceSystem.gd")

func run(t) -> void:
	var state = State.new()
	state.start_new_run(60606, "core-enabled")
	state.unlocked_weapon_ids = ["magic_bolt", "ice_orbit"]
	state.disabled_weapon_ids = ["ice_orbit"]
	var options := Core.new()._options(state, "weapon", 5)
	t.assert_true(not _ids(options).has("ice_orbit"), "disabled weapon must not enter core choices")

func _ids(options: Array) -> Array:
	return options.map(func(option): return String(option.get("id", "")))
