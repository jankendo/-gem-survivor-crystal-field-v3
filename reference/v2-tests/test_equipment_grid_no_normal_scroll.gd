extends RefCounted
const H = preload("res://tests/helpers/Phase12TestScenarios.gd")
func run(t) -> void: H.new().equipment_grid_no_normal_scroll(t)
