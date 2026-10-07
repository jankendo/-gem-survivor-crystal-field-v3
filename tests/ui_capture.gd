extends SceneTree
var app
var capture_size:=Vector2i(844,390)
var report: Array=[]
var capture_ok:=true
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--size="):
   var pair:=arg.get_slice("=",1).split("x")
   capture_size=Vector2i(int(pair[0]),int(pair[1]))
 root.size=capture_size
 root.position=Vector2i.ZERO
 app=load("res://scenes/Main.tscn").instantiate()
 app.save_path="user://qa_visual_capture.save"
 for p in [app.save_path,app.save_path+".bak",app.save_path+".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
 root.add_child(app)
 app.set_physics_process(false)
 if capture_size.y<500: app.safe_override=Rect2(Vector2(44,0),Vector2(capture_size.x-88,capture_size.y-21))
 app.resize_ui()
 await shot("title")
 app.controller.show_character()
 await shot("character")
 app.controller.open_menu("BlessingSelect"); app.controller.menu.blessing()
 await shot("blessing")
 app.controller.back(); app.controller.show_setup()
 await shot("run-setup")
 app.controller.show_shop()
 app.controller.shop_index=app.controller.shop_ids.find(["weapons","laser_lance"])
 app.controller.update_shop()
 await shot("shop")
 app.controller.open_menu("SettingsScreen")
 await shot("settings")
 app.controller.show_collection()
 await shot("collection")
 app.controller.view.node("CollectionScreen","Search").text="魔弾"
 await shot("collection-search")
 app.controller.collection.open_detail(0)
 await shot("collection-detail")
 app.controller.back()
 app.controller.view.node("CollectionScreen","Search").text="存在しない検索結果"
 await shot("collection-empty")
 app.controller.collection.clear(); app.controller.collection.quests()
 await shot("quest-progress")
 app.keyboard_points_override=220;app.sync_keyboard_area()
 await shot("collection-keyboard")
 app.keyboard_points_override=0;app.sync_keyboard_area()
 app.saves.data.settings.ui_scale=1.25;app.apply_profile()
 await shot("collection-125")
 app.saves.data.settings.ui_scale=1.0;app.apply_profile()

 app.start_run("noah","attack",60606)
 await shot("gameplay-early")
 var r: RunController=app.run
 for id in app.db.table("weapons").keys().slice(0,6): r.state.progression.weapons[id]=8
 for id in app.db.table("passives").keys().slice(0,6): r.state.progression.passives[id]=5
 r.weapons.refresh(r.state,r.db)
 r.combos.refresh(r.state,r.db)
 for i in range(600):
  var position:=r.map.safe_position(Vector2(300,0).rotated(i*2.4)*(1+float(i%11)/10))
  r.enemies.spawn(i%r.db.enemy_defs.size(),position,r.db.enemy_defs[i%r.db.enemy_defs.size()])
  if i==99: await shot("combat-100")
  if i==299: await shot("combat-300")
 for i in range(500): r.projectiles.add(Vector2(60,0).rotated(i)*float(1+i%5),Vector2.RIGHT.rotated(i)*100,5,"weapon:magic_bolt",1,1)
 for i in range(1000): r.gems.add(r.map.safe_position(Vector2(100+i%500,0).rotated(i*2.4)),1,r.map)
 for i in range(90): r.damage.presentation.emit(Vector2(20+i%60,0).rotated(i*2.4),1)
 app.renderer.effects.submitted_tick=-1
 app.renderer.effects.present(r.damage.presentation,r.state.tick,false)
 app.renderer.effects.set_process(false) # Freeze only cosmetic decay for reproducible fixture.
 await shot("gameplay-dense")
 var signature: int=r.signature()
 app.set_temporary_profile("ios_ultra")
 await shot("gameplay-dense-ultra")
 assert(r.signature()==signature,"render quality cannot mutate simulation")
 app.set_temporary_profile("")
 app.controller.show_equipment()
 await shot("equipment")
 app.controller.progression.slot(0)
 await shot("equipment-detail")
 app.controller.back()
 app.controller.back()
 app.controller.pause_toggle()
 await shot("pause")
 app.controller.confirm("ランを終了し、報酬を保存してリザルトへ進みます。",app.controller.end_run)
 await shot("confirmation")
 app.controller.back()
 app.controller.pause_toggle()
 r.state.progression.weapons["magic_bolt"]=2
 r.state.progression.weapons["ice_orbit"]=2
 r.state.progression.passives["might"]=2
 r.state.progression.choices=[["weapons","magic_bolt"],["passives","might"],["weapons","ice_orbit"]]
 r.state.phase="LEVEL_UP"
 app.controller.sync_phase()
 await shot("level-up")
 app.controller.choose(0)
 r.pending_contract=app.db.table("rune_contracts").keys()[0]
 r.state.phase="CONTRACT"; app.controller.sync_phase()
 await shot("contract")
 app.controller.resolve_contract(false)
 r.state.phase="RUNNING"
 app.controller.show_hud()
 r.enemies=EnemyWorld.new()
 r.state.player.position=r.map.portals[0]
 app.controller.enter_warp()
 await shot("warp-entry")
 app.controller.accept_warp()
 await shot("warp")
 r.warp.leave(r)
 r.enemies=EnemyWorld.new()
 var boss: Dictionary=app.db.table("bosses").values()[2]
 var id:=r.enemies.spawn(-3,r.state.player.position+Vector2(200,0),boss)
 var slot:=r.enemies.slot(id)
 r.enemies.flags[slot]|=1
 r.enemies.warning[slot]=60
 r.enemies.attack_target[slot]=r.state.player.position+Vector2(70,50)
 app.controller.update_hud()
 await shot("boss")
 r.state.player.hp=20
 app.controller.update_hud()
 await shot("boss-low-hp")
 r.enemies.warning[slot]=0
 await shot("boss-attack")
 r.state.boss_stage=3
 r.state.progression.bosses=3
 r.state.phase="CLEAR"
 app.controller.sync_phase()
 await shot("clear")
 app.controller.continue_endless()
 r.state.player.hp=0
 r.state.last_damage_source="boss:telegraph"
 r.state.phase="RESULT"
 app.saves.settle(r)
 app.controller.sync_phase()
 await shot("result")
 app.controller.system_error("保存できませんでした。元データは保持しています。空き容量や保存先を確認して、再試行してください。購入が失敗した場合、貨と商品は変更されません。")
 await shot("save-error")
 app.controller.close_system()
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
 FileAccess.open("res://test-output/visual-"+str(capture_size.x)+"x"+str(capture_size.y)+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 app.queue_free()
 for i in range(4): await process_frame
 quit(0 if capture_ok else 1)
func shot(name: String) -> void:
 for i in range(4): await process_frame
 await RenderingServer.frame_post_draw
 var image:=root.get_texture().get_image()
 assert(image!=null and not image.is_empty(),"real rendered image required")
 var directory: String=ProjectSettings.globalize_path("res://docs/qa/evidence/ui-screenshots/"+str(capture_size.x)+"x"+str(capture_size.y))
 DirAccess.make_dir_recursive_absolute(directory)
 var path:=directory.path_join(name+".png")
 assert(image.save_png(path)==OK)
 var geometry: Array=[]
 for c in app.controller.view.controls[app.controller.current].values():
  if c.is_visible_in_tree(): geometry.append({"name":str(c.name),"rect":str(c.get_global_rect()),"minimum":str(c.get_combined_minimum_size())})
 var focus: Control=root.gui_get_focus_owner()
 if app.controller.current!="HUD" and focus!=null and not UILayoutInspector.new().visible_rect(focus).has_area(): capture_ok=false
 var errors:=UILayoutInspector.new().inspect(app,app.controller.current)
 if not errors.is_empty(): capture_ok=false
 print("LAYOUT ",name," errors=",errors)
 report.append({"errors":errors,"safe_rect":str(Rect2(app.ui.global_position,app.ui.size)),"geometry":geometry,"screen":name,"view":app.controller.current,"size":str(image.get_size()),"file":path.get_file(),"fixture":"scripted real renderer state fixture, not human/physical-device playtest"})
 print("CAPTURE ",name," ",image.get_size())
