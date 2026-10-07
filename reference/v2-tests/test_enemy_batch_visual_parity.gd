extends RefCounted
const H = preload("res://tests/helpers/Phase12TestScenarios.gd")
func run(t) -> void: H.new().enemy_batch_visual_parity(t)
