extends RefCounted

const BudgetScript = preload("res://scripts/systems/VisualEffectBudgetSystem.gd")

func run(t) -> void:
	var budget = BudgetScript.new()
	budget.set_profile("ios_low")
	t.assert_true(budget.adaptive_arc_segments(12.0) >= 8 and budget.adaptive_arc_segments(12.0) <= 12, "small arcs should use 8-12 segments")
	t.assert_true(budget.adaptive_arc_segments(70.0) <= 20, "medium arcs should stay within the mobile segment range")
	t.assert_true(budget.adaptive_arc_segments(180.0) <= 32, "large non-critical arcs should not exceed 32 segments")
	t.assert_eq(budget.adaptive_arc_segments(180.0, true), 48, "critical warnings may use 48 segments")

