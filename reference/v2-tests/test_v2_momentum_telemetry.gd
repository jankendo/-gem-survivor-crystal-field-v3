extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const V2MomentumTelemetryScript = preload("res://scripts/systems/V2MomentumTelemetry.gd")

func run(t) -> void:
	test_snapshot_contains_balance_fields(t)
	test_record_respects_row_limit(t)

func test_snapshot_contains_balance_fields(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(2026)
	state.elapsed_seconds = 123.0
	state.v2_momentum_timer = 4.5
	state.v2_momentum_tier = 2
	state.v2_momentum_triggers = 3
	state.v2_momentum_active_time_total = 18.0
	state.v2_momentum_score_base = 1000
	state.v2_momentum_score_bonus = 80
	state.v2_momentum_weighted_time = 100.0
	state.v2_momentum_weighted_multiplier_sum = 104.5
	state.v2_momentum_trigger_counts = {"boss_defeat": 1, "evolution": 2}
	var telemetry = V2MomentumTelemetryScript.new()
	var row := telemetry.snapshot(state, "boss_defeat")
	t.assert_eq(int(row.get("momentum_tier", 0)), 2, "telemetry should include current momentum tier")
	t.assert_eq(String(row.get("trigger_type", "")), "boss_defeat", "telemetry should include trigger type")
	t.assert_true(float(row.get("weighted_multiplier", 0.0)) > 1.04, "telemetry should include weighted multiplier")
	t.assert_eq(int(row.get("score_momentum_bonus", 0)), 80, "telemetry should include momentum score bonus")

func test_record_respects_row_limit(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(2026)
	var telemetry = V2MomentumTelemetryScript.new()
	telemetry.configure(true, 2)
	for i in range(35):
		state.elapsed_seconds = float(i)
		telemetry.record(state, "kill_streak")
	t.assert_eq(telemetry.rows.size(), 32, "telemetry should keep the safe minimum row limit")
