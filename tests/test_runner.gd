extends SceneTree
func _initialize() -> void:
 call_deferred("run_all")
func run_all() -> void:
 var ctx := TestContext.new()
 var category := "all"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--category="): category = arg.get_slice("=",1)
 var suites := 0
 for file in DirAccess.get_files_at("res://tests/suites"):
  if not file.ends_with(".gd"): continue
  var script: GDScript = load("res://tests/suites/"+file)
  if script==null or not script.can_instantiate():
   ctx.check(false,"suite parser "+file)
   continue
  var suite = script.new()
  if category != "all" and not suite.tags().has(category): continue
  var before := ctx.assertions
  await suite.run(ctx,self)
  suites += 1
  print(file," assertions=",ctx.assertions-before)
 var report := {"suites":suites,"assertions":ctx.assertions,"failures":ctx.failures,"ok":ctx.failures.is_empty(),"godot":Engine.get_version_info().string}
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
 FileAccess.open("res://test-output/tests-"+category+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print(JSON.stringify(report))
 quit(0 if report.ok and suites > 0 else 1)
