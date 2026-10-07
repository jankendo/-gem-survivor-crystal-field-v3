extends RefCounted

const BudgetScript = preload("res://scripts/systems/VisualEffectBudgetSystem.gd")

func run(t) -> void:
	var budget = BudgetScript.new()
	budget.set_profile("ios_low")
	t.assert_eq(budget.rendered_limit("projectiles", 999), 120, "iOS low projectile render budget should come from the visual profile")
	t.assert_eq(budget.rendered_limit("gems", 999), 260, "iOS low gem render budget should not be a simulation cap")
	var items: Array = []
	for index in range(20):
		items.append({"pos": Vector2(index, 0), "priority": 2})
	var selected := budget.select_visual_items(items, Vector2.ZERO, Vector2(200, 200), 7)
	t.assert_eq(selected.size(), 7, "visual selection should honor its render-only budget")
	t.assert_eq(items.size(), 20, "visual selection must not mutate the source array")

