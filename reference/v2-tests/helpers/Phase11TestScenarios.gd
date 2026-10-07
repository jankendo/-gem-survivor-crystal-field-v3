extends RefCounted

const StateScript = preload("res://scripts/core/SurvivorState.gd")
const WarpScript = preload("res://scripts/systems/WarpRoomSystem.gd")
const WarpTypeScript = preload("res://scripts/systems/WarpRoomTypeResolver.gd")
const ChestScript = preload("res://scripts/systems/ChestSystem.gd")
const CandidateScript = preload("res://scripts/systems/CoreCandidateSystem.gd")
const CoreChoiceScript = preload("res://scripts/systems/CorePickupChoiceSystem.gd")
const ReplacementScript = preload("res://scripts/systems/LoadoutReplacementSystem.gd")
const ComboResolverScript = preload("res://scripts/systems/WeaponComboResolver.gd")
const ComboSystemScript = preload("res://scripts/systems/WeaponComboSystem.gd")
const WeaponSystemScript = preload("res://scripts/systems/WeaponSystem.gd")
const EnemyScript = preload("res://scripts/core/SurvivorEnemy.gd")
const ResultFormatterScript = preload("res://scripts/systems/ResultDamageFormatter.gd")

func state(seed: int = 11111):
	var value = StateScript.new()
	value.start_new_run(seed, "phase11-%d" % seed)
	value.unlocked_weapon_ids = value.weapon_defs.keys()
	value.unlocked_passive_ids = value.passive_defs.keys()
	value.disabled_weapon_ids = []
	value.disabled_passive_ids = []
	return value

func warp_chest_collection(t) -> void:
	var pair := _entered_warp("normal")
	var s = pair[0]
	var system = pair[1]
	_clear_all_waves(s, system)
	t.assert_true(not s.chests.is_empty(), "warp clear creates physical chests")
	var chest = s.chests[0]
	var before: int = s.chests_opened
	var main_rng_before: Dictionary = s.rng.snapshot()
	s.player_position = chest.position
	ChestScript.new().process_pickups(s, [], 0.1)
	t.assert_eq(s.chests_opened, before + 1, "normal chest pickup path opens warp chest")
	t.assert_true(not s.chests.has(chest), "opened warp chest is removed once")
	t.assert_eq(s.rng.snapshot(), main_rng_before, "warp chest reward does not consume main combat RNG")

func warp_chest_reward_once(t) -> void:
	var pair := _entered_warp("normal")
	var s = pair[0]
	var system = pair[1]
	_clear_all_waves(s, system)
	var score: int = s.score
	var chest_count: int = s.chests.size()
	var drop_count: int = s.field_drops.size()
	for index in range(6):
		system.process_challenge(s, 0.0, [])
	t.assert_eq(s.score, score, "warp clear score is committed once")
	t.assert_eq(s.chests.size(), chest_count, "warp chests are spawned once")
	t.assert_eq(s.field_drops.size(), drop_count, "warp items are spawned once")

func warp_room_type_determinism(t) -> void:
	var a = _warp_state(2311)
	var b = _warp_state(2311)
	var wa = WarpScript.new()
	var wb = WarpScript.new()
	wa.initialize_run(a)
	wb.initialize_run(b)
	t.assert_eq(a.warp_portals, b.warp_portals, "same seed resolves identical room type and content")

func warp_room_type_distribution(t) -> void:
	var resolver = WarpTypeScript.new()
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/warp_rooms.json"))
	var counts := {"normal": 0, "heaven": 0, "hell": 0}
	var s = state(70000)
	for seed in range(10000):
		s.rng.set_seed_value(seed + 70000)
		var kind: String = resolver.resolve(s, "distribution", config)
		counts[kind] = int(counts.get(kind, 0)) + 1
	t.assert_true(absf(float(counts.normal) / 10000.0 - 0.50) < 0.025, "normal room distribution stays near 50 percent")
	t.assert_true(absf(float(counts.heaven) / 10000.0 - 0.25) < 0.022, "heaven room distribution stays near 25 percent")
	t.assert_true(absf(float(counts.hell) / 10000.0 - 0.25) < 0.022, "hell room distribution stays near 25 percent")

