extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const MetaProgressionSystemScript = preload("res://scripts/systems/MetaProgressionSystem.gd")

func run(t) -> void:
	test_initial_weapon_and_start_stats(t)
	test_weapon_tag_damage_trait(t)
	test_blessing_and_meta_modifiers_stack(t)

func _state():
	var state = SurvivorStateScript.new()
	state.start_new_run(4401)
	return state

func test_initial_weapon_and_start_stats(t) -> void:
	var state = _state()
	var meta = MetaProgressionSystemScript.new()
	meta.apply_to_state(state, "noah", "attack", SaveSystem.new("user://test_character_traits_a.save").load_data())
	t.assert_true(state.weapons.has("magic_bolt"), "Noah should start with Magic Bolt")
	t.assert_eq(state.max_hp, 100, "Noah's HP penalty should apply")
	t.assert_true(state.base_magnet_radius > 86.0, "Noah's magnet bonus should apply")

func test_weapon_tag_damage_trait(t) -> void:
	var state = _state()
	var meta = MetaProgressionSystemScript.new()
	var save_data := SaveSystem.new("user://test_character_traits_b.save").load_data()
	save_data["shop_purchases"]["character"]["kaede"] = true
	if not (save_data["unlocked_characters"] as Array).has("kaede"):
		(save_data["unlocked_characters"] as Array).append("kaede")
	meta.apply_to_state(state, "kaede", "attack", save_data)
	t.assert_true(state.weapons.has("soul_scythe"), "Kaede should start with Soul Scythe")
	t.assert_true(state.get_damage_multiplier_for_weapon("soul_scythe") > state.get_damage_multiplier_for_weapon("magic_bolt"), "melee tag damage should boost Soul Scythe only")

func test_blessing_and_meta_modifiers_stack(t) -> void:
	var state = _state()
	var meta = MetaProgressionSystemScript.new()
	var save_data := SaveSystem.new("user://test_character_traits_c.save").load_data()
	save_data["meta_upgrades"]["base_damage"] = 2
	save_data["meta_upgrades"]["base_magnet"] = 1
	meta.apply_to_state(state, "noah", "attack", save_data)
	t.assert_true(state.get_damage_multiplier() > 1.08, "attack blessing and base damage upgrade should stack")
	t.assert_true(state.get_magnet_radius() > 100.0, "base magnet upgrade and Noah trait should stack")
