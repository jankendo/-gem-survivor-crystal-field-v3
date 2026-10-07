extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(1701)
	var first: Dictionary = state.weapon_effect("magic_bolt")
	var second: Dictionary = state.weapon_effect("magic_bolt")
	var stats: Dictionary = state.weapon_render_style_cache.stats()
	t.assert_true(is_same(first, second), "repeated style lookup should return the cached dictionary")
	t.assert_eq(int(stats.misses), 1, "first style resolution should miss once")
	t.assert_eq(int(stats.hits), 1, "second style resolution should hit")
	t.assert_true(first.is_read_only(), "resolved render style should be read-only")
	state.configure_render_profile("ios_low", false)
	var low: Dictionary = state.weapon_effect("magic_bolt")
	t.assert_eq(String(low.quality_profile), "ios_low", "quality changes should invalidate and rebuild the style")

