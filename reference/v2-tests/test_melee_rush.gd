extends RefCounted

const MeleeRushSystemScript = preload("res://scripts/systems/MeleeRushSystem.gd")

func run(t) -> void:
	test_melee_kills_build_gauge(t)
	test_rush_levels_activate_effects(t)
	test_rush_boosts_melee_effect_state(t)
	test_rush_level_does_not_refresh_forever(t)

func _state():
	var state = SurvivorState.new()
	state.start_new_run(5050, "rush")
	state.weapons = {"soul_scythe": 1, "blade_fan": 1}
	return state

func test_melee_kills_build_gauge(t) -> void:
	var state = _state()
	var system = MeleeRushSystemScript.new()
	system.record_kill(state, "soul_scythe", [])
	t.assert_eq(state.melee_rush_kills, 1, "melee kill should increase rush gauge")

func test_rush_levels_activate_effects(t) -> void:
	var state = _state()
	var system = MeleeRushSystemScript.new()
	for i in range(20):
		system.record_kill(state, "soul_scythe", [])
	t.assert_eq(state.melee_rush_level, 1, "20 melee kills should activate rush Lv1")
	for i in range(30):
		system.record_kill(state, "soul_scythe", [])
	t.assert_eq(state.melee_rush_level, 2, "50 melee kills should activate rush Lv2")
	for i in range(50):
		system.record_kill(state, "soul_scythe", [])
	t.assert_eq(state.melee_rush_level, 3, "100 melee kills should activate rush Lv3")

func test_rush_boosts_melee_effect_state(t) -> void:
	var state = _state()
	state.melee_rush_level = 2
	state.melee_rush_timer = 6.0
	t.assert_true(state.get_area_multiplier_for_weapon("soul_scythe") > state.get_area_multiplier(), "rush should boost melee area")
	t.assert_true(MeleeRushSystemScript.new().effect_boost_active(state), "rush Lv2 should request stronger slash effect")

func test_rush_level_does_not_refresh_forever(t) -> void:
	var state = _state()
	var system = MeleeRushSystemScript.new()
	for i in range(100):
		system.record_kill(state, "soul_scythe", [])
	system.process(state, 6.0, [])
	var timer_before = state.melee_rush_timer
	system.record_kill(state, "soul_scythe", [])
	t.assert_eq(state.melee_rush_timer, timer_before, "melee kills after Lv3 threshold must not refresh the rush forever")
