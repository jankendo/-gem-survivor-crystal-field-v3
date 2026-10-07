extends RefCounted

const DebugOverlaySystemScript = preload("res://scripts/systems/DebugOverlaySystem.gd")

func run(t) -> void:
	var overlay = DebugOverlaySystemScript.new()
	overlay.configure({}, "iOS", false)
	var normal_text := "HP 100 / 100　Lv 4　EXP 32%　時間 03:20　ミニマップ　目標"
	t.assert_true(not overlay.normal_ui_contains_forbidden_text(normal_text), "normal iOS HUD should contain no developer terms")
	for term in overlay.FORBIDDEN_IOS_TEXT:
		t.assert_true(overlay.normal_ui_contains_forbidden_text(String(term)), "forbidden developer term should be detected: %s" % term)
	t.assert_true(not overlay.should_show(), "developer overlay defaults to off")
	t.assert_eq(overlay.overlay_text(), "", "iOS should emit no profiler text")

