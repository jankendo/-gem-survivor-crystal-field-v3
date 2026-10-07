extends RefCounted

const BudgetScript = preload("res://scripts/systems/VisualEffectBudgetSystem.gd")
const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var budget = BudgetScript.new()
	budget.configure_metrics(false)
	budget.select_visual_items([{"pos": Vector2.ZERO}], Vector2.ZERO, Vector2(100, 100), 1)
	t.assert_eq(bool(budget.snapshot().enabled), false, "release visual budget metrics should be disabled")
	var state = StateScript.new()
	state.start_new_run(7719)
	state.configure_render_profile("ios_standard", false)
	state.add_hit_flash({"pos": Vector2.ZERO, "source": "magic_bolt", "life": 0.2})
	t.assert_eq(bool(state.visual_effect_command_buffer.snapshot().enabled), false, "release command metrics should be disabled")

