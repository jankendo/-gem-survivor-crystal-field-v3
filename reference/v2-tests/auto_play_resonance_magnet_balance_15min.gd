extends SceneTree

func _initialize() -> void:
	var ok = preload("res://tests/helpers/FeatureAutoplaySmoke.gd").new().run("resonance")
	print("auto_play_resonance_magnet_balance_15min: %s" % ("OK" if ok else "FAILED"))
	quit(0 if ok else 1)
