extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const ProfileScript = preload("res://scripts/systems/PerformanceProfileSystem.gd")

func run(t) -> void:
	var desktop = StateScript.new()
	desktop.start_new_run(50504)
	ProfileScript.new().apply_to_state(desktop, {"render_quality": "standard"}, "Windows")
	var ios = StateScript.new()
	ios.start_new_run(50504)
	ProfileScript.new().apply_to_state(ios, {"render_quality": "low"}, "iOS")
	t.assert_eq(ios.max_enemies(), desktop.max_enemies(), "same seed should start with equal enemy cap")
	t.assert_eq(ios.enemy_hp_multiplier(), desktop.enemy_hp_multiplier(), "iOS profile must not weaken enemy HP")
	t.assert_eq(ios.enemy_damage_multiplier(), desktop.enemy_damage_multiplier(), "iOS profile must not weaken enemy damage")
	t.assert_eq(ios.enemy_spawn_multiplier(), desktop.enemy_spawn_multiplier(), "iOS profile must not weaken spawn multiplier")
	t.assert_eq(ios.enemy_speed_multiplier(), desktop.enemy_speed_multiplier(), "iOS profile must not weaken enemy speed")
