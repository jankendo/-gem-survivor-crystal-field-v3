extends SceneTree

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const LevelScript = preload("res://scripts/systems/LevelUpSystem.gd")
const SelectionScript = preload("res://scripts/systems/SelectionActionSystem.gd")

var failures: Array = []

func _initialize() -> void:
	var state = StateScript.new()
	state.start_new_run(881601, "auto-skip-seal")
	var selection = SelectionScript.new()
	selection.begin_run(state, {"currency_sink_levels": {"selection_skip_charm": 2, "selection_seal_art": 2}, "stats": {}})
	var level = LevelScript.new()
	var events: Array = []
	for minute in range(10):
		state.elapsed_seconds = float(minute * 60)
		state.level_up_options = level.prepare_options(state, 3)
		state.level_up_pending = true
		if minute % 3 == 0 and state.selection_seal_remaining > 0:
			selection.seal_option(state, String(state.level_up_options[0].get("uid", "")), events)
		if state.selection_skip_remaining > 0:
			selection.skip_current(state, events)
		else:
			level.apply_option(state, String(state.level_up_options[0].get("uid", "")), events)
	_assert(state.selection_skip_rewards > 0, "autoplay should use skip")
	_assert(state.selection_seals_used > 0, "autoplay should use seal")
	_assert(state.disabled_weapon_ids.is_empty() and state.disabled_passive_ids.is_empty(), "run seal should not persist as loadout OFF")
	await process_frame
	_done()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _done() -> void:
	if failures.is_empty():
		print("AutoPlay skip/seal OK: 10min equivalent")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
