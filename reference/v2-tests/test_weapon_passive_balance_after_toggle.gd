extends RefCounted

const LoadoutScript = preload("res://scripts/systems/LoadoutDisableSystem.gd")

func run(t) -> void:
	var weapons: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))
	var strong_ids := ["ice_orbit", "blade_fan", "corridor_blade", "magic_bolt", "relic_chain"]
	var weak_ids := ["black_hole", "gravity_anchor", "frost_wall", "rune_gate", "mine_lantern"]
	for id in strong_ids:
		t.assert_true(_proxy(weapons[id]) < 4.0, "%s static proxy should not remain an extreme outlier" % id)
	for id in weak_ids:
		t.assert_true(_proxy(weapons[id]) >= 0.15, "%s should meet the minimum useful proxy" % id)
	t.assert_true(_proxy(weapons["blade_fan"]) > _proxy(weapons["magic_bolt"]), "melee risk should retain higher damage than ranged safety")
	t.assert_true(_proxy(weapons["bomb_seed"]) < _proxy(weapons["ice_orbit"]), "long cooldown explosion should retain a distinct burst role")
	t.assert_eq(LoadoutScript.MIN_ACTIVE_WEAPONS, 4, "toggle system should preserve at least four active weapons")
	t.assert_eq(LoadoutScript.MIN_ACTIVE_PASSIVES, 4, "toggle system should preserve at least four active passives")

func _proxy(data: Dictionary) -> float:
	var damage := float(data.get("base_damage_score", data.get("base_damage", 1.0)))
	var cooldown := maxf(0.2, float(data.get("base_cooldown_score", data.get("cooldown", 1.5))))
	var reach := minf(900.0, float(data.get("range", 300.0)))
	var category := String(data.get("category", ""))
	var category_mult := 1.0
	match category:
		"ranged": category_mult = 0.92
		"melee": category_mult = 1.20
		"lightning": category_mult = 0.92
		"poison": category_mult = 0.84
		"explosion": category_mult = 1.08
		"deploy": category_mult = 0.92
		"gem": category_mult = 0.80
		"knockback": category_mult = 0.84
		"crystal": category_mult = 0.94
	return damage * category_mult * (0.78 + reach / 3000.0) / cooldown
