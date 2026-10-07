extends RefCounted
class_name OverclockSystem
func candidates(state: RunState,db: GameDatabase) -> Array:
 var result: Array=[]
 for weapon in state.progression.evolutions:
  if state.progression.banished.has(weapon): continue
  if int(state.progression.overclocks.get(weapon,0))>=2: continue
  for variant in db.table("overclocks").get(state.progression.evolutions[weapon],[]):
   if not state.progression.named_overclocks.get(weapon,[]).has(variant.id): result.append(["overclock",weapon,variant.id])
 return result
func apply(choice: Array,state: RunState,db: GameDatabase) -> bool:
 if choice.size()<3 or not candidates(state,db).has(choice): return false
 var owned: Array=state.progression.named_overclocks.get(choice[1],[])
 owned.append(choice[2])
 state.progression.named_overclocks[choice[1]]=owned
 state.progression.overclocks[choice[1]]=int(state.progression.overclocks.get(choice[1],0))+1
 return true
func runtime(weapon: String,state: RunState,db: GameDatabase) -> Dictionary:
 var d: Dictionary=db.table("v3_weapons")[weapon].duplicate(true)
 for id in state.progression.named_overclocks.get(weapon,[]):
  var variant: Dictionary=db.table("v3_overclocks").get(id,{})
  for key in variant.get("modifiers",{}): d.modifiers[key]=variant.modifiers[key]
 return d
func factors(weapon: String,state: RunState,db: GameDatabase) -> Dictionary:
 var result: Dictionary={"damage":1.0,"area":1.0,"cooldown":1.0,"targets":0}
 for id in state.progression.named_overclocks.get(weapon,[]):
  var d: Dictionary=db.table("v3_overclocks").get(id,{})
  for key in ["damage","area","cooldown"]: result[key]*=float(d.get(key,1))
  result.targets+=int(d.get("targets",0))
 return result
func definition(choice: Array,db: GameDatabase) -> Dictionary:
 return db.table("v3_overclocks").get(choice[2],{}) if choice.size()>2 else db.table("weapons")[choice[1]]
