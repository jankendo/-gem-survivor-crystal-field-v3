extends RefCounted

const BudgetScript = preload("res://scripts/systems/VisualEffectBudgetSystem.gd")

func run(t) -> void:
	var budget = BudgetScript.new()
	var decorative := {"pos": Vector2.ZERO, "priority": 3, "id": "decorative"}
	var critical := {"pos": Vector2.ZERO, "priority": 0, "id": "critical"}
	var signature := {"pos": Vector2.ZERO, "priority": 1, "id": "signature"}
	var selected := budget.select_visual_items([decorative, signature, critical], Vector2.ZERO, Vector2(100, 100), 2)
	t.assert_eq(String(selected[0].id), "critical", "critical visual must be selected first")
	t.assert_eq(String(selected[1].id), "signature", "signature visual must precede decorative effects")
	var critical_only := budget.select_visual_items([critical, critical.duplicate(), critical.duplicate()], Vector2.ZERO, Vector2(100, 100), 1)
	t.assert_eq(critical_only.size(), 3, "critical effects must not be dropped by a soft visual limit")