func warp_room_identity_ui(t) -> void:
	var pair := _entered_warp("heaven")
	var s = pair[0]
	t.assert_eq(String(s.warp_room_presentation.get("display_name_ja", "")), "天上宝晶庭", "heaven identity has Japanese title")
	t.assert_true(String(s.warp_room_presentation.get("danger_ja", "")).find("★") >= 0, "identity includes danger")
	var source := FileAccess.get_file_as_string("res://scripts/ui/GameScreen.gd")
	t.assert_true(source.find("warp_identity_label") >= 0 and source.find("報酬:") >= 0, "runtime UI presents room identity and reward tendency")

func warp_normal_room_flow(t) -> void:
	_assert_warp_flow(t, "normal", 3)

func warp_heaven_room_flow(t) -> void:
	_assert_warp_flow(t, "heaven", 1)

func warp_hell_room_flow(t) -> void:
	_assert_warp_flow(t, "hell", 5)

func warp_heaven_loot_quantity(t) -> void:
	var pair := _entered_warp("heaven")
	var s = pair[0]
	_clear_all_waves(s, pair[1])
	t.assert_true(s.chests.size() >= 4 and s.chests.size() <= 6, "heaven creates four to six chests")
	t.assert_true(s.field_drops.size() >= 8 and s.field_drops.size() <= 12, "heaven creates eight to twelve items")
	var core_count := 0
	for drop in s.field_drops:
		if String(drop.get("id", "")) in ["weapon_core", "passive_core"]:
			core_count += 1
	t.assert_true(core_count >= 1, "heaven includes at least one core")

func warp_hell_difficulty(t) -> void:
	var pair := _entered_warp("hell")
	var s = pair[0]
	var system = pair[1]
	system.process_challenge(s, 0.1, [])
	t.assert_true(s.enemies.size() >= 24, "hell first wave applies high density multiplier")
	var enemy = s.enemies[0]
	var base: Dictionary = s.enemy_defs.get(enemy.type, {})
	t.assert_true(enemy.max_hp >= int(round(float(base.get("hp", 1)) * 1.35)), "hell enemy HP multiplier is applied")
	t.assert_true(enemy.damage >= int(round(float(base.get("damage", 1)) * 1.25)), "hell enemy damage multiplier is applied")

func warp_reward_safe_placement(t) -> void:
	var s = _warp_state(500)
	for seed in range(500, 600):
		s.rng.set_seed_value(seed)
		var system = WarpScript.new()
		system.initialize_run(s)
		s.player_position = s.warp_portals[0].get("position", Vector2.ZERO)
		system.process_entry(s, [])
		_clear_all_waves(s, system)
		var positions: Array = [s.warp_room_exit_position]
		for chest in s.chests:
			t.assert_true(s.is_walkable_position(chest.position, 28.0), "warp chest is on reachable safe floor for seed %d" % seed)
			positions.append(chest.position)
		for drop in s.field_drops:
			var pos: Vector2 = drop.get("position", Vector2.INF)
			t.assert_true(s.is_walkable_position(pos, 24.0), "warp item is on reachable safe floor for seed %d" % seed)
			positions.append(pos)
		for a in range(positions.size()):
			for b in range(a + 1, positions.size()):
				t.assert_true(positions[a].distance_to(positions[b]) >= 77.9, "warp rewards do not overlap for seed %d" % seed)
		s.player_position = s.warp_room_exit_position
		system.process_challenge(s, 0.0, [])
		t.assert_true(not s.warp_room_active, "placement fixture returns to main field for seed %d" % seed)

func core_candidates_at_capacity(t) -> void:
	var s = state()
	_fill_weapon_capacity(s)
	var options := CandidateScript.new().make_options(s, "weapon", 12, "capacity")
	t.assert_true(not options.is_empty(), "core offers candidates at full capacity")
	var found_new := false
	for option in options:
		if bool(option.get("requires_replacement", false)):
			found_new = true
	t.assert_true(found_new, "full loadout can offer an unowned replacement candidate")

