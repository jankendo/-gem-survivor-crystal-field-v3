extends SceneTree

func _initialize() -> void:
	var ok = preload("res://tests/helpers/FeatureAutoplaySmoke.gd").new().run("magnet")
	print("auto_play_global_magnet_stress: %s" % ("OK" if ok else "FAILED"))
	quit(0 if ok else 1)
