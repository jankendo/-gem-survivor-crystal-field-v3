extends SceneTree

func _initialize() -> void:
	var ok = preload("res://tests/helpers/FeatureAutoplaySmoke.gd").new().run("drop")
	print("auto_play_field_drop_persistence_30min: %s" % ("OK" if ok else "FAILED"))
	quit(0 if ok else 1)
