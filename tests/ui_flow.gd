extends SceneTree
func _initialize() -> void: call_deferred("play")
func play() -> void:
 var app=load("res://scenes/Main.tscn").instantiate()
 app.save_path="user://qa_full_ui_flow.save"
 for p in [app.save_path,app.save_path+".bak",app.save_path+".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
 root.add_child(app)
 app.set_physics_process(false); app.set_process(false)
 var ui: UIController=app.controller
 var timeline: Array=[]
 timeline.append("Boot → Title")
 ui.show_shop(); ui.back(); ui.open_menu("SettingsScreen"); ui.back(); ui.show_collection(); ui.back()
 timeline.append("Title → Shop → Back → Settings → Back → Collection → Back")
 app.saves.data.progression.unlocked=["noah","attack","magic_bolt","thunder_chain","bomb_seed","laser_lance","might","cooldown","area","regen","armor","elite_hunter"]
 ui.show_character(); ui.show_setup(); ui.view.node("RunSetup","Seed").text="60606"; ui.start_selected()
 timeline.append("Character → Setup → Gameplay")
 var driver:=AutoplayDriver.new()
 var r: RunController=app.run
 var entered:=false
 var exited:=false
 var levels:=0
 var contracts:=0
 var started:=Time.get_ticks_usec()
 while r.state.tick<80000 and r.state.phase not in ["CLEAR","RESULT"]:
  ui.sync_phase()
  if r.state.phase=="LEVEL_UP":
   ui.choose(driver.choice(r)); levels+=1
   continue
  if r.state.phase=="CONTRACT": ui.resolve_contract(false); contracts+=1; continue
  var direction:=driver.direction(r)
  if not entered and r.state.field_tick>=37000:
   var destination: Vector2=r.map.portals[0]
   if destination.distance_to(r.state.player.position)<100:
    ui.enter_warp(); ui.accept_warp(); entered=r.warp.active
    timeline.append({"warp_entry_tick":r.state.tick,"HP":r.state.player.hp,"phase":r.state.phase,"wave":r.warp.wave_index})
   else: direction=(r.map.pursuit_target(r.state.player.position,destination)-r.state.player.position).normalized()
  if r.state.tick%120==0: ui.interact()
  r.pipeline.tick(r,direction)
  if entered and not r.warp.active and not exited:
   exited=true; timeline.append({"warp_return_tick":r.state.tick,"HP":r.state.player.hp})
  if r.state.tick%600==0:
   ui.update_hud()
   await process_frame
 ui.sync_phase()
 var clear: bool=r.state.phase=="CLEAR"
 if clear:
  timeline.append({"CLEAR_tick":r.state.tick,"field_seconds":r.state.field_tick/60.0,"HP":r.state.player.hp,"bosses":r.state.progression.bosses})
  ui.continue_endless()
  for i in range(60): r.pipeline.tick(r,driver.direction(r))
  timeline.append("CLEAR → Continue Endless → Finish")
 ui.end_run()
 var result: bool=ui.current=="ResultScreen" and r.state.settled
 ui.home()
 var title: bool=ui.current=="TitleScreen" and app.run==null
 var report: Dictionary={"ok":clear and entered and exited and result and title,"seed":60606,"normal_hp":true,"normal_population":true,"levels_selected_through_UI":levels,"contracts_resolved_through_UI":contracts,"clear":clear,"warp_entered":entered,"warp_completed_or_timeout":exited,"result":result,"title_return":title,"timeline":timeline,"wall_seconds":(Time.get_ticks_usec()-started)/1e6,"note":"Accelerated fixed-tick gameplay via shared QA input agent and real UI commands. Not human playtest; no HP/spawn/phase overrides."}
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
 FileAccess.open("res://test-output/ui-flow.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print(JSON.stringify(report))
 app.queue_free()
 for i in range(4): await process_frame
 quit(0 if report.ok else 1)
