extends RefCounted
const H = preload("res://tests/helpers/Phase10TestScenarios.gd")
func run(t) -> void: H.new().warp_placement_100_seed(t)
