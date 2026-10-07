extends RefCounted
const Helper = preload("res://tests/helpers/Phase9TestScenarios.gd")
func run(t) -> void:
	Helper.new().enemy_snapshot_and_batch(t)
