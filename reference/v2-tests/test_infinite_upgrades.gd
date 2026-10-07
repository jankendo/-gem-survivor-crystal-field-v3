extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const LevelUpSystemScript = preload("res://scripts/systems/LevelUpSystem.gd")

func run(t) -> void:
	test_infinite_definitions_exist(t)
	test_infinite_effects_stack(t)

func test_infinite_definitions_exist(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(602)
	var required = ["infinite_damage", "infinite_speed", "infinite_area", "infinite_magnet", "infinite_hp", "infinite_greed"]
	for id in required:
		t.assert_true(state.infinite_defs.has(id), "missing infinite upgrade %s" % id)

func test_infinite_effects_stack(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(603)
	var level_system = LevelUpSystemScript.new()
	state.level_up_pending = true
	state.level_up_options = [
		{"uid": "infinite:infinite_damage", "kind": "infinite", "id": "infinite_damage", "name_ja": "無限強化：攻撃力", "next_level": 1},
		{"uid": "infinite:infinite_speed", "kind": "infinite", "id": "infinite_speed", "name_ja": "無限強化：連射", "next_level": 1},
		{"uid": "infinite:infinite_hp", "kind": "infinite", "id": "infinite_hp", "name_ja": "無限強化：生命", "next_level": 1}
	]
	var before_hp = state.max_hp
	t.assert_true(level_system.apply_option(state, "infinite:infinite_damage", []), "damage infinite should apply")
	state.level_up_pending = true
	state.level_up_options = [{"uid": "infinite:infinite_speed", "kind": "infinite", "id": "infinite_speed", "name_ja": "無限強化：連射", "next_level": 1}]
	t.assert_true(level_system.apply_option(state, "infinite:infinite_speed", []), "speed infinite should apply")
	state.level_up_pending = true
	state.level_up_options = [{"uid": "infinite:infinite_hp", "kind": "infinite", "id": "infinite_hp", "name_ja": "無限強化：生命", "next_level": 1}]
	t.assert_true(level_system.apply_option(state, "infinite:infinite_hp", []), "hp infinite should apply")
	t.assert_true(state.get_damage_multiplier() > 1.04, "infinite damage should increase damage multiplier")
	t.assert_true(state.get_cooldown_multiplier() < 1.0, "infinite speed should reduce cooldown multiplier")
	t.assert_eq(state.max_hp, before_hp + 10, "infinite hp should increase max hp")

