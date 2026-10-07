extends SceneTree

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const RewardScript = preload("res://scripts/systems/FieldEquipmentRewardSystem.gd")

var failures: Array = []

func _initialize() -> void:
	var reward = RewardScript.new()
	var camping = StateScript.new()
	camping.start_new_run(881603, "camping")
	camping.elapsed_seconds = 1200.0
	var explore = StateScript.new()
	explore.start_new_run(881603, "exploration")
	explore.elapsed_seconds = 1200.0
	explore.field_equipment_collected = 5
	explore.reward_room_pickups = 5
	explore.exploration_chain_max = 6
	_assert(reward.exploration_reward_score(explore) > reward.camping_score_estimate(20.0), "20min exploration should have stronger reward score than camping")
	_assert(camping.field_equipment_collected == 0, "camping control should not gain field equipment")
	await process_frame
	_done()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _done() -> void:
	if failures.is_empty():
		print("AutoPlay camping vs exploration OK: 20min equivalent")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
