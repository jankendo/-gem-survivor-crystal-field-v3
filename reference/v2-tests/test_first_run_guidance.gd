extends RefCounted

const FirstRunTelemetryScript = preload("res://scripts/systems/FirstRunTelemetry.gd")
const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9401, "")
	var summary: Dictionary = FirstRunTelemetryScript.new().estimate_first_run(state)
	t.assert_true(float(summary.get("first_objective_seconds", 999.0)) <= 45.0, "first objective should appear quickly")
	t.assert_true(bool(summary.get("concept_visible", false)), "first-run concept should be visible")
