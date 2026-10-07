extends RefCounted
const Helper = preload("res://tests/helpers/Phase9TestScenarios.gd")
const Context = preload("res://scripts/systems/SelectionContextSystem.gd")
func run(t) -> void:
	var h = Helper.new()
	h.selection_hidden_for_context(t, Context.WEAPON_CORE)
	h.selection_hidden_for_context(t, Context.PASSIVE_CORE)
	h.reward_popup_hides_level_actions(t)
