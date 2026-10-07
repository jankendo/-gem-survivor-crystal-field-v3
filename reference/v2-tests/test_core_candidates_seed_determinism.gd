extends RefCounted

const State = preload("res://scripts/core/SurvivorState.gd")
const Core = preload("res://scripts/systems/CorePickupChoiceSystem.gd")

func run(t) -> void:
	var first = State.new()
	var second = State.new()
	first.start_new_run(60606, "core-seed")
	second.start_new_run(60606, "core-seed")
	t.assert_eq(_ids(Core.new()._options(first, "weapon", 3)), _ids(Core.new()._options(second, "weapon", 3)), "core candidates must be seed deterministic")

func _ids(options: Array) -> Array:
	return options.map(func(option): return String(option.get("id", "")))
