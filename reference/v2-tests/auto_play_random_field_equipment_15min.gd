extends SceneTree

func _initialize() -> void:
	var ok = preload("res://tests/helpers/FeatureAutoplaySmoke.gd").new().run("field_equipment")
	print("auto_play_random_field_equipment_15min: %s" % ("OK" if ok else "FAILED"))
	quit(0 if ok else 1)
