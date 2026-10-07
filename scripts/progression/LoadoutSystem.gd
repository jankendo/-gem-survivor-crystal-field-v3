extends RefCounted
class_name LoadoutSystem
const CAP := 6
func candidates(state: RunState, db: GameDatabase, unlocked: Array) -> Array:
 var result: Array = []
 for kind in ["weapons", "passives"]:
  var owned: Dictionary = state.progression.weapons if kind == "weapons" else state.progression.passives
  for id in db.table(kind):
   if state.progression.banished.has(id): continue
   if not unlocked.has(id) and not owned.has(id): continue
   if not owned.has(id) and owned.size() >= CAP: continue
   if int(owned.get(id, 0)) < int(db.table(kind)[id].max_level): result.append([kind,id])
 return result
func apply(choice: Array, state: RunState, db: GameDatabase) -> bool:
 var owned: Dictionary = state.progression.weapons if choice[0] == "weapons" else state.progression.passives
 var id: String = choice[1]
 if not db.table(choice[0]).has(id): return false
 if not owned.has(id) and owned.size() >= CAP: return false
 if int(owned.get(id,0)) >= int(db.table(choice[0])[id].max_level): return false
 owned[id] = int(owned.get(id,0)) + 1
 if id == "max_hp":
  state.player.max_hp += float(db.table("v3_passives").max_hp.max_hp)
  state.player.hp += float(db.table("v3_passives").max_hp.max_hp)
 return true
