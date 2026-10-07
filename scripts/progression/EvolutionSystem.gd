extends RefCounted
class_name EvolutionSystem
func refresh(state: RunState, db: GameDatabase) -> void:
 var p := state.progression
 for id in db.table("evolutions"):
  var d: Dictionary = db.table("evolutions")[id]
  if int(p.weapons.get(d.weapon, 0)) >= int(d.weapon_level) and int(p.passives.get(d.passive, 0)) >= int(d.passive_level) and state.field_tick >= 18000:
   p.evolutions[d.weapon] = id
 var c: Dictionary = db.table("character_evolutions").get(state.player.character, {})
 if not c.is_empty() and not state.player.evolved and p.level >= int(c.required_level) and state.field_tick >= int(float(c.required_seconds) * 60):
  var condition: Dictionary = c.get("unique_condition", {})
  var value := 0
  match str(condition.get("type", "")):
   "kills": value = p.kills
   "gems_collected": value = p.gems
   "rooms_discovered": value = p.rooms.size()
   "boss_defeats": value = p.bosses
  if value >= int(condition.get("value", 0)):
   state.player.evolved = true
   state.player.max_hp += 12
   state.player.hp = minf(state.player.hp + 12, state.player.max_hp)
