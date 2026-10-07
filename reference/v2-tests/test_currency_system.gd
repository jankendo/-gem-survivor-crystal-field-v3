extends RefCounted

const CurrencySystemScript = preload("res://scripts/systems/CurrencySystem.gd")
const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")

func run(t) -> void:
	test_run_currency_formula(t)
	test_currency_saved_after_run(t)
	test_currency_multiplier_sources(t)

func _summary() -> Dictionary:
	return {
		"survival_time": 600.0,
		"kills": 400,
		"boss_defeats": 1,
		"chests_opened": 2,
		"evolved_weapon_count": 1,
		"rune_contracts": ["glass_cannon", "crystal_tax"],
		"title_badges": ["生存者", "採掘者"],
		"weapon_levels": {"magic_bolt": 8},
		"evolved_weapon_ids": ["magic_bolt"],
		"enemy_seen": [],
		"boss_defeated_ids": []
	}

func test_run_currency_formula(t) -> void:
	var amount := CurrencySystemScript.new().calculate_run_currency(_summary())
	t.assert_eq(amount, 440, "currency formula should include survival, kills, bosses, chests, evolutions, contracts, and titles")

func test_currency_saved_after_run(t) -> void:
	var save := SaveSystem.new("user://test_currency_system.save")
	save.save_data({})
	save.reset_play_data("RESET")
	var meta = MetaProgressionSystemScript.new()
	var result: Dictionary = meta.update_after_run(save, _summary())
	t.assert_eq(int(result.get("currency_earned", 0)), 440, "run result should report earned currency")
	t.assert_eq(save.get_currency(), 990, "quest rewards and run currency should be saved together")

func test_currency_multiplier_sources(t) -> void:
	var meta = MetaProgressionSystemScript.new()
	var save_data := SaveSystem.new("user://test_currency_system_mult.save").load_data()
	save_data["meta_upgrades"]["currency"] = 2
	var character := meta.character_data("lily")
	var amount := CurrencySystemScript.new().calculate_run_currency(_summary(), save_data, character)
	t.assert_eq(amount, 554, "currency upgrade and Lily's currency trait should multiply earnings")
