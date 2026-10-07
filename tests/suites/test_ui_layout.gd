extends RefCounted
func tags() -> Array: return ["UI","iOS","release"]
func run(t: TestContext,tree: SceneTree) -> void:
 var app=load("res://scenes/Main.tscn").instantiate()
 app.save_path="user://qa_layout.save"
 tree.root.size=Vector2i(1280,720)
 tree.root.add_child(app)
 app.set_process(false); app.set_physics_process(false)
 await tree.process_frame
 app.start_run("noah","attack",60606)
 app.run.pause()
 var inspector:=UILayoutInspector.new()
 var resolutions: Array=[Vector2i(1280,720),Vector2i(1366,768),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(1280,800),Vector2i(1024,768),Vector2i(844,390),Vector2i(852,393),Vector2i(874,402),Vector2i(932,430),Vector2i(1024,768),Vector2i(1080,810),Vector2i(1180,820),Vector2i(1194,834),Vector2i(1366,1024)]
 var report: Array=[]
 var long_text: String="超長い日本語の装備名と説明、次の効果は120 → 145です。操作を確認してから選択してください。".repeat(25)
 for n in range(resolutions.size()):
  var size: Vector2i=resolutions[n]
  tree.root.size=size
  app.safe_override=Rect2(Vector2(44,0),Vector2(size.x-88,size.y-21)) if n in range(7,11) else Rect2(Vector2(0,20),Vector2(size.x,size.y-41)) if n>=11 else Rect2(Vector2.ZERO,Vector2(size))
  app.resize_ui()
  await tree.process_frame
  app.resize_ui()
  for name in app.controller.panels:
   app.controller.show_panel(name)
   app.controller.view.text(name,"Info",long_text)
   if name=="LevelUpPanel":
    app.run.state.progression.choices=[["weapons","magic_bolt"],["passives","might"],["weapons","ice_orbit"]]
    app.controller.progression.choices()
   if name=="EquipmentPanel": app.controller.progression.equipment()
   for settle in range(5): await tree.process_frame
   var errors:=inspector.inspect(app,name)
   t.check(errors.is_empty(),str(size)+" "+name+" "+str(errors))
   var focus: Control=tree.root.get_viewport().gui_get_focus_owner()
   t.check(focus==null or focus.is_visible_in_tree(),str(size)+" no hidden focus "+name)
   t.check(focus==null or inspector.visible_rect(focus).has_area(),str(size)+" focused control has visible hit area "+name)
   report.append({"resolution":str(size),"platform":"phone safe-area fixture" if n in range(7,11) else "tablet safe-area fixture" if n>=11 else "desktop fixture","screen":name,"errors":errors})
  app.run.state.phase="RUNNING"
  app.controller.show_hud()
  await tree.process_frame
  await tree.process_frame
  t.check(inspector.inspect(app,"HUD").is_empty(),str(size)+" HUD action geometry")
  app.run.pause()
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
 FileAccess.open("res://test-output/ui-layout-matrix.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 app.queue_free()
 await tree.process_frame
 tree.root.size=Vector2i(1280,720)
 tree.root.content_scale_size=Vector2i(1280,720)
