extends SceneTree

const Utils = preload("res://tests/item_placement_test_utils.gd")

func _initialize() -> void:
	var summary := {
		"seed_count": 100,
		"item_total": 0,
		"outside_map_count": 0,
		"wall_overlap_count": 0,
		"void_position_count": 0,
		"unreachable_item_count": 0,
		"determinism_difference_count": 0,
		"reroll_count": 0,
		"repair_count": 0
	}
	var signatures: Dictionary = {}
	for i in range(100):
		var seed := 70000 + i
		var state = Utils.new_state(seed)
		var invalid := _count_invalid(state)
		for key in invalid.keys():
			summary[key] = int(summary.get(key, 0)) + int(invalid[key])
		summary["item_total"] = int(summary["item_total"]) + int(invalid.get("checked", 0))
		var telemetry: Dictionary = state.item_placement_telemetry.summary()
		summary["reroll_count"] = int(summary["reroll_count"]) + int(telemetry.get("reroll_count", 0))
		summary["repair_count"] = int(summary["repair_count"]) + int(telemetry.get("repaired_count", 0))
		signatures[seed] = state.map_signature()
	for i in range(100):
		var seed := 70000 + i
		var state = Utils.new_state(seed)
		if String(signatures[seed]) != state.map_signature():
			summary["determinism_difference_count"] = int(summary["determinism_difference_count"]) + 1
	_write_reports(summary)
	if int(summary["outside_map_count"]) == 0 and int(summary["wall_overlap_count"]) == 0 and int(summary["void_position_count"]) == 0 and int(summary["unreachable_item_count"]) == 0 and int(summary["determinism_difference_count"]) == 0:
		print("Item placement QA OK: ", summary)
		quit(0)
	else:
		push_error("Item placement QA failed: %s" % str(summary))
		quit(1)

func _count_invalid(state) -> Dictionary:
	var invalid := {
		"outside_map_count": 0,
		"wall_overlap_count": 0,
		"void_position_count": 0,
		"unreachable_item_count": 0,
		"checked": 0
	}
	for source in [
		{"items": state.field_drops, "type": "field_drop"},
		{"items": state.field_equipment, "type": "field_equipment"},
		{"items": state.field_gimmicks, "type": "field_gimmick"}
	]:
		for item in source["items"]:
			var result: Dictionary = state.pickup_validation_result(item.get("position", Vector2.INF), String(source["type"]), float(item.get("radius", -1.0)))
			invalid["checked"] = int(invalid["checked"]) + 1
			for reason in result.get("reasons", []):
				match String(reason):
					"outside_map":
						invalid["outside_map_count"] = int(invalid["outside_map_count"]) + 1
					"wall_clearance":
						invalid["wall_overlap_count"] = int(invalid["wall_overlap_count"]) + 1
					"not_walkable":
						invalid["void_position_count"] = int(invalid["void_position_count"]) + 1
					"unreachable":
						invalid["unreachable_item_count"] = int(invalid["unreachable_item_count"]) + 1
	return invalid

func _write_reports(summary: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
	var json := FileAccess.open("res://test-output/item_placement_summary.json", FileAccess.WRITE)
	if json != null:
		json.store_string(JSON.stringify(summary, "\t"))
	var md := FileAccess.open("res://test-output/item_placement_qa.md", FileAccess.WRITE)
	if md != null:
		md.store_line("# Item Placement QA")
		md.store_line("")
		for key in summary.keys():
			md.store_line("- %s: %s" % [key, str(summary[key])])
