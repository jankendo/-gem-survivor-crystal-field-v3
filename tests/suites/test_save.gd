extends RefCounted
func tags() -> Array: return ["unit","gameplay","release"]
func run(t: TestContext, _tree: SceneTree) -> void:
 var path := "user://test-v3.save"
 var legacy := "user://test-v2.save"
 for p in [path,path+".bak",path+".tmp",legacy]: DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
 var old := {"crystal_currency":123,"unlocked_weapons":["thunder_chain"],"unlocked_characters":["mio"],"settings":{"render_fps":30}}
 var raw := JSON.stringify(old)
 FileAccess.open(legacy,FileAccess.WRITE).store_string(raw)
 var save := SaveRepository.new(path,legacy)
 t.equal(save.data.schema_version,3,"schema 3")
 t.equal(save.data.profile.currency,123,"legacy currency")
 t.check(save.data.progression.unlocked.has("mio"),"legacy character")
 t.check(save.flush(),"atomic imported write")
 t.equal(FileAccess.get_file_as_string(legacy),raw,"legacy file preserved")
 save.data.profile.currency = 456
 save.mark_dirty()
 t.check(save.flush(),"replace existing file")
 t.check(FileAccess.file_exists(path+".bak"),"backup exists")
 FileAccess.open(path,FileAccess.WRITE).store_string("broken")
 var recovery := SaveRepository.new(path,legacy)
 t.equal(recovery.data.profile.currency,123,"backup recovery")
 t.check(recovery.flush(),"recovered atomic write")
 var writes := recovery.writes
 recovery.tick(.1)
 t.equal(recovery.writes,writes,"clean cache never writes")
 recovery.data.profile.currency = 789
 recovery.mark_dirty()
 recovery.tick(.5)
 t.equal(recovery.writes,writes,"debounce")
 recovery.tick(.5)
 t.equal(recovery.writes,writes+1,"debounced save writes")
 var db := GameDatabase.new()
 recovery.data.profile.currency=10000
 recovery.data.profile.metrics={}
 t.check(not recovery.buy_item("weapons","laser_lance",db),"repository rejects unmet purchase prerequisite")
 t.equal(recovery.data.profile.currency,10000,"rejected purchase leaves currency")
 recovery.data.profile.metrics={"total_crystals":20}
 var price:=ShopSystem.new().cost("weapons","laser_lance",db)
 t.check(recovery.buy_item("weapons","laser_lance",db),"eligible purchase persists")
 t.equal(recovery.data.profile.currency,10000-price,"source license cost charged")
 t.check(not recovery.buy_item("weapons","laser_lance",db),"duplicate purchase rejected")
 t.equal(SaveRepository.new(path,legacy).data.profile.currency,10000-price,"purchase survives reload")
 for p in [path,path+".bak",path+".tmp",legacy]: DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
 var directory: String=ProjectSettings.globalize_path("user://test-v2-profile")
 DirAccess.make_dir_recursive_absolute(directory)
 var sibling:=directory.path_join("chrono_merge_tactics.save")
 FileAccess.open(sibling,FileAccess.WRITE).store_string(raw)
 var imported:=SaveRepository.new(path,"user://missing-legacy.save",directory)
 t.equal(imported.data.profile.currency,123,"legacy import finds old desktop profile directory")
 t.check(imported.flush(),"sibling legacy imports to new schema")
 t.equal(FileAccess.get_file_as_string(sibling),raw,"old desktop file stays byte-for-byte intact")
 for p in [path,path+".bak",path+".tmp",sibling]: DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
 DirAccess.remove_absolute(directory)
