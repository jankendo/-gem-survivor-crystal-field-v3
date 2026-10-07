extends RefCounted
class_name SaveRepository
const PATH := "user://gem_survivor_crystal_field_v3.save"
const LEGACY := "user://chrono_merge_tactics.save"
var path := PATH
var data: Dictionary = {}
var dirty := false
var elapsed := 0.0
var writes := 0
var last_error := OK
var load_status := "new"
var blocked_load := false
var purchase_busy := false
var migration := SaveMigration.new()
func _init(target: String = PATH, legacy: String = LEGACY,legacy_directory: String = "") -> void:
 path = target
 var corrupt_current := false
 for candidate in [path,path + ".bak",path + ".tmp"]:
  if not FileAccess.file_exists(candidate): continue
  var value = parse_file(candidate)
  if migration.valid(value):
   data = migration.normalize(value)
   dirty = candidate != path
   load_status = "recovered" if dirty else "loaded"
   break
  if candidate == path: corrupt_current = true
 if data.is_empty():
  data = migration.defaults()
  if corrupt_current:
   blocked_load = true
   load_status = "corrupt"
   last_error = ERR_FILE_CORRUPT
   return
  var candidates: Array[String]=[legacy]
  if not legacy_directory.is_empty(): candidates.append(legacy_directory.path_join("chrono_merge_tactics.save"))
  elif path==PATH and legacy==LEGACY and not OS.has_feature("mobile"):
   candidates.append(OS.get_user_data_dir().get_base_dir().path_join("Gem Survivor Crystal Field/chrono_merge_tactics.save"))
  for candidate in candidates:
   if not FileAccess.file_exists(candidate): continue
   var old = parse_file(candidate)
   if old is Dictionary:
    var imported := migration.migrate(old)
    if migration.valid(imported):
     data = migration.normalize(imported)
     dirty = true
     load_status = "imported"
     break
   last_error=ERR_PARSE_ERROR
   load_status = "import_error"
func mark_dirty() -> void:
 dirty = true
 elapsed = 0
func tick(delta: float) -> void:
 if not dirty: return
 elapsed += delta
 if elapsed >= 1.0:
  elapsed = 0
  flush()
func flush() -> bool:
 if blocked_load:
  last_error = ERR_FILE_CORRUPT
  return false
 if not dirty:
  last_error=OK
  return true
 if not migration.valid(data):
  last_error = ERR_INVALID_DATA
  return false
 var temp := path + ".tmp"
 var file := FileAccess.open(temp,FileAccess.WRITE)
 if file == null:
  last_error = FileAccess.get_open_error()
  return false
 file.store_string(JSON.stringify(data))
 file.flush()
 file.close()
 if not migration.valid(parse_file(temp)):
  last_error = ERR_INVALID_DATA
  return false
 var absolute := ProjectSettings.globalize_path(path)
 if FileAccess.file_exists(path):
  var previous = parse_file(path)
  var backup:=absolute+".bak" if migration.valid(previous) else absolute+".corrupt"
  if not migration.valid(previous) and FileAccess.file_exists(backup): backup+="."+str(Time.get_unix_time_from_system())
  last_error = DirAccess.copy_absolute(absolute,backup)
  if last_error != OK: return false
 last_error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),absolute)
 if last_error != OK: return false
 last_error = OK
 dirty = false
 writes += 1
 return true
func settle(run: RunController) -> void:
 if run.state.settled: return
 run.state.settled = true
 var p := run.state.progression
 var reward_mult := (1+float(run.state.player.stats.get("currency",0)))*float(run.state.player.stats.get("contract_currency",1))
 if run.state.player.hp <= 0: reward_mult += float(run.state.player.stats.get("death_reward",0))
 run.state.settlement_reward = roundi(p.currency*reward_mult)
 data.profile.currency += run.state.settlement_reward
 data.profile["total_kills"] = int(data.profile.get("total_kills",0))+p.kills
 data.profile["total_crystals"] = int(data.profile.get("total_crystals",0))+run.field.crystals
 data.profile["total_rooms"] = int(data.profile.get("total_rooms",0))+p.rooms.size()
 data.profile.runs += 1
 data.profile.best_kills = maxi(data.profile.best_kills,p.kills)
 for id in p.weapons: data.progression.collection[id] = true
 data.progression.mastery[run.state.player.character] = int(data.progression.mastery.get(run.state.player.character,0)) + p.kills
 QuestSystem.new().settle(run,data)
 mark_dirty()
 flush()
func buy_item(kind: String,id: String, db: GameDatabase) -> bool:
 if purchase_busy or blocked_load: return false
 var shop := ShopSystem.new()
 if not shop.available(kind,id,data,db): return false
 var cost := shop.cost(kind,id,db)
 if cost < 0 or data.progression.unlocked.has(id) or int(data.profile.currency) < cost: return false
 var before := data.duplicate(true)
 var was_dirty := dirty
 purchase_busy = true
 data.profile.currency -= cost
 data.progression.unlocked.append(id)
 mark_dirty()
 return finish_purchase(before,was_dirty)

func parse_file(filename: String):
 var parser := JSON.new()
 if parser.parse(FileAccess.get_file_as_string(filename)) != OK: return null
 return parser.data

func buy_meta(id: String, definition: Dictionary) -> bool:
 if purchase_busy or blocked_load: return false
 if not data.progression.has("meta"): data.progression.meta = {}
 var level := int(data.progression.meta.get(id,0))
 if level >= int(definition.max_level): return false
 var cost := int(definition.base_cost)+int(definition.cost_step)*level
 if int(data.profile.currency) < cost: return false
 var before := data.duplicate(true)
 var was_dirty := dirty
 purchase_busy = true
 data.profile.currency -= cost
 data.progression.meta[id] = level+1
 mark_dirty()
 return finish_purchase(before,was_dirty)

func finish_purchase(before: Dictionary, was_dirty: bool) -> bool:
 var success := flush()
 if not success:
  data = before
  dirty = was_dirty
  if FileAccess.file_exists(path+".tmp"): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+".tmp"))
 purchase_busy = false
 return success

func recover_blocked() -> bool:
 if not blocked_load: return flush()
 for candidate in [path,path+".bak",path+".tmp"]:
  if not FileAccess.file_exists(candidate): continue
  var value=parse_file(candidate)
  if not migration.valid(value): continue
  data=migration.normalize(value)
  blocked_load=false
  load_status="recovered"
  dirty=candidate!=path
  if flush(): return true
  return false
 last_error=ERR_FILE_CORRUPT
 return false
