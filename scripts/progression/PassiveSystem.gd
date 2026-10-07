extends RefCounted
class_name PassiveSystem
func resolve(state: RunState, db: GameDatabase) -> Dictionary:
 var result: Dictionary = {}
 for key in ["meta_damage","meta_magnet"]:
  if state.player.stats.has(key): result[key] = state.player.stats[key]
 for id in state.progression.passives:
  for stat in db.table("v3_passives").get(id, {}): result[stat] = float(result.get(stat,0)) + float(db.table("v3_passives")[id][stat]) * int(state.progression.passives[id])
 return result
