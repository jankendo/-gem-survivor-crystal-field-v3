extends RefCounted

const ValidatorScript = preload("res://scripts/systems/EffectCompletenessValidator.gd")

func run(t) -> void:
	var weapons = _json("res://data/weapons.json")
	var evolutions = _json("res://data/evolutions.json")
	var effects = _json("res://data/weapon_effects.json")
	var errors = ValidatorScript.new().validate(weapons, evolutions, effects)
	t.assert_eq(errors, [], "all weapons and evolutions should resolve to supported visual effects")

func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())

