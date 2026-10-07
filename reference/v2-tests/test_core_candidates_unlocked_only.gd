extends RefCounted

const State = preload("res://scripts/core/SurvivorState.gd")
const Core = preload("res://scripts/systems/CorePickupChoiceSystem.gd")

func run(t) -> void:
	var state = State.new()
	state.start_new_run(60606, "core-unlocked")
	state.unlocked_weapon_ids = ["magic_bolt"]
	var options := Core.new()._options(state, "weapon", 8)
	for option in options:
		if String(option.get("kind", "")) != "decline":
			t.assert_eq(String(option.get("id", "")), "magic_bolt", "locked weapon must not enter core choices")
