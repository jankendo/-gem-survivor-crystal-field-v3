extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const CacheScript = preload("res://scripts/systems/MinimapRenderCache.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(7718)
	var cache = CacheScript.new()
	var rect := Rect2(Vector2.ZERO, Vector2(180, 180))
	t.assert_true(cache.needs_rebuild(state, rect, false), "empty minimap cache should require an initial build")
	var commands := cache.rebuild(state, rect, false)
	t.assert_true(commands.size() > 1, "minimap cache should contain precomputed commands")
	t.assert_true(not cache.needs_rebuild(state, rect, false), "unchanged minimap state should reuse cached commands")
	t.assert_eq(cache.rebuild_count, 1, "cache should record its rebuild count")
	state.explored_room_ids.append("phase7_new_room")
	t.assert_true(cache.needs_rebuild(state, rect, false), "exploration changes should invalidate minimap commands")

