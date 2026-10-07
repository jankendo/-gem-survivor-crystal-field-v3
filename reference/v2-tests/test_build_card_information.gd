extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9402, "")
	t.assert_true(state.get_weapon_label().find("武器") >= 0, "weapon card label should use Japanese equipment term")
	t.assert_true(state.get_passive_label().find("パッシブ") >= 0, "passive card label should use Japanese passive term")
