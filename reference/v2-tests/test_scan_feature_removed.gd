extends RefCounted
const H = preload("res://tests/helpers/Phase10TestScenarios.gd")
func run(t) -> void: H.new().scan_removed(t)
