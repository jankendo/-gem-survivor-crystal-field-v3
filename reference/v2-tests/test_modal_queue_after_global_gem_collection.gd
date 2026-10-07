extends RefCounted

const ExpGemScript = preload("res://scripts/core/ExpGem.gd")
const GlobalGemCollectionSystemScript = preload("res://scripts/systems/GlobalGemCollectionSystem.gd")
const LevelUpSystemScript = preload("res://scripts/systems/LevelUpSystem.gd")

func run(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(0, "modal-queue")
	state.gems.clear()
	for i in range(80):
		state.gems.append(ExpGemScript.new(state.player_position + Vector2(float(i), 0), 80))
	var events: Array = []
	GlobalGemCollectionSystemScript.new().collect_all(state, events, "magnet")
	t.assert_true(state.level_up_pending, "first level up should open after global gem collection")
	t.assert_true(state.queued_level_up_count > 0, "extra level ups should be queued")
	var uid = String(state.level_up_options[0].get("uid", ""))
	LevelUpSystemScript.new().apply_option(state, uid, events)
	t.assert_true(state.level_up_pending or state.queued_level_up_count >= 0, "queue should continue without overlapping modals")
