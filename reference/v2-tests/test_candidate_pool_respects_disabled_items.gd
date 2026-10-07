extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const LevelScript = preload("res://scripts/systems/LevelUpSystem.gd")
const DropScript = preload("res://scripts/systems/FieldDropSystem.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(811, "disabled-candidates")
	state.unlocked_weapon_ids = state.weapon_defs.keys()
	state.unlocked_passive_ids = state.passive_defs.keys()
	state.disabled_weapon_ids = ["ice_orbit", "blade_fan"]
	state.disabled_passive_ids = ["regen", "greed"]
	var levels = LevelScript.new()
	for i in range(80):
		var options := levels.prepare_options(state, 3)
		t.assert_true(not _contains(options, "weapon", "ice_orbit") and not _contains(options, "weapon", "blade_fan"), "level-up pool must exclude OFF weapons")
		t.assert_true(not _contains(options, "passive", "regen") and not _contains(options, "passive", "greed"), "level-up pool must exclude OFF passives")
	var drops = DropScript.new()
	for i in range(30):
		drops._apply_weapon_core(state)
		drops._apply_passive_core(state)
	t.assert_true(not state.weapons.has("ice_orbit") and not state.weapons.has("blade_fan"), "field rewards must exclude OFF weapons")
	t.assert_true(not state.passives.has("regen") and not state.passives.has("greed"), "field rewards must exclude OFF passives")
	t.assert_true(levels.has_regular_candidates(state), "limited OFF slots must not collapse the candidate pool")

func _contains(options: Array, kind: String, id: String) -> bool:
	for option in options:
		if String(option.get("kind", "")) == kind and String(option.get("id", "")) == id:
			return true
	return false
