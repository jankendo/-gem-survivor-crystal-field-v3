extends RefCounted
const Helper = preload("res://tests/helpers/Phase9TestScenarios.gd")
const Context = preload("res://scripts/systems/SelectionContextSystem.gd")
func run(t) -> void:
	var h = Helper.new()
	h.selection_hidden_for_context(t, Context.CHEST)
	h.selection_hidden_for_context(t, Context.RUNE_CONTRACT)
	h.selection_hidden_for_context(t, Context.OVERCLOCK)
	h.selection_hidden_for_context(t, Context.EVENT_REWARD)
	h.selection_hidden_for_context(t, Context.CHARACTER_EVOLUTION)
