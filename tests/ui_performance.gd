extends SceneTree
func _initialize() -> void: call_deferred("measure")
func nodes(node: Node) -> int:
 var count:=1
 for child in node.get_children(): count+=nodes(child)
 return count
func measure() -> void:
 root.size=Vector2i(1280,720)
 var app=load("res://scenes/Main.tscn").instantiate()
 if "save_path" in app: app.save_path="user://qa_ui_performance.save"
 root.add_child(app)
 app.set_process(false); app.set_physics_process(false)
 for i in range(5): await process_frame
 app.run=RunController.new(app.db,60606)
 var r: RunController=app.run
 for id in app.db.table("weapons").keys().slice(0,6): r.state.progression.weapons[id]=8
 for id in app.db.table("passives").keys().slice(0,6): r.state.progression.passives[id]=5
 r.weapons.refresh(r.state,r.db)
 for i in range(600): r.enemies.spawn(0,r.map.safe_position(Vector2(100+i%400,0).rotated(i*2.4)),{"hp":100000,"speed":0,"radius":18})
 for i in range(500): r.projectiles.add(Vector2.ZERO,Vector2.RIGHT,1,"weapon:magic_bolt",1,1)
 for i in range(1000): r.gems.add(r.map.safe_position(Vector2(80+i%500,0).rotated(i*2.4)),1,r.map)
 app.controller.show_hud()
 var total_nodes:=nodes(app)
 var saved_renderer=app.renderer
 var report: Array=[]
 for fps in [30,60]:
  var iterations: int=fps*30
  var ui_samples: Array=[]
  var combined: Array=[]
  for mode in ["UI_only","render_preparation_and_UI"]:
   app.renderer=null if mode=="UI_only" else saved_renderer
   for frame in range(iterations+fps):
    r.state.field_tick=roundi(frame*60.0/fps)
    r.state.tick=r.state.field_tick
    if frame%(fps/2)==0: r.state.player.hp=70+float(frame%29)
    var start:=Time.get_ticks_usec()
    if mode=="UI_only" and "dirty_ticks" in app:
     # Baseline scheduler is nested under renderer!=null; reproduce its exact
     # UI cadence while excluding renderer preparation, rather than skip HUD.
     app.saves.tick(1.0/fps)
     app.dirty_ticks+=1
     if app.dirty_ticks>=6: app.controller.update_hud(); app.dirty_ticks=0
    else: app._process(1.0/fps)
    var elapsed:=Time.get_ticks_usec()-start
    if frame>=fps:
     if mode=="UI_only": ui_samples.append(elapsed)
     else: combined.append(elapsed)
   var samples: Array=ui_samples if mode=="UI_only" else combined
   samples.sort()
   var sum:=0.0
   for value in samples: sum+=float(value)
   report.append({"render_fps":fps,"mode":mode,"mean_us":sum/samples.size(),"p95_us":samples[int(samples.size()*.95)],"p99_us":samples[int(samples.size()*.99)]})
 app.renderer=saved_renderer
 var stable:=nodes(app)==total_nodes
 var budget_ok:=true
 for row in report:
  if row.mode=="UI_only": budget_ok=budget_ok and float(row.mean_us)<1000 and float(row.p99_us)<2000
 var result: Dictionary={"ok":stable and budget_ok,"UI_CPU_budget_ms":1.0,"node_count":total_nodes,"stable_node_count":stable,"enemy_count":r.enemies.count,"projectile_count":r.projectiles.count,"gem_count":r.gems.count,"samples":report,"limitation":"Linux headless CPU-only: explicit process calls and real renderer preparation; no deferred Control sorting/GPU drawing, thermal or real-device measurements. Simulation is frozen to isolate UI process cost."}
 if "hud_presenter" in app.controller:
  result["critical_calls"]=app.controller.hud_presenter.critical_updates
  result["slow_calls"]=app.controller.hud_presenter.slow_updates
  result["formatted_HUD_changes"]=app.controller.hud_presenter.string_updates
  result["cadence_note"]="30 simulated seconds per FPS/mode plus1s warmup; critical<=30Hz, slow5Hz regardless render FPS. Counters include setup/warmup."
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
 FileAccess.open("res://test-output/ui-performance.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
 print(JSON.stringify(result))
 app.queue_free()
 for i in range(4): await process_frame
 quit(0 if stable and budget_ok else 1)
