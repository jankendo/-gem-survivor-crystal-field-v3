extends SceneTree

func _initialize() -> void:
	var ok = preload("res://tests/helpers/FeatureAutoplaySmoke.gd").new().run("exp")
	print("auto_play_exp_multiplier_5min: %s" % ("OK" if ok else "FAILED"))
	quit(0 if ok else 1)
