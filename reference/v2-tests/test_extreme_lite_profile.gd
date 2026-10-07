extends RefCounted

const Budget = preload("res://scripts/systems/VisualEffectBudgetSystem.gd")

func run(t) -> void:
	var budget = Budget.new()
	budget.set_profile("ios_minimal")
	t.assert_true(budget.is_minimal(), "ios_minimal must be marked minimal")
	t.assert_eq(budget.rendered_limit("damage_numbers", 99), 0, "minimal damage numbers must be zero")
	t.assert_eq(budget.rendered_limit("background_particles", 99), 0, "minimal background particles must be zero")
	t.assert_true(not budget.feature_enabled("trails"), "minimal projectile trails must be disabled")
