extends RefCounted

const EffectScript = preload("res://scripts/systems/EffectBatchSystem.gd")
const StateScript = preload("res://scripts/core/SurvivorState.gd")

func run(t) -> void:
	var state = StateScript.new()
	state.start_new_run(42)
	var expected: Array = state.weapon_defs.keys()
	for id in expected:
		t.assert_true(not state.weapon_effect(String(id)).is_empty(), "weapon effect metadata must remain available: %s" % id)
	var items := [
		{"text": "10", "pos": Vector2(100, 100), "life": 1.0},
		{"text": "15", "pos": Vector2(110, 100), "life": 1.0},
		{"text": "8", "pos": Vector2(2000, 2000), "life": 1.0}
	]
	var visible := EffectScript.new().visible_items(items, Vector2(100, 100), Vector2(400, 300))
	t.assert_eq(visible.size(), 2, "offscreen effects should be culled without dropping visible effects")
	t.assert_eq(EffectScript.new().merge_damage_numbers(visible).size(), 1, "same-frame nearby damage numbers should batch")
