extends RefCounted

const Utils = preload("res://tests/phase4_environment_test_utils.gd")

func run(t) -> void:
	Utils.new().run(t, "fallback")
