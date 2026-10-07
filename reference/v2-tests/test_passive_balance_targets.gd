extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const PlayerScript = preload("res://scripts/systems/Player.gd")

func run(t) -> void:
	test_offense_caps(t)
	test_defense_and_healing_caps(t)
	test_metadata_marks_indirect_passives(t)

func _state():
	var state = SurvivorStateScript.new()
	state.start_new_run(4203)
	return state

func test_offense_caps(t) -> void:
	var state = _state()
	state.passives = {"might": 5, "cooldown": 5, "area": 5, "greed": 5}
	t.assert_true(absf(state.get_damage_multiplier() - 1.65) < 0.001, "might Lv5 should cap at +65%")
	t.assert_true(absf(state.get_cooldown_multiplier() - 0.675) < 0.001, "cooldown Lv5 should cap at -32.5%")
	t.assert_true(absf(state.get_area_multiplier() - 1.55) < 0.001, "area Lv5 should cap at +55%")
	t.assert_true(absf(state.get_score_multiplier() - 1.70) < 0.001, "greed Lv5 should cap at +70% score")

func test_defense_and_healing_caps(t) -> void:
	var state = _state()
	state.passives = {"armor": 5, "regen": 5}
	t.assert_eq(PlayerScript.new()._reduced_damage(state, 100), 60, "armor Lv5 should remain strong without exceeding its floor")
	state.hp = 1
	for i in range(5):
		PlayerScript.new().process_survival(state, 1.0, [])
	t.assert_eq(state.hp, 16, "regen Lv5 should heal at most 3 HP per second")

func test_metadata_marks_indirect_passives(t) -> void:
	var state = _state()
	t.assert_eq(bool(state.passive_defs["might"].get("direct_damage", false)), true, "might should be marked as direct combat power")
	t.assert_eq(bool(state.passive_defs["greed"].get("direct_damage", true)), false, "greed should be marked as an indirect economy passive")
	t.assert_eq(int(state.passive_defs["pickup_heal"].get("heal_cap", 0)), 4, "pickup healing metadata should expose its cap")
	for passive_id in ["treasure_instinct", "route_memory", "map_reader", "mining_luck", "crystal_wallet"]:
		t.assert_true(not bool(state.passive_defs[passive_id].get("direct_damage", false)), "economy and exploration passive %s should not grant broad direct damage" % passive_id)
