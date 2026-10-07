extends RefCounted
class_name Phase4EnvironmentAutoplay

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const EnvironmentVisualSystemScript = preload("res://scripts/systems/EnvironmentVisualSystem.gd")
const ItemUtils = preload("res://tests/item_placement_test_utils.gd")

func simulate_environment(profile_name: String, seconds: int, seeds: Array, report_stem: String) -> Dictionary:
	var system = EnvironmentVisualSystemScript.new()
	var summary := {
		"profile": profile_name,
		"seconds": seconds,
		"seed_count": seeds.size(),
		"sample_count": 0,
		"missing_texture_count": 0,
		"variant_mismatch_count": 0,
		"max_visible_tile_budget": int(system.quality_config.get("budgets", {}).get("max_visible_environment_tiles", 520))
	}
	for seed in seeds:
		var state = SurvivorStateScript.new()
		state.start_new_run(int(seed), "phase4-env-%s" % profile_name)
		for second in range(0, seconds, 15):
			state.elapsed_seconds = float(second)
			var biome_id: String = state.biome_system.biome_id_for_position(state, state.player_position + Vector2(float(second % 600), float((second * 3) % 600)))
			for surface in ["floor", "wall", "void", "decal"]:
				if system.surface_path(biome_id, surface) == "":
					summary["missing_texture_count"] = int(summary["missing_texture_count"]) + 1
				var a := system.deterministic_variant(biome_id, surface, "%d,%d" % [second, int(seed)], int(seed))
				var b := system.deterministic_variant(biome_id, surface, "%d,%d" % [second, int(seed)], int(seed))
				if a != b:
					summary["variant_mismatch_count"] = int(summary["variant_mismatch_count"]) + 1
				summary["sample_count"] = int(summary["sample_count"]) + 1
	_write_report(report_stem, summary)
	return summary

func simulate_item_placement_with_environment(seconds: int, seed_count: int, report_stem: String) -> Dictionary:
	var system = EnvironmentVisualSystemScript.new()
	var summary := {
		"seconds": seconds,
		"seed_count": seed_count,
		"checked": 0,
		"invalid_count": 0,
		"environment_variant_mismatch_count": 0
	}
	for i in range(seed_count):
		var seed := 73000 + i
		var state = ItemUtils.new_state(seed)
		for source in [
			{"items": state.field_drops, "type": "field_drop"},
			{"items": state.field_equipment, "type": "field_equipment"},
			{"items": state.field_gimmicks, "type": "field_gimmick"}
		]:
			for item in source["items"]:
				var pos: Vector2 = item.get("position", Vector2.INF)
				var validation: Dictionary = state.pickup_validation_result(pos, String(source["type"]), float(item.get("radius", -1.0)))
				summary["checked"] = int(summary["checked"]) + 1
				if not bool(validation.get("ok", false)):
					summary["invalid_count"] = int(summary["invalid_count"]) + 1
				var biome_id: String = state.biome_system.biome_id_for_position(state, pos)
				var key := "%d,%d" % [int(pos.x / 64.0), int(pos.y / 64.0)]
				if system.deterministic_variant(biome_id, "floor", key, seed) != system.deterministic_variant(biome_id, "floor", key, seed):
					summary["environment_variant_mismatch_count"] = int(summary["environment_variant_mismatch_count"]) + 1
	_write_report(report_stem, summary)
	return summary

func simulate_title_navigation(report_stem: String) -> Dictionary:
	var layout = preload("res://scripts/systems/IosTitleLayoutSystem.gd").new()
	var actions := layout.visible_action_ids()
	var summary := {
		"visible_action_count": actions.size(),
		"quit_hidden": not actions.has("quit"),
		"start_first": actions.size() > 0 and String(actions[0]) == "start"
	}
	_write_report(report_stem, summary)
	return summary

func _write_report(stem: String, summary: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
	var json := FileAccess.open("res://test-output/%s.json" % stem, FileAccess.WRITE)
	if json != null:
		json.store_string(JSON.stringify(summary, "\t"))
	var md := FileAccess.open("res://test-output/%s.md" % stem, FileAccess.WRITE)
	if md != null:
		md.store_line("# %s" % stem)
		md.store_line("")
		for key in summary.keys():
			md.store_line("- %s: %s" % [key, str(summary[key])])
