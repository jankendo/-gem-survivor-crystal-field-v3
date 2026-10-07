extends SceneTree

func _initialize() -> void:
	_finish("shop")

func _finish(kind: String) -> void:
	var ok = preload("res://tests/helpers/FeatureAutoplaySmoke.gd").new().run(kind)
	print("auto_play_%s: %s" % [kind, "OK" if ok else "FAILED"])
	quit(0 if ok else 1)
