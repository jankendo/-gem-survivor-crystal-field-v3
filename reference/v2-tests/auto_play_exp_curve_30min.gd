extends SceneTree

func _initialize() -> void:
	var ok = preload("res://tests/helpers/FeatureAutoplaySmoke.gd").new().run("exp_curve")
	print("auto_play_exp_curve_30min: %s" % ("OK" if ok else "FAILED"))
	quit(0 if ok else 1)
