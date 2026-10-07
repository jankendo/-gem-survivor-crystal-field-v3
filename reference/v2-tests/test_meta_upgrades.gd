extends RefCounted

const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")
const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	test_purchase_upgrade_spends_currency(t)
	test_upgrade_caps_at_max_level(t)
	test_upgrade_applies_to_state(t)

func _fresh_save() -> SaveSystem:
	var save := SaveSystem.new("user://test_meta_upgrades.save")
	save.save_data({})
	save.reset_play_data("RESET")
	return save

func test_purchase_upgrade_spends_currency(t) -> void:
	var save := _fresh_save()
	var meta = MetaProgressionSystemScript.new()
	save.add_currency(200)
	t.assert_true(meta.purchase_upgrade(save, "base_hp"), "base HP upgrade should be purchasable")
	var data := save.load_data()
	t.assert_eq(int(data["meta_upgrades"].get("base_hp", 0)), 1, "upgrade level should increase")
	t.assert_eq(int(data.get("crystal_currency", 0)), 80, "upgrade should spend the first cost")

func test_upgrade_caps_at_max_level(t) -> void:
	var save := _fresh_save()
	var meta = MetaProgressionSystemScript.new()
	save.add_currency(999999)
	var purchases := 0
	while meta.purchase_upgrade(save, "base_damage"):
		purchases += 1
	t.assert_eq(purchases, 10, "base damage upgrade should stop at max level")
	t.assert_eq(int(save.load_data()["meta_upgrades"].get("base_damage", 0)), 10, "saved upgrade should equal max level")

func test_upgrade_applies_to_state(t) -> void:
	var meta = MetaProgressionSystemScript.new()
	var save_data := SaveSystem.new("user://test_meta_upgrades_apply.save").load_data()
	save_data["meta_upgrades"]["base_hp"] = 3
	save_data["meta_upgrades"]["crystal_mining"] = 2
	var state = SurvivorStateScript.new()
	state.start_new_run(202)
	meta.apply_to_state(state, "noah", "attack", save_data)
	t.assert_true(state.max_hp > 100, "HP meta upgrade should offset Noah's HP penalty")
	t.assert_true(state.crystal_damage_multiplier() > 1.09, "crystal mining upgrade should affect crystal damage")
