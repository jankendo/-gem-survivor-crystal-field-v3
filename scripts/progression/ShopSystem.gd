extends RefCounted
class_name ShopSystem
var conditions := ConditionSystem.new()
func condition(kind: String,id: String,db: GameDatabase) -> Dictionary:
 match kind:
  "characters": return db.table("character_unlocks").get(id,{})
  "blessings": return db.table(kind).get(id,{}).get("unlock",{})
  "weapons","passives":
   var d: Dictionary = db.table("weapon_unlocks" if kind=="weapons" else "passive_unlocks").get(id,{})
   return {"type":"initial"} if d.get("initial",false) else d.get("condition",{})
 return {}
func available(kind: String,id: String,save: Dictionary,db: GameDatabase) -> bool:
 if not db.table(kind).has(id) or save.progression.unlocked.has(id): return false
 return bool(save.progression.get("available",{}).get(id,false)) or conditions.met(save,condition(kind,id,db))
func cost(kind: String,id: String,db: GameDatabase) -> int:
 var singular: String = {"weapons":"weapon","passives":"passive","characters":"character","blessings":"blessing"}.get(kind,"")
 for sink in db.table("currency_sinks").values():
  if sink.get("target","")==id and str(sink.get("category","")).begins_with(singular): return int(sink.base_cost)
 if kind=="characters":
  var direct := int(db.table(kind)[id].get("unlock_cost",0))
  if direct>0: return direct
  var c := condition(kind,id,db)
  if c.get("type","")=="currency": return int(c.get("cost",c.get("value",0)))
 var cfg: Dictionary = db.table("shop_entitlements").default_costs.get(singular,{"base":600,"step":120})
 return int(cfg.base)+int(cfg.step)*maxi(0,db.table(kind).keys().find(id))
