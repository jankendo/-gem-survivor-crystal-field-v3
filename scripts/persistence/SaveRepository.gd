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
var migration := SaveMigration.new()
func _init(target: String = PATH, legacy: String = LEGACY) -> void:
 path = target
 for candidate in [path,path + ".bak",path + ".tmp"]:
  if not FileAccess.file_exists(candidate): continue
  var value = parse_file(candidate)
  if migration.valid(value):
   data = value
   dirty = candidate != path
   break
 if data.is_empty():
  data = migration.defaults()
  if FileAccess.file_exists(legacy):
   var old = JSON.parse_string(FileAccess.get_file_as_string(legacy))
   if old is Dictionary:
    data = migration.migrate(old)
    dirty = true
func mark_dirty() -> void:
 dirty = true
 elapsed = 0
func tick(delta: float) -> void:
 if not dirty: return
 elapsed += delta
 if elapsed >= 1.0: flush()
func flush() -> bool:
 if not dirty: return true
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
  if migration.valid(previous):
   last_error = DirAccess.copy_absolute(absolute,absolute + ".bak")
   if last_error != OK: return false
 last_error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temp),absolute)
 if last_error != OK: return false
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
func buy(id: String, cost: int) -> bool:
 if cost < 0 or data.progression.unlocked.has(id) or int(data.profile.currency) < cost: return false
 data.profile.currency -= cost
 data.progression.unlocked.append(id)
 mark_dirty()
 return flush()

func parse_file(filename: String):
 var parser := JSON.new()
 if parser.parse(FileAccess.get_file_as_string(filename)) != OK: return null
 return parser.data

func buy_meta(id: String, definition: Dictionary) -> bool:
 if not data.progression.has("meta"): data.progression.meta = {}
 var level := int(data.progression.meta.get(id,0))
 if level >= int(definition.max_level): return false
 var cost := int(definition.base_cost)+int(definition.cost_step)*level
 if int(data.profile.currency) < cost: return false
 data.profile.currency -= cost
 data.progression.meta[id] = level+1
 mark_dirty()
 return flush()