func core_candidate_randomness(t) -> void:
	var signatures: Dictionary = {}
	for seed in range(20, 44):
		var s = state(seed)
		_fill_weapon_capacity(s)
		var options := CandidateScript.new().make_options(s, "weapon", 3, "randomness")
		signatures[_option_signature(options)] = true
	t.assert_true(signatures.size() >= 3, "core candidates vary across seeds")
	var a = state(555)
	var b = state(555)
	_fill_weapon_capacity(a)
	_fill_weapon_capacity(b)
	t.assert_eq(_option_signature(CandidateScript.new().make_options(a, "weapon", 3, "same")), _option_signature(CandidateScript.new().make_options(b, "weapon", 3, "same")), "core candidates remain deterministic per seed")

func loadout_replacement_transaction(t) -> void:
	var s = state()
	_fill_weapon_capacity(s)
	var new_id := _first_unowned_weapon(s)
	var drop := {"runtime_id": "replace-test", "id": "weapon_core", "position": s.player_position, "collected": false}
	var core = CoreChoiceScript.new()
	t.assert_true(core.open_choice(s, "weapon", drop, [], 32), "core choice opens")
	var candidate := _option_for_id(s.level_up_options, new_id)
	t.assert_true(not candidate.is_empty(), "unowned candidate is present")
	t.assert_true(core.accept_current(s, String(candidate.uid), []), "replacement selection opens")
	var old_id := String(s.weapons.keys()[0])
	t.assert_true(ReplacementScript.new().choose(s, "replace:weapon:%s" % old_id, []), "replacement commits")
	t.assert_true(s.weapons.has(new_id) and not s.weapons.has(old_id), "old weapon is atomically replaced")
	t.assert_true(bool(drop.collected), "core source is consumed only after commit")
	t.assert_eq(s.weapons.size(), s.normal_weapon_cap(), "replacement preserves weapon capacity")

func loadout_replacement_rollback(t) -> void:
	var s = state()
	_fill_weapon_capacity(s)
	var new_id := _first_unowned_weapon(s)
	var drop := {"runtime_id": "rollback-test", "id": "weapon_core", "position": s.player_position, "collected": false}
	var core = CoreChoiceScript.new()
	core.open_choice(s, "weapon", drop, [], 32)
	var candidate := _option_for_id(s.level_up_options, new_id)
	core.accept_current(s, String(candidate.uid), [])
	var before: Dictionary = s.weapons.duplicate(true)
	var old_id := String(s.weapons.keys()[0])
	var events: Array = []
	t.assert_true(not ReplacementScript.new().choose(s, "replace:weapon:%s" % old_id, events, true), "simulated failure returns false")
	t.assert_eq(s.weapons, before, "failed replacement rolls back all weapons")
	t.assert_true(not bool(drop.collected), "failed replacement does not consume core")
	t.assert_true(_has_event(events, "loadout_replacement_rollback"), "rollback is observable")

func weapon_combo_data_validation(t) -> void:
	var s = state()
	var resolver = ComboResolverScript.new()
	t.assert_eq(resolver.combos.size(), 16, "sixteen curated combos are defined")
	t.assert_true(resolver.validate(s.weapon_defs, s.evolution_defs).is_empty(), "combo data validates")
	var coverage := resolver.coverage(s.weapon_defs)
	t.assert_eq(int(coverage.covered), int(coverage.total), "all base weapons are covered by a combo")

func weapon_combo_activation(t) -> void:
	var s = state()
	s.weapons = {"magic_bolt": 1, "bomb_seed": 1}
	var events: Array = []
	var combos = ComboSystemScript.new()
	combos.initialize(s, events)
	t.assert_true(s.weapon_combo_runtime.active.has("starburst_seed"), "owned pair activates combo")
	t.assert_true(_has_event(events, "weapon_combo_activated"), "activation emits one clear event")

func weapon_combo_deactivation(t) -> void:
	var s = state()
	s.weapons = {"magic_bolt": 1, "bomb_seed": 1}
	var events: Array = []
	var combos = ComboSystemScript.new()
	combos.initialize(s, events)
	s.weapons.erase("bomb_seed")
	events.clear()
	combos.refresh(s, events)
	t.assert_true(not s.weapon_combo_runtime.active.has("starburst_seed"), "removing a weapon deactivates combo")
	t.assert_true(_has_event(events, "weapon_combo_deactivated"), "deactivation emits an event")

