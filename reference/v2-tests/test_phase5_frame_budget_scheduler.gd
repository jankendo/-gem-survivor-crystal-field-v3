extends RefCounted

const BudgetScript = preload("res://scripts/performance/CombatFrameBudgetScheduler.gd")

func run(t) -> void:
	var budget = BudgetScript.new()
	budget.configure({"max_logic_updates_per_frame": 3, "max_damage_events_per_frame": 5})
	budget.begin_frame()
	t.assert_true(budget.consume_logic_update(2), "logic budget should allow work inside budget")
	t.assert_true(not budget.consume_logic_update(2), "logic budget should reject over-budget work")
	t.assert_true(budget.consume_damage_event(5), "damage budget should allow exact budget use")
	t.assert_true(not budget.consume_damage_event(1), "damage budget should reject overflow")
	var snapshot: Dictionary = budget.snapshot()
	t.assert_eq(int(snapshot.logic_updates_used), 2, "snapshot should keep accepted logic count")
	t.assert_eq(int(snapshot.damage_events_used), 5, "snapshot should keep accepted damage count")
