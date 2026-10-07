extends SceneTree

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const RewardScript = preload("res://scripts/systems/FieldEquipmentRewardSystem.gd")

var failures: Array = []

func _initialize() -> void:
	var state = StateScript.new()
	state.start_new_run(881602, "auto-exploration-reward")
	state.elapsed_seconds = 900.0
	state.field_equipment_collected = min(4, state.field_equipment.size())
	state.reward_room_pickups = state.field_equipment_collected
	state.exploration_chain_max = 5
	var reward = RewardScript.new()
	_assert(reward.exploration_reward_score(state) > reward.camping_score_estimate(15.0), "15min exploration route should beat camping estimate")
	_assert(state.field_equipment.size() > 0, "exploration map should contain field equipment")
	await process_frame
	_done()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _done() -> void:
	if failures.is_empty():
		print("AutoPlay exploration reward OK: 15min equivalent")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
