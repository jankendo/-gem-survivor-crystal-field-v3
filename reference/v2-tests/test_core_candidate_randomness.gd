extends RefCounted
const H = preload("res://tests/helpers/Phase11TestScenarios.gd")
func run(t) -> void: H.new().core_candidate_randomness(t)
