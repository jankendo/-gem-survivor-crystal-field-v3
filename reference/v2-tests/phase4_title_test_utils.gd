extends RefCounted
class_name Phase4TitleTestUtils

const SafeScript = preload("res://scripts/systems/MobileSafeAreaSystem.gd")
const LayoutScript = preload("res://scripts/systems/IosTitleLayoutSystem.gd")
const GuardScript = preload("res://scripts/systems/IosSafeAreaGuardSystem.gd")

const ACTION_IDS := [
	"start",
	"characters",
	"shop",
	"loadout",
	"collection",
	"quests",
	"settings",
	"help",
	"reset",
	"quit"
]

func run(t, mode: String) -> void:
	match mode:
		"fit":
			_assert_fit(t)
		"safe_area":
			_assert_safe_area(t)
		"button_visibility":
			_assert_button_visibility(t)
		"hit_targets":
			_assert_hit_targets(t)
		"rotation":
			_assert_rotation(t)
		"all_profiles":
			_assert_all_profiles(t)
		"scroll_fallback":
			_assert_scroll_fallback(t)
		"windows_regression":
			_assert_windows_regression(t)

func profile_contracts() -> Array:
	var safe_system = SafeScript.new()
	var layout_system = LayoutScript.new()
	var result: Array = []
	for profile in layout_system.device_profiles():
		for orientation in ["landscape_left", "landscape_right"]:
			var size: Vector2 = profile["size"]
			var safe := safe_system.safe_rect_for_orientation(size, orientation, 16.0)
			var contract := layout_system.contract(size, safe, ACTION_IDS)
			contract["profile_id"] = String(profile["id"])
			contract["orientation"] = orientation
			result.append(contract)
	return result

func _assert_fit(t) -> void:
	var layout_system = LayoutScript.new()
	for contract in profile_contracts():
		var safe: Rect2 = contract["safe_rect"]
		var content_size: Vector2 = contract["content_size"]
		t.assert_true(content_size.x <= safe.size.x + 0.01, "%s %s title content width must fit safe area" % [contract["profile_id"], contract["orientation"]])
		t.assert_true(layout_system.all_buttons_fit_width(safe.size, safe, ACTION_IDS), "%s buttons must fit content width" % contract["profile_id"])

func _assert_safe_area(t) -> void:
	var guard = GuardScript.new()
	for contract in profile_contracts():
		var safe: Rect2 = contract["safe_rect"]
		var violations := guard.violations({"scroll": contract["scroll_rect"]}, safe)
		t.assert_true(violations.is_empty(), "%s %s title scroll viewport must stay inside safe area" % [contract["profile_id"], contract["orientation"]])

func _assert_button_visibility(t) -> void:
	for contract in profile_contracts():
		var safe: Rect2 = contract["safe_rect"]
		var rects: Dictionary = contract["rects"]
		t.assert_true((rects["button.start"] as Rect2).end.y <= safe.size.y + 0.01, "%s start button must be visible without scrolling" % contract["profile_id"])
		for action_id in LayoutScript.new().visible_action_ids(ACTION_IDS):
			t.assert_true(rects.has("button.%s" % action_id), "touch title must expose reachable button: %s" % action_id)
		t.assert_true(not rects.has("button.quit"), "touch title must hide quit button on iOS/touch")

func _assert_hit_targets(t) -> void:
	for contract in profile_contracts():
		var rects: Dictionary = contract["rects"]
		for key in rects.keys():
			if not String(key).begins_with("button."):
				continue
			var rect: Rect2 = rects[key]
			t.assert_true(rect.size.x >= 88.0, "%s width must exceed touch target floor" % key)
			t.assert_true(rect.size.y >= 56.0, "%s height must exceed 44pt-equivalent floor" % key)

func _assert_rotation(t) -> void:
	var safe_system = SafeScript.new()
	var layout_system = LayoutScript.new()
	for profile in layout_system.device_profiles():
		var size: Vector2 = profile["size"]
		var left := layout_system.contract(size, safe_system.safe_rect_for_orientation(size, "landscape_left", 16.0), ACTION_IDS)
		var right := layout_system.contract(size, safe_system.safe_rect_for_orientation(size, "landscape_right", 16.0), ACTION_IDS)
		t.assert_eq((left["content_size"] as Vector2).x, (right["content_size"] as Vector2).x, "%s rotation must not change usable content width" % profile["id"])
		t.assert_eq((left["rects"] as Dictionary).keys().size(), (right["rects"] as Dictionary).keys().size(), "%s rotation must keep same title controls" % profile["id"])

func _assert_all_profiles(t) -> void:
	var layout_system = LayoutScript.new()
	var profiles := layout_system.device_profiles()
	t.assert_true(profiles.size() >= 7, "title layout must cover current iPhone/iPad landscape profiles")
	for contract in profile_contracts():
		var metrics: Dictionary = contract["metrics"]
		t.assert_true(["compact_phone", "regular_phone", "large_phone", "tablet"].has(String(metrics.get("profile", ""))), "profile must classify into supported bucket")
		t.assert_true(int(metrics.get("columns", 0)) >= 2, "landscape title should keep at least two columns on supported profiles")

func _assert_scroll_fallback(t) -> void:
	var layout_system = LayoutScript.new()
	var contract := layout_system.contract(Vector2(700, 360), Rect2(Vector2(24, 16), Vector2(652, 312)), ACTION_IDS)
	t.assert_true(bool(contract.get("scroll_required", false)), "compact fallback must enable vertical scroll instead of clipping")
	t.assert_true((contract["content_size"] as Vector2).x <= (contract["safe_rect"] as Rect2).size.x + 0.01, "compact fallback must not need horizontal scroll")

func _assert_windows_regression(t) -> void:
	t.assert_eq(String(ProjectSettings.get_setting("display/window/stretch/aspect")), "keep", "Windows project stretch aspect must remain keep")
	t.assert_eq(String(ProjectSettings.get_setting("display/window/stretch/mode")), "canvas_items", "Windows project stretch mode must remain canvas_items")
