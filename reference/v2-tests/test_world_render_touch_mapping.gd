extends RefCounted
const H = preload("res://tests/helpers/Phase12TestScenarios.gd")
func run(t) -> void: H.new().world_render_touch_mapping(t)
