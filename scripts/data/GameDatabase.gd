extends RefCounted
class_name GameDatabase
var tables: Dictionary = {}
var errors: Array[String] = []
var enemy_ids: Array = []
var enemy_defs: Array = []
func _init() -> void:
 for filename in DirAccess.get_files_at("res://data"):
  if not filename.ends_with(".json"): continue
  var value = JSON.parse_string(FileAccess.get_file_as_string("res://data/" + filename))
  if value == null:
   errors.append("Invalid JSON: " + filename)
  else: tables[filename.trim_suffix(".json")] = value
 for id in table("enemies"):
  enemy_ids.append(id)
  enemy_defs.append(table("enemies")[id])
 errors.append_array(DataValidator.new().validate(self))
func table(id: String) -> Dictionary: return tables.get(id, {})
func enemy_index(id: String) -> int: return enemy_ids.find(id)
func config() -> Dictionary: return table("v3_balance")
