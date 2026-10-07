extends RefCounted

func run(t) -> void:
	var characters = _json("res://data/characters.json")
	var weapons = _json("res://data/weapons.json")
	var passives = _json("res://data/passives.json")
	var evolutions = _json("res://data/evolutions.json")
	var character_unlocks = _json("res://data/character_unlocks.json")
	var weapon_unlocks = _json("res://data/weapon_unlocks.json")
	var passive_unlocks = _json("res://data/passive_unlocks.json")
	t.assert_true(characters.size() >= 25, "at least ten characters must be added")
	t.assert_true(weapons.size() >= 28, "at least twelve weapons must be added")
	t.assert_true(passives.size() >= 31, "at least fifteen passives must be added")
	t.assert_true(evolutions.size() >= 22, "at least eight evolutions must be added")
	for id in ["corridor_knight", "cave_mapper", "relic_hunter", "shrine_guardian", "tunnel_runner", "crystal_witch", "forge_master", "storm_pilgrim", "blast_miner", "oasis_saint", "void_cartographer", "abyss_merchant"]:
		t.assert_true(character_unlocks.has(id), "added character must have unlock condition: %s" % id)
	for id in ["corridor_blade", "wall_bounce_blaster", "drill_charge", "mine_lantern", "relic_chain", "shrine_beam", "thorn_seed", "frost_wall", "coin_orbit", "echo_bell", "void_mirror", "magma_core", "compass_star", "guardian_wall", "gravity_anchor"]:
		t.assert_true(weapon_unlocks.has(id) and not bool(weapon_unlocks[id].get("initial", false)), "added weapon must be locked: %s" % id)
	for id in ["corridor_sense", "room_mastery", "wall_breaker", "route_memory", "treasure_instinct", "event_focus", "relic_resist", "boss_pressure", "choke_point", "open_field", "mining_luck", "map_reader", "hunter_mark", "chain_reward", "emergency_route"]:
		t.assert_true(passive_unlocks.has(id) and not bool(passive_unlocks[id].get("initial", false)), "added passive must be locked: %s" % id)

func _json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.open(path, FileAccess.READ).get_as_text())
	return parsed if parsed is Dictionary else {}
