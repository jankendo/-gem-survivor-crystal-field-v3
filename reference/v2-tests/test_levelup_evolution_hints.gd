extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const LevelUpSystemScript = preload("res://scripts/systems/LevelUpSystem.gd")

func run(t) -> void:
	test_weapon_option_contains_evolution_hint(t)
	test_passive_option_contains_related_evolution_hint(t)

func _state():
	var state = SurvivorStateScript.new()
	state.start_new_run(1616, "hint-seed")
	return state

func test_weapon_option_contains_evolution_hint(t) -> void:
	var state = _state()
	state.weapons["magic_bolt"] = 7
	state.passives["might"] = 2
	var option = LevelUpSystemScript.new()._make_option(state, "weapon", "magic_bolt")
	t.assert_true(String(option.get("evolution_hint", "")).find("進化先") >= 0, "weapon option should show evolution destination")
	t.assert_true(String(option.get("evolution_hint", "")).find("あと") >= 0, "weapon option should show shortage")

func test_passive_option_contains_related_evolution_hint(t) -> void:
	var state = _state()
	state.weapons["magic_bolt"] = 7
	state.passives["might"] = 2
	var option = LevelUpSystemScript.new()._make_option(state, "passive", "might")
	t.assert_true(String(option.get("evolution_hint", "")).find("魔弾") >= 0, "passive option should list related weapon")
	t.assert_true(String(option.get("evolution_hint", "")).find("星砕き") >= 0, "passive option should list related evolution")
