extends RefCounted

const Budget = preload("res://scripts/systems/VisualEffectBudgetSystem.gd")

func run(t) -> void:
	var budget = Budget.new()
	budget.set_profile("ios_minimal")
	var items := [
		{"pos": Vector2.ZERO, "priority": Budget.PRIORITY_CRITICAL},
		{"pos": Vector2.ONE, "priority": Budget.PRIORITY_CRITICAL},
		{"pos": Vector2(2, 0), "priority": Budget.PRIORITY_DECORATIVE},
	]
	var selected := budget.select_visual_items(items, Vector2.ZERO, Vector2(100, 100), 1)
	t.assert_eq(selected.size(), 2, "Critical visuals must survive a soft visual budget")
	t.assert_true(selected.all(func(item): return int(item.get("priority", 9)) == Budget.PRIORITY_CRITICAL), "only Critical visuals may exceed the limit")
