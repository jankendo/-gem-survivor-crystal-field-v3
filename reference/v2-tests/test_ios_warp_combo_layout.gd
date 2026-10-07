extends RefCounted
const H = preload("res://tests/helpers/Phase11TestScenarios.gd")
func run(t) -> void: H.new().ios_warp_combo_layout(t)
