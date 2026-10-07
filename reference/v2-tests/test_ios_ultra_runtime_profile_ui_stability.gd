extends RefCounted
const H = preload("res://tests/helpers/Phase12TestScenarios.gd")
func run(t) -> void: H.new().ios_ultra_runtime_profile_ui_stability(t)
