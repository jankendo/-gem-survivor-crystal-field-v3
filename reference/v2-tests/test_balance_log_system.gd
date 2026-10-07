extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const BalanceLogSystemScript = preload("res://scripts/systems/BalanceLogSystem.gd")

func run(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(4205)
	state.balance_log_enabled = true
	state.elapsed_seconds = 300.0
	state.weapon_damage_by_id = {"magic_bolt": 120, "star_fragment": 30}
	state.crystals_destroyed = 4
	state.rooms_discovered = 6
	state.exploration_score = 25
	BalanceLogSystemScript.new().process(state, 1.0)
	t.assert_eq(state.balance_log_rows.size(), 2, "balance log should emit a header and data row")
	var header = String(state.balance_log_rows[0])
	t.assert_true(header.find("total_weapon_damage") >= 0, "balance log should include total weapon damage")
	t.assert_true(header.find("map_room_count") >= 0, "balance log should include explored room count")
	t.assert_eq(String(state.balance_log_rows[1]).split(",").size(), header.split(",").size(), "balance log rows should match the header column count")
