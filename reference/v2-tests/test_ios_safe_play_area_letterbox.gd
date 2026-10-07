extends RefCounted

const SafePlayScript = preload("res://scripts/systems/IosSafePlayAreaSystem.gd")
const InputScript = preload("res://scripts/systems/SafePlayInputMapper.gd")

func run(t) -> void:
	var system = SafePlayScript.new()
	var viewport := Vector2(2796, 1290)
	var rect: Rect2 = system.safe_play_rect(viewport, {"notch_protection": true, "safe_area_margin": 16.0}, true, Rect2(Vector2(96, 20), Vector2(2604, 1234)))
	var left: float = rect.position.x
	var right: float = viewport.x - rect.end.x
	t.assert_true(absf(left - right) <= 0.01, "Safe Play Area should use symmetric left/right letterbox bars")
	t.assert_true(left >= 86.0, "iPhone notch protection should reserve a real side bar")
	var bars: Array = system.letterbox_bars(viewport, rect)
	t.assert_eq(bars.size(), 2, "notch letterbox should create left and right bars")
	var mapper = InputScript.new()
	t.assert_true(not mapper.accepts(Vector2(left * 0.5, viewport.y * 0.5), rect), "letterbox bars must not accept input")
	t.assert_true(mapper.accepts(rect.get_center(), rect), "center play area should accept input")
	var off: Rect2 = system.safe_play_rect(viewport, {"notch_protection": false}, true, Rect2(Vector2.ZERO, viewport))
	t.assert_eq(off.position, Vector2.ZERO, "notch protection off should allow full viewport")
