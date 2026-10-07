extends RefCounted

const Settlement = preload("res://scripts/systems/RunSettlementSystem.gd")

func run(t) -> void:
	var system = Settlement.new()
	var state := {"game_over_reason": "manual_exit"}
	t.assert_true(system.begin(true), "manual settlement must begin")
	var summary := system.decorate_summary({"score": 10}, state)
	t.assert_eq(summary.get("end_reason"), "manual_exit", "manual result must expose manual_exit")
	t.assert_true(bool(summary.get("manually_ended")), "manual result must be marked manually ended")
	t.assert_true(not bool(summary.get("run_completed")), "manual result must not be completed")
