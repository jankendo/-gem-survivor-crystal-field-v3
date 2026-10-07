extends RefCounted

const CharacterEvolutionSystemScript = preload("res://scripts/systems/CharacterEvolutionSystem.gd")

func run(t) -> void:
	test_character_evolution_data_complete(t)
	test_character_evolution_run_conditions(t)
	test_character_evolution_once_per_run(t)
	test_character_evolution_trait_upgrade(t)
	test_character_evolution_ui_lines_split_unlock_and_run_conditions(t)
	test_character_evolution_save_migration(t)

func test_character_evolution_data_complete(t) -> void:
	var characters = JSON.parse_string(FileAccess.open("res://data/characters.json", FileAccess.READ).get_as_text())
	var evolutions = JSON.parse_string(FileAccess.open("res://data/character_evolutions.json", FileAccess.READ).get_as_text())
	t.assert_true(characters is Dictionary and evolutions is Dictionary, "character evolution data should load")
	for id in characters.keys():
		t.assert_true(evolutions.has(String(id)), "every character should have evolution data: %s" % String(id))
		var path = String(evolutions[String(id)].get("evolved_sprite", ""))
		t.assert_true(FileAccess.file_exists(path), "evolved character asset should exist: %s" % path)

func test_character_evolution_run_conditions(t) -> void:
	var state = _ready_state()
	t.assert_true(CharacterEvolutionSystemScript.new().can_evolve(state), "character should evolve when run conditions are met")

func test_character_evolution_once_per_run(t) -> void:
	var state = _ready_state()
	var system = CharacterEvolutionSystemScript.new()
	var events: Array = []
	t.assert_true(system.apply_evolution(state, events), "first character evolution should apply")
	t.assert_true(not system.apply_evolution(state, events), "second character evolution in same run should be blocked")

func test_character_evolution_trait_upgrade(t) -> void:
	var state = _ready_state()
	var before = state.get_damage_multiplier()
	CharacterEvolutionSystemScript.new().apply_evolution(state, [])
	t.assert_true(state.character_evolved, "character evolved flag should be set")
	t.assert_true(state.get_damage_multiplier() > before, "character evolution should upgrade traits")

func test_character_evolution_ui_lines_split_unlock_and_run_conditions(t) -> void:
	var state = _ready_state()
	state.level = 12
	state.elapsed_seconds = 330.0
	state.gems_collected = 90
	var text = "\n".join(CharacterEvolutionSystemScript.new().run_condition_lines(state))
	t.assert_true(text.find("永久解放") >= 0, "character evolution UI should show permanent unlock group")
	t.assert_true(text.find("ラン中発動") >= 0, "character evolution UI should show run activation group")
	t.assert_true(text.find("12/20") >= 0, "character evolution UI should show current and required level")
	t.assert_true(text.find("発動できない理由") >= 0, "character evolution UI should explain blockers")

func test_character_evolution_save_migration(t) -> void:
	var save = SaveSystem.new("user://test_character_evolution_migration.save")
	save.save_data({"crystal_currency": 12})
	var data = save.load_data()
	t.assert_true(data.has("character_evolutions_unlocked"), "save migration should add evolution unlock table")
	t.assert_true(data.has("character_evolution_progress"), "save migration should add evolution progress table")

func _ready_state():
	var state = SurvivorState.new()
	state.start_new_run(0, "character-evolution")
	state.character_evolution_unlocked_ids = ["noah"]
	state.level = 20
	state.elapsed_seconds = 601.0
	state.gems_collected = 300
	return state
