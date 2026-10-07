extends RefCounted
const H = preload("res://tests/helpers/Phase11TestScenarios.gd")
func run(t) -> void: H.new().weapon_combo_no_recursion(t)
