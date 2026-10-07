extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const LevelUpScript = preload("res://scripts/systems/LevelUpSystem.gd")
const SelectionScript = preload("res://scripts/systems/SelectionActionSystem.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(20260616, "skip-seal")
	var selection = SelectionScript.new()
	selection.begin_run(state, {
		"currency_sink_levels": {"selection_skip_charm": 1, "levelup_reroll_capacity": 2, "selection_seal_art": 1},
		"stats": {}
	})
	t.assert_true(state.selection_skip_max >= 2, "shop upgrade should increase skip count")
	t.assert_true(state.selection_reroll_max >= 3, "shop upgrade should increase level-up reroll count")
	t.assert_true(state.selection_seal_max >= 1, "shop upgrade should increase seal count")
	var level = LevelUpScript.new()
	state.level_up_options = level.prepare_options(state, 3)
	state.level_up_pending = true
	var sealed_uid := String(state.level_up_options[0].get("uid", ""))
	var events: Array = []
	t.assert_true(selection.consume_reroll(state, events), "reroll should consume a run-only charge")
	t.assert_eq(state.selection_reroll_remaining, state.selection_reroll_max - 1, "reroll charge should decrease")
	t.assert_true(selection.seal_option(state, sealed_uid, events), "seal should consume a run-only charge")
	t.assert_true(state.run_sealed_option_uids.has(sealed_uid), "sealed option should be stored for current run")
	t.assert_true(state.disabled_weapon_ids.is_empty() and state.disabled_passive_ids.is_empty(), "run seal must not change persistent loadout OFF arrays")
	var regenerated = level.prepare_options(state, 12)
	for option in regenerated:
		t.assert_true(String(option.get("uid", "")) != sealed_uid, "sealed option must not reappear in candidate pool")
	state.level_up_options = regenerated.slice(0, 3)
	state.level_up_pending = true
	var before_score: int = state.score
	t.assert_true(selection.skip_current(state, events), "skip should close the selection")
	t.assert_true(not state.level_up_pending, "skip should resume the run")
	t.assert_true(state.score > before_score, "skip should grant a small reward")
