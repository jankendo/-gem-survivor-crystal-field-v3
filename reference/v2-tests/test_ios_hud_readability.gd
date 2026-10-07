extends RefCounted

const NotificationLogSystemScript = preload("res://scripts/systems/NotificationLogSystem.gd")
const EquipmentHudSystemScript = preload("res://scripts/systems/EquipmentHudSystem.gd")
const IosLayoutDiagnosticSystemScript = preload("res://scripts/systems/IosLayoutDiagnosticSystem.gd")
const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var log = NotificationLogSystemScript.new()
	log.configure({"notification_log_enabled": true, "notification_log_amount": "standard"}, "iOS")
	for i in range(8):
		log.ingest({"type": "room_discovered", "name": "区画%d" % i}, float(i))
	t.assert_true(log.entries.size() <= 3, "iPhone HUD should show at most three notifications")

	var equipment = EquipmentHudSystemScript.new()
	equipment.configure({"equipment_hud_mode": "simple"})
	var state = SurvivorStateScript.new()
	state.start_new_run(12)
	t.assert_true(equipment.compact_text(state).length() < 100, "simple equipment HUD should stay compact")

	var row: Dictionary = IosLayoutDiagnosticSystemScript.new().snapshot(Vector2(1334, 750))
	var safe := _rect(row["safe_area"])
	t.assert_true(safe.encloses(_rect(row["minimap_rect"])), "compact phone HUD must keep minimap in safe area")
	t.assert_true(float(row["action_button_extent"]) >= 64.0, "compact phone HUD must preserve readable actions")

func _rect(data: Dictionary) -> Rect2:
	return Rect2(float(data["x"]), float(data["y"]), float(data["width"]), float(data["height"]))

