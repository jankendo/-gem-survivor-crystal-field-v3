extends RefCounted
const Helper = preload("res://tests/helpers/Phase9TestScenarios.gd")
func run(t) -> void:
	Helper.new().result_damage_lines(t)
