extends RefCounted
class_name DataValidator
func validate(db: GameDatabase) -> Array[String]:
 var errors: Array[String] = []
 for id in db.table("evolutions"):
  var d: Dictionary = db.table("evolutions")[id]
  if not db.table("weapons").has(d.weapon): errors.append("evolution weapon " + id)
  if not db.table("passives").has(d.passive): errors.append("evolution passive " + id)
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
 for name in ["weapons", "passives", "characters", "enemies", "bosses", "evolutions", "character_evolutions"]:
  for id in db.table(name):
   var d: Dictionary = db.table(name)[id]
   for key in d:
    if key in ["generated_icon", "generated_sprite", "evolved_sprite"] and not ResourceLoader.exists(d[key]): errors.append("asset " + str(d[key]))
 return errors
