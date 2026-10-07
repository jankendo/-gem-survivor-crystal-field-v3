extends RefCounted
class_name DataValidator
func validate(db: GameDatabase,strict_assets: bool=false) -> Array[String]:
 var errors: Array[String] = []
 for required in ["characters","weapons","passives","enemies","bosses","v3_balance","v3_weapons","v3_passives","blessings","rune_contracts","warp_rooms","field_events","field_gimmicks"]:
  if db.table(required).is_empty(): errors.append("required table "+required)
 if not errors.is_empty(): return errors
 # Reject malformed entity definitions before typed fields/asset reads.
 for name in ["weapons","passives","characters","enemies","bosses","evolutions","character_evolutions","blessings","v3_weapons","v3_passives","rune_contracts","field_gimmicks"]:
  for id in db.table(name):
   if not db.table(name)[id] is Dictionary: errors.append("definition shape "+name+":"+str(id))
 for id in db.table("evolutions"):
  var d=db.table("evolutions")[id]
  if d is Dictionary and (not d.has("weapon") or not d.has("passive")): errors.append("evolution fields "+str(id))
 for combo in db.table("weapon_combo_attacks").get("combos",[]):
  if not combo is Dictionary or not combo.has_all(["id","weapon_a","weapon_b"]): errors.append("combo fields")
 for name in ["weapons","passives"]:
  for id in db.table(name):
   var d=db.table(name)[id]
   if d is Dictionary and (not d.has("max_level") or not d.max_level is float and not d.max_level is int or float(d.max_level)<1): errors.append("level range "+name+":"+str(id))
 for id in db.table("v3_weapons"):
  var d=db.table("v3_weapons")[id]
  if d is Dictionary and not d.has_all(["archetype","category","cooldown","damage","range","radius","targets","status","modifiers"]): errors.append("runtime fields "+str(id))
 if not db.table("field_events").get("events") is Array: errors.append("field event list")
 if not db.table("warp_rooms").get("types") is Dictionary or not db.table("warp_rooms").get("type_weights") is Dictionary: errors.append("warp shape")
 if not db.config().get("status") is Dictionary: errors.append("status configuration")
 if not errors.is_empty(): return errors
 for id in db.table("evolutions"):
  var d: Dictionary = db.table("evolutions")[id]
  if not db.table("weapons").has(d.weapon): errors.append("evolution weapon " + id)
  if not db.table("passives").has(d.passive): errors.append("evolution passive " + id)
 for id in db.table("characters"):
  if not db.table("v3_weapons").has(db.table("characters")[id].get("initial_weapon","")): errors.append("character starting weapon "+id)
 var seen: Dictionary = {}
 for d in db.table("weapon_combo_attacks").get("combos", []):
  if seen.has(d.id): errors.append("duplicate combo " + d.id)
  seen[d.id] = true
  for k in ["weapon_a", "weapon_b"]:
   if not db.table("weapons").has(d[k]): errors.append("combo reference " + d.id)
 for id in db.table("weapons"):
  if not db.table("v3_weapons").has(id): errors.append("missing runtime " + id)
  var d: Dictionary = db.table("v3_weapons").get(id, {})
  if float(d.get("cooldown", 0)) <= 0 or float(d.get("damage", -1)) < 0: errors.append("range " + id)
 for name in ["weapons", "passives", "characters", "enemies", "bosses", "evolutions", "character_evolutions","field_gimmicks"]:
  for id in db.table(name):
   var d: Dictionary = db.table(name)[id]
   for key in d:
    if key in ["generated_icon", "generated_sprite", "evolved_sprite"] and not ResourceLoader.exists(d[key]):
     var message: String="asset "+str(d[key])
     if key!="generated_icon" or strict_assets: errors.append(message)
     elif not db.warnings.has(message): db.warnings.append(message)
 for evolution in db.table("overclocks"):
  for variant in db.table("overclocks")[evolution]:
   if not db.table("v3_overclocks").has(variant.id): errors.append("missing overclock runtime "+str(variant.id))
 return errors
