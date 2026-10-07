extends RefCounted
class_name SaveMigration
func defaults() -> Dictionary:
 return {"schema_version":3,"profile":{"currency":0,"runs":0,"best_kills":0,"total_kills":0,"total_crystals":0,"total_rooms":0},"progression":{"unlocked":["attack","noah","magic_bolt","ice_orbit","thunder_chain","bomb_seed","blade_fan","might","magnet","cooldown","move_speed","area","regen"],"quests":{},"collection":{},"mastery":{},"meta":{}},"settings":{"profile":"desktop_standard","render_fps":60,"fullscreen":false,"ui_scale":1.0,"tutorial_seen":false},"migration":{}}
func migrate(old: Dictionary) -> Dictionary:
 var value := defaults()
 value.profile.currency = int(old.get("crystal_currency",old.get("currency",0)))
 for k in ["profile","progression","settings"]:
  if old.get(k) is Dictionary: value[k].merge(old[k],true)
 for k in ["unlocked_characters","unlocked_weapons","unlocked_passives","unlocked_blessings"]:
  var entries = old.get(k,[])
  if entries is Dictionary: entries = entries.keys()
  if entries is Array:
   for id in entries:
    if k in ["unlocked_weapons","unlocked_passives"] and not value.progression.unlocked.has(id):
     if not value.progression.has("available"): value.progression.available={}
     value.progression.available[id]=true
    elif not value.progression.unlocked.has(id): value.progression.unlocked.append(id)
 value.progression.meta = old.get("meta_upgrades",{}).duplicate(true) if old.get("meta_upgrades",{}) is Dictionary else {}
 value.profile.metrics=old.get("stats",{}).duplicate(true) if old.get("stats",{}) is Dictionary else {}
 var aliases := {"best_survival":"survive_seconds","survive_10_runs":"survive_runs","max_exploration_chain":"exploration_chain","max_rooms_in_run":"rooms_in_run","best_exploration_rank":"exploration_rank","shortcut_walls_broken":"shortcut_walls"}
 for source in aliases:
  if value.profile.metrics.has(source): value.profile.metrics[aliases[source]]=value.profile.metrics[source]
 for pair in [["weapon_highest_levels","weapon_levels"],["evolved_weapons","evolved_weapons"],["boss_defeats","bosses"],["secret_flags","secret_flags"]]: value.progression[pair[1]]=old.get(pair[0],{}).duplicate(true) if old.get(pair[0],{}) is Dictionary else {}
 value.profile.metrics.weapon_kills=old.get("weapon_kills",{}).duplicate(true) if old.get("weapon_kills",{}) is Dictionary else {}
 value["legacy_archive"] = old.duplicate(true)
 var purchases: Dictionary=old.get("shop_purchases",{}) if old.get("shop_purchases",{}) is Dictionary else {}
 for kind in purchases:
  if not purchases[kind] is Dictionary: continue
  for id in purchases[kind]:
   if purchases[kind][id] and not value.progression.unlocked.has(id): value.progression.unlocked.append(id)
 value.migration = {"legacy_imported":true,"original_preserved":true}
 return value
func valid(value) -> bool:
 if not (value is Dictionary and value.get("schema_version")==3 and value.get("profile") is Dictionary and value.get("progression") is Dictionary and value.get("settings") is Dictionary and value.progression.get("unlocked") is Array): return false
 for key in ["currency","runs"]:
  if not (value.profile.get(key) is int or value.profile.get(key) is float) or float(value.profile[key])<0: return false
 for key in ["quests","collection","mastery","meta"]:
  if value.progression.has(key) and not value.progression[key] is Dictionary: return false
 return true
func normalize(value: Dictionary) -> Dictionary:
 var result := defaults()
 for key in ["profile","progression","settings"]: result[key].merge(value[key],true)
 for key in value:
  if key not in ["profile","progression","settings"]: result[key]=value[key]
 var settings: Dictionary=result.settings
 if settings.get("profile") not in ["desktop_standard","ios_ultra"]: settings.profile="desktop_standard"
 if settings.get("render_fps") not in [30,60]: settings.render_fps=60
 if not settings.get("fullscreen") is bool: settings.fullscreen=false
 if not (settings.get("ui_scale") is float or settings.get("ui_scale") is int): settings.ui_scale=1.0
 settings.ui_scale=clampf(float(settings.ui_scale),1,1.25)
 if not settings.get("tutorial_seen") is bool: settings.tutorial_seen=false
 return result
