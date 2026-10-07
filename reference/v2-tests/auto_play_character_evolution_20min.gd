extends SceneTree

func _initialize() -> void:
	var ok = preload("res://tests/helpers/FeatureAutoplaySmoke.gd").new().run("character_evolution")
	print("auto_play_character_evolution_20min: %s" % ("OK" if ok else "FAILED"))
	quit(0 if ok else 1)