func weapon_combo_evolved_alias(t) -> void:
	var s = state()
	s.weapons = {"magic_bolt": 8, "bomb_seed": 8}
	s.evolved_weapons = {"magic_bolt": true, "bomb_seed": true}
	var combos = ComboSystemScript.new()
	combos.initialize(s)
	t.assert_true(s.weapon_combo_runtime.active.has("starburst_seed"), "evolved base weapons keep combo active")
	var combo: Dictionary = s.weapon_combo_runtime.active.starburst_seed
	t.assert_true((combo.weapon_a_aliases as Array).has("starbreaker_bolt") and (combo.weapon_b_aliases as Array).has("final_fireworks"), "evolved aliases are explicit in data")

func weapon_combo_determinism(t) -> void:
	var a = state(9090)
	var b = state(9090)
	a.weapons = {"ice_orbit": 3, "thunder_chain": 4}
	b.weapons = a.weapons.duplicate(true)
	var ca = ComboSystemScript.new()
	var cb = ComboSystemScript.new()
	ca.initialize(a)
	cb.initialize(b)
	t.assert_eq(a.weapon_combo_runtime.cooldowns, b.weapon_combo_runtime.cooldowns, "combo phase offsets are deterministic")

func weapon_combo_damage_attribution(t) -> void:
	var fixture := _combo_damage_fixture()
	var s = fixture[0]
	var combo = fixture[1]
	var weapon = fixture[2]
	combo.process(s, 0.1, [], weapon)
	t.assert_true(int(s.weapon_combo_runtime.damage.get("frozen_thunder_ring", 0)) > 0, "combo damage is tracked by combo ID")
	t.assert_eq(int(s.weapon_damage_by_id.get("weapon_combo:frozen_thunder_ring", 0)), 0, "combo damage is not double-counted as a weapon")
	t.assert_true(int(s.damage_by_category.get("weapon_combo", 0)) > 0, "combo category receives damage")

func weapon_combo_no_recursion(t) -> void:
	var fixture := _combo_damage_fixture()
	var s = fixture[0]
	var combo = fixture[1]
	var weapon = fixture[2]
	for index in range(30):
		s.weapon_combo_runtime.cooldowns["frozen_thunder_ring"] = 0.0
		combo.process(s, 0.1, [], weapon)
	t.assert_eq(s.weapon_combo_runtime.active.size(), 1, "combo attacks do not create recursive combos")
	t.assert_true(not s.weapons.has("weapon_combo:frozen_thunder_ring"), "combo source never enters loadout")

func weapon_combo_ui(t) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/GameScreen.gd")
	t.assert_true(source.find("武器連携成立") >= 0, "combo activation has Japanese HUD feedback")
	t.assert_true(source.find("所持武器の連携候補") >= 0, "pause UI exposes combo candidates")
	t.assert_true(source.find("active_status_lines") >= 0, "pause UI exposes active combo details")

func weapon_combo_result_summary(t) -> void:
	var summary := {
		"weapon_damage_by_id": {"ice_orbit": 600},
		"weapon_combo_damage_by_id": {"frozen_thunder_ring": 400},
		"weapon_combo_activation_by_id": {"frozen_thunder_ring": 5}
	}
	var text := "\n".join(ResultFormatterScript.new().weapon_damage_lines(summary))
	t.assert_true(text.find("連携攻撃ダメージ") >= 0 and text.find("氷雷環") >= 0, "result has a separate combo damage section")
	t.assert_true(text.find("40.0%") >= 0, "combo percentage uses weapon plus combo denominator")

func weapon_combo_performance(t) -> void:
	var fixture := _combo_damage_fixture(500)
	var s = fixture[0]
	var combo = fixture[1]
	var weapon = fixture[2]
	var started := Time.get_ticks_usec()
	for index in range(180):
		s.weapon_combo_runtime.cooldowns["frozen_thunder_ring"] = 0.0
		combo.process(s, 1.0 / 60.0, [], weapon)
	var duration := Time.get_ticks_usec() - started
	t.assert_true(duration < 1500000, "three seconds of dense combo scheduling stays within test CPU budget")
	t.assert_true(int(s.weapon_combo_runtime.get("visual_commands", 0)) <= 1800, "visual commands remain bounded")

