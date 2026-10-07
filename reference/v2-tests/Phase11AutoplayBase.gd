extends SceneTree

const H = preload("res://tests/helpers/Phase11TestScenarios.gd")

var failures: Array = []
var assertions := 0

func scenario_id() -> String:
	return ""

func _initialize() -> void:
	var id := scenario_id()
	var started := Time.get_ticks_usec()
	var scenarios = H.new()
	match id:
		"warp_chest_collection":
			scenarios.warp_chest_collection(self)
		"heaven_loot_stress":
			scenarios.warp_heaven_loot_quantity(self)
			scenarios.warp_reward_safe_placement(self)
		"hell_density_stress":
			scenarios.warp_hell_difficulty(self)
			scenarios.weapon_combo_performance(self)
		"core_capacity_flow":
			scenarios.core_candidates_at_capacity(self)
			scenarios.loadout_replacement_transaction(self)
			scenarios.loadout_replacement_rollback(self)
		"combo_3pair_stress":
			scenarios.weapon_combo_activation(self)
			scenarios.weapon_combo_damage_attribution(self)
			scenarios.weapon_combo_performance(self)
		"combo_all_patterns":
			scenarios.weapon_combo_data_validation(self)
			scenarios.weapon_combo_no_recursion(self)
		"warp_roundtrip_combo":
			scenarios.warp_normal_room_flow(self)
			scenarios.weapon_combo_determinism(self)
		"100_seed_chest_placement":
			scenarios.warp_reward_safe_placement(self)
		"10000_seed_room_distribution":
			scenarios.warp_room_type_distribution(self)
		_:
			failures.append("Unknown Phase 11 autoplay scenario: %s" % id)
	var report := {
		"scenario": id,
		"ok": failures.is_empty(),
		"assertions": assertions,
		"failures": failures,
		"duration_ms": float(Time.get_ticks_usec() - started) / 1000.0
	}
	var directory := "res://test-output/phase11/autoplay"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file := FileAccess.open("%s/%s.json" % [directory, id], FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
	print("Phase 11 autoplay ", id, ": ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)

func assert_true(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)

func assert_eq(actual, expected, message: String) -> void:
	assertions += 1
	if actual != expected:
		failures.append("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])
