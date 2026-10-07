extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(7007)
	state.configure_render_profile("ios_standard", true)
	state.elapsed_seconds = 10.0
	state.add_hit_flash({"pos": Vector2(100, 100), "source": "bomb_seed", "life": 0.2, "radius": 30.0})
	state.add_hit_flash({"pos": Vector2(112, 108), "source": "bomb_seed", "life": 0.3, "radius": 44.0})
	t.assert_eq(state.hit_flashes.size(), 1, "nearby same-source flashes in the coalescing window should share one command")
	t.assert_eq(int(state.hit_flashes[0].get("coalesced_count", 1)), 2, "coalesced command should retain its represented count")
	t.assert_eq(float(state.hit_flashes[0].get("radius", 0.0)), 44.0, "coalescing should retain the strongest representative radius")
	var metrics: Dictionary = state.visual_effect_command_buffer.snapshot()
	t.assert_eq(int(metrics.get("created", 0)), 2, "QA metrics should count source commands")
	t.assert_eq(int(metrics.get("coalesced", 0)), 1, "QA metrics should count merged commands")

