extends RefCounted
const Helper = preload("res://tests/helpers/Phase9TestScenarios.gd")
func run(t) -> void:
	var h = Helper.new()
	h.enemy_snapshot_and_batch(t)
	h.gem_collection_batch(t)
