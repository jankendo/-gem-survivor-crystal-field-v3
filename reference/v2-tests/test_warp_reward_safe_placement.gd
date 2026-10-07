extends RefCounted
const H = preload("res://tests/helpers/Phase11TestScenarios.gd")
func run(t) -> void: H.new().warp_reward_safe_placement(t)