func ios_warp_combo_layout(t) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/GameScreen.gd")
	t.assert_true(source.find("_runtime_safe_rect") >= 0, "Phase 11 HUD uses existing safe area contract")
	t.assert_true(source.find("warp_identity_label.offset_left = safe_left") >= 0, "warp identity respects left safe inset")
	t.assert_true(source.find("warp_identity_label.offset_right = -safe_right") >= 0, "warp identity respects right safe inset")
	t.assert_true(source.find("damage_number") < 0 or FileAccess.get_file_as_string("res://scripts/ui/ArenaView.gd").find("_draw_damage_numbers") < 0, "Phase 11 does not restore damage numbers")

func _combo_damage_fixture(enemy_count: int = 12) -> Array:
	var s = state(8080)
	s.weapons = {"ice_orbit": 3, "thunder_chain": 3}
	s.enemies = []
	for index in range(enemy_count):
		var pos: Vector2 = s.player_position + Vector2(80 + index % 25 * 18, index / 25 * 18)
		s.enemies.append(EnemyScript.new("slime", {"hp": 100000, "damage": 1, "radius": 18.0}, pos))
	var weapon = WeaponSystemScript.new()
	weapon.enemy_grid.rebuild(s.enemies)
	var combo = ComboSystemScript.new()
	combo.initialize(s)
	s.weapon_combo_runtime.cooldowns["frozen_thunder_ring"] = 0.0
	return [s, combo, weapon]

func _assert_warp_flow(t, kind: String, wave_count: int) -> void:
	var pair := _entered_warp(kind)
	var s = pair[0]
	var system = pair[1]
	t.assert_eq(s.warp_room_kind, kind, "%s room entered" % kind)
	t.assert_eq((system.current_portal.get("waves", []) as Array).size(), wave_count, "%s wave count matches contract" % kind)
	_clear_all_waves(s, system)
	t.assert_true(s.warp_room_exit_ready, "%s exit appears after all enemies are gone" % kind)
	t.assert_true(not s.chests.is_empty(), "%s clear creates rewards" % kind)

func _entered_warp(kind: String) -> Array:
	return _entered_warp_for_seed(kind, 1)

func _entered_warp_for_seed(kind: String, start_seed: int) -> Array:
	for seed in range(start_seed, start_seed + 2000):
		var s = _warp_state(seed)
		var system = WarpScript.new()
		system.initialize_run(s)
		if String(s.warp_portals[0].get("kind", "")) != kind:
			continue
		s.player_position = s.warp_portals[0].get("position", Vector2.ZERO)
		system.process_entry(s, [])
		return [s, system]
	return []

func _warp_state(seed: int):
	var s = state(seed)
	s.elapsed_seconds = 900.0
	var source: Dictionary = s.map_data.get("rooms", [])[0]
	var cave := source.duplicate(true)
	cave["id"] = "phase11-cave"
	cave["shape"] = "cave_room"
	s.map_data["rooms"] = [cave]
	return s

func _clear_all_waves(s, system) -> void:
	for guard in range(24):
		system.process_challenge(s, 0.1, [])
		for enemy in s.enemies:
			s.release_runtime("enemy", enemy)
		s.enemies.clear()
		if s.warp_room_exit_ready:
			return

func _fill_weapon_capacity(s) -> void:
	s.weapons = {}
	var ids: Array = s.weapon_defs.keys()
	ids.sort()
	for id in ids:
		if s.weapons.size() >= s.normal_weapon_cap():
			break
		s.weapons[String(id)] = 1

func _first_unowned_weapon(s) -> String:
	for raw_id in s.weapon_defs.keys():
		var id := String(raw_id)
		if not s.weapons.has(id):
			return id
	return ""

func _option_for_id(options: Array, id: String) -> Dictionary:
	for option in options:
		if String(option.get("id", "")) == id:
			return option
	return {}

func _option_signature(options: Array) -> String:
	var ids: Array = []
	for option in options:
		ids.append(String(option.get("id", "")))
	return "|".join(ids)

func _has_event(events: Array, type: String) -> bool:
	for event in events:
		if String(event.get("type", "")) == type:
			return true
	return false
