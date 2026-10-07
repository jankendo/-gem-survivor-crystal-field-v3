extends RefCounted

const SurvivorStateScript = preload("res://scripts/core/SurvivorState.gd")
const ChestSystemScript = preload("res://scripts/systems/ChestSystem.gd")

func run(t) -> void:
	test_chest_cap_and_expiry(t)
	test_elite_cooldown(t)
	test_rarity_resolution(t)

func test_chest_cap_and_expiry(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9103)
	var system = ChestSystemScript.new()
	var events: Array = []
	for i in range(4):
		system.drop_chest(state, state.player_position + Vector2(100 + i * 20, 0), events)
	t.assert_eq(state.chests.size(), 3, "field chests should cap at 3")
	system.process_pickups(state, events, 301.0)
	t.assert_eq(state.chests.size(), 0, "old chests should expire")
	t.assert_true(state.gems.size() >= 1, "expired chests should become big gems")

func test_elite_cooldown(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9104)
	t.assert_true(state.can_drop_elite_chest(), "elite chest should be initially available")
	state.reset_elite_chest_cooldown()
	t.assert_true(not state.can_drop_elite_chest(), "elite chest cooldown should block immediate repeats")
	state.elite_chest_cooldown = 0.0
	t.assert_true(state.can_drop_elite_chest(), "elite chest should unlock after cooldown")

func test_rarity_resolution(t) -> void:
	var state = SurvivorStateScript.new()
	state.start_new_run(9105)
	state.elapsed_seconds = 300.0
	state.weapons["magic_bolt"] = 8
	state.passives["might"] = 3
	var system = ChestSystemScript.new()
	var events: Array = []
	system.drop_chest(state, state.player_position + Vector2(80, 0), events, "normal", "boss")
	t.assert_eq(String(state.chests[0].rarity), "evolution", "boss chest should prioritize evolution when ready")
