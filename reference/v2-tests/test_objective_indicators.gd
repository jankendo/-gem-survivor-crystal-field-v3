extends RefCounted

const ObjectiveIndicatorSystemScript = preload("res://scripts/systems/ObjectiveIndicatorSystem.gd")
const ChestScript = preload("res://scripts/core/Chest.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")

func run(t) -> void:
	test_targets_are_priority_sorted_and_limited(t)
	test_heal_priority_rises_when_low_hp(t)
	test_targets_have_distance_for_edge_display(t)
	test_legacy_navigation_targets_are_preserved(t)

func _state():
	var state = SurvivorState.new()
	state.start_new_run(7070, "objective")
	state.player_position = Vector2(1000, 1000)
	state.field_drops = [
		{"id": "weapon_core", "name_ja": "武器コア", "position": Vector2(3000, 1000), "unlock_seconds": 0.0, "priority": 4, "color": [0.4, 0.9, 1.0]},
		{"id": "evolution_core", "name_ja": "進化核", "position": Vector2(3100, 1000), "unlock_seconds": 0.0, "priority": 1, "color": [1.0, 0.9, 0.3]},
		{"id": "heal_ore", "name_ja": "回復鉱石", "position": Vector2(900, 2300), "unlock_seconds": 0.0, "priority": 6, "color": [0.4, 1.0, 0.5]}
	]
	state.chests = [ChestScript.new(Vector2(2500, 1300), "normal", "test")]
	state.enemies = [EnemyScript.new("boss_test", {"name_ja": "ボス", "boss": true, "hp": 100}, Vector2(2600, 900))]
	return state

func test_targets_are_priority_sorted_and_limited(t) -> void:
	var targets = ObjectiveIndicatorSystemScript.new().targets_for_state(_state(), 3)
	t.assert_eq(targets.size(), 3, "objective indicators should cap at 3")
	t.assert_eq(String(targets[0].get("label", "")), "進化核", "evolution core should be top priority")

func test_heal_priority_rises_when_low_hp(t) -> void:
	var state = _state()
	state.hp = 30
	state.max_hp = 100
	var targets = ObjectiveIndicatorSystemScript.new().targets_for_state(state, 3)
	var found_heal = false
	for target in targets:
		if String(target.get("label", "")) == "回復鉱石":
			found_heal = true
	t.assert_true(found_heal, "heal ore should rise when HP is low")

func test_targets_have_distance_for_edge_display(t) -> void:
	var targets = ObjectiveIndicatorSystemScript.new().targets_for_state(_state(), 3)
	for target in targets:
		t.assert_true(float(target.get("distance", 0.0)) > 0.0, "target should include distance")

func test_legacy_navigation_targets_are_preserved(t) -> void:
	var state = _state()
	state.field_drops = []
	state.field_gimmicks = []
	state.chests = []
	state.enemies = []
	state.gems = []
	state.danger_zones = [{"position": Vector2(1800, 1500), "radius": 180.0}]
	state.navigation_targets["field_event"] = Vector2(2200, 1800)
	var targets = ObjectiveIndicatorSystemScript.new().targets_for_state(state, 4)
	var labels: Array = []
	for target in targets:
		labels.append(String(target.get("label", "")))
	t.assert_true(labels.has("危険地帯"), "danger zone target should be preserved")
	t.assert_true(not labels.has("イベント候補"), "legacy field-event coordinates must not create a fake event arrow")
