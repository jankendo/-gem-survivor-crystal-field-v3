extends RefCounted

func run(t) -> void:
	test_different_seed_changes_field_equipment(t)
	test_same_seed_reproduces_field_equipment(t)
	test_eligible_pool_only(t)

func _signature(state) -> String:
	var parts: Array = []
	for equipment in state.field_equipment:
		var p: Vector2 = equipment.get("position", Vector2.ZERO)
		parts.append("%s:%s:%d:%d" % [String(equipment.get("kind", "")), String(equipment.get("id", "")), int(p.x), int(p.y)])
	return "|".join(parts)

func test_different_seed_changes_field_equipment(t) -> void:
	var a = SurvivorState.new()
	var b = SurvivorState.new()
	a.start_new_run(0, "field-random-a")
	b.start_new_run(0, "field-random-b")
	t.assert_true(_signature(a) != _signature(b), "different seeds should change field equipment")

func test_same_seed_reproduces_field_equipment(t) -> void:
	var a = SurvivorState.new()
	var b = SurvivorState.new()
	a.start_new_run(0, "field-random-same")
	b.start_new_run(0, "field-random-same")
	t.assert_eq(_signature(a), _signature(b), "same seed should reproduce field equipment content and position")

func test_eligible_pool_only(t) -> void:
	var state = SurvivorState.new()
	state.start_new_run(0, "field-random-eligible")
	for equipment in state.field_equipment:
		var kind = String(equipment.get("kind", ""))
		var id = String(equipment.get("id", ""))
		t.assert_true(kind == "weapon" and state.unlocked_weapon_ids.has(id) or kind == "passive" and state.unlocked_passive_ids.has(id), "field equipment should use unlocked pools only")
		t.assert_true(not state.disabled_weapon_ids.has(id) and not state.disabled_passive_ids.has(id), "field equipment should exclude disabled items")
