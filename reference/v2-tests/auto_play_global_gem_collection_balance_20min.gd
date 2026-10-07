extends SceneTree

func _initialize() -> void:
	var smoke = preload("res://tests/helpers/FeatureAutoplaySmoke.gd").new()
	var ok = smoke.run("magnet") and smoke.run("drone")
	print("auto_play_global_gem_collection_balance_20min: %s" % ("OK" if ok else "FAILED"))
	quit(0 if ok else 1)
