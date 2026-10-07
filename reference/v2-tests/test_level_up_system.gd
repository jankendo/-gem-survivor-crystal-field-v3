extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const LevelUpSystemScript = preload("res://scripts/systems/LevelUpSystem.gd")

func run(t) -> void:
	test_options_are_unique(t)
	test_max_level_is_excluded(t)
	test_apply_option_upgrades(t)

func _state() :
	var state = SurvivorStateScript.new()
	state.start_new_run(44)
	return state

func test_options_are_unique(t) -> void:
	var state = _state()
	var options = LevelUpSystemScript.new().prepare_options(state, 3)
	var ids: Array = []
	for option in options:
		var uid = String(option.get("uid", ""))
		t.assert_true(not ids.has(uid), "level options should not duplicate")
		ids.append(uid)

func test_max_level_is_excluded(t) -> void:
	var state = _state()
	state.weapons["magic_bolt"] = 8
	var options = LevelUpSystemScript.new().prepare_options(state, 8)
	for option in options:
		t.assert_true(String(option.get("uid", "")) != "weapon:magic_bolt", "max level weapon should not appear")

func test_apply_option_upgrades(t) -> void:
	var state = _state()
	state.level_up_options = [{"uid": "passive:magnet", "kind": "passive", "id": "magnet", "name_ja": "磁力コア", "next_level": 1}]
	state.level_up_pending = true
	var ok = LevelUpSystemScript.new().apply_option(state, "passive:magnet", [])
	t.assert_true(ok, "option should apply")
	t.assert_eq(int(state.passives.get("magnet", 0)), 1, "passive should increase")
