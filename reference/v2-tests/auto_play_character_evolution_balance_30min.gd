extends SceneTree

func _initialize() -> void:
	var ok = preload("res://tests/helpers/FeatureAutoplaySmoke.gd").new().run("character_balance")
	print("auto_play_character_evolution_balance_30min: %s" % ("OK" if ok else "FAILED"))
	quit(0 if ok else 1)
