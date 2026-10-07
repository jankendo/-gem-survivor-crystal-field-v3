extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const RewardScript = preload("res://scripts/systems/FieldEquipmentRewardSystem.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(771601, "explore-vs-camp")
	state.field_equipment_collected = 3
	state.reward_room_pickups = 3
	state.exploration_chain_max = 5
	var reward = RewardScript.new()
	var exploration_score := reward.exploration_reward_score(state)
	var camping_score := reward.camping_score_estimate(10.0)
	t.assert_true(exploration_score > camping_score, "reward rooms and chain should beat safe start-room camping")
