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
  var value = JSON.parse_string(FileAccess.get_file_as_string(candidate))
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
 if not migration.valid(JSON.parse_string(FileAccess.get_file_as_string(temp))):
  last_error = ERR_INVALID_DATA
  return false
 var absolute := ProjectSettings.globalize_path(path)
 if FileAccess.file_exists(path):
  var previous = JSON.parse_string(FileAccess.get_file_as_string(path))
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
 data.profile.currency += p.currency
 data.profile.runs += 1
 data.profile.best_kills = maxi(data.profile.best_kills,p.kills)
 for id in p.weapons: data.progression.collection[id] = true
 data.progression.mastery[run.state.player.character] = int(data.progression.mastery.get(run.state.player.character,0)) + p.kills
 mark_dirty()
 flush()
func buy(id: String, cost: int) -> bool:
 if cost < 0 or data.progression.unlocked.has(id) or int(data.profile.currency) < cost: return false
 data.profile.currency -= cost
 data.progression.unlocked.append(id)
 mark_dirty()
 return flush()
