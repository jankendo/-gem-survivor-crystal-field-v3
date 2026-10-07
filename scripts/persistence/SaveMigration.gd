extends RefCounted
class_name SaveMigration
func defaults() -> Dictionary:
 return {"schema_version":3,"profile":{"currency":0,"runs":0,"best_kills":0},"progression":{"unlocked":["noah","magic_bolt","might","magnet","cooldown","move_speed","area","regen"],"quests":{},"collection":{},"mastery":{}},"settings":{"profile":"desktop_standard","render_fps":60,"fullscreen":false},"migration":{}}
func migrate(old: Dictionary) -> Dictionary:
 var value := defaults()
 value.profile.currency = int(old.get("crystal_currency",old.get("currency",0)))
 for k in ["profile","progression","settings"]:
  if old.get(k) is Dictionary: value[k].merge(old[k],true)
 for k in ["unlocked_characters","unlocked_weapons","unlocked_passives"]:
  var entries = old.get(k,[])
  if entries is Dictionary: entries = entries.keys()
  if entries is Array:
   for id in entries:
    if not value.progression.unlocked.has(id): value.progression.unlocked.append(id)
 value.migration = {"legacy_imported":true,"original_preserved":true}
 return value
func valid(value) -> bool:
 return value is Dictionary and value.get("schema_version") == 3 and value.get("profile") is Dictionary and value.get("progression") is Dictionary and value.get("settings") is Dictionary and value.progression.get("unlocked") is Array
