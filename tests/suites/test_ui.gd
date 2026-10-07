extends RefCounted
func tags() -> Array: return ["smoke","UI","iOS","release"]
func run(t: TestContext, tree: SceneTree) -> void:
 tree.root.size = Vector2i(1280,720)
 tree.root.content_scale_size = Vector2i(1280,720)
 var app = load("res://scenes/Main.tscn").instantiate()
 app.save_path = "user://qa_ui_suite.save"
 tree.root.add_child(app)
 await tree.process_frame
 t.check(app.db.errors.is_empty(),"main database")
 t.equal(app.controller.current,"TitleScreen","main scene launches")
 app.controller.show_character()
 app.start_run("noah")
 app.set_physics_process(false)
 t.equal(app.controller.current,"HUD","gameplay starts")
 app.run.state.progression.choices = [["weapons","magic_bolt"]]
 app.run.state.phase = "LEVEL_UP"
 app.controller.sync_phase()
 t.equal(app.controller.current,"LevelUpPanel","level modal")
 app.controller.choose(0)
 t.equal(app.run.state.progression.weapons.magic_bolt,2,"choice applied")
 app.controller.pause_toggle()
 t.equal(app.run.state.phase,"PAUSED","pause")
 var nodes_before: int = app.get_child_count()
 app.controller.toggle_profile()
 t.equal(app.get_child_count(),nodes_before,"profile does not rebuild UI")
 t.equal(app.world_container.stretch_shrink,2 if app.saves.data.settings.profile == "ios_ultra" else 1,"world-only shrink")
 app.controller.pause_toggle()
 app.run.state.phase = "CLEAR"
 app.controller.sync_phase()
 t.equal(app.controller.current,"RewardPanel","clear choice")
 app.run.continue_endless()
 t.check(app.run.state.endless and app.run.state.phase == "RUNNING","endless continuation")
 app.controller.end_run()
 t.equal(app.controller.current,"ResultScreen","result flow")
 var area := SafeArea.new()
 var rect := area.logical_rect(Vector2(1280,720),Vector2(2560,1440),Rect2i(80,0,2400,1440))
 t.check(rect.position.x >= 40 and rect.end.x <= 1240,"notch safe area")
 for name in app.controller.panels:
  var panel: Control = app.controller.panels[name]
  for node in app.controller.view.controls[name].values():
   if node is Button: t.check(node.custom_minimum_size.y >= 44,"44pt control "+name+"/"+node.name)
 app.start_run("noah")
 var touch := InputEventScreenTouch.new()
 touch.index = 0
 touch.position = Vector2(150,220)
 touch.pressed = true
 app.touch._input(touch)
 var drag := InputEventScreenDrag.new()
 drag.index = 0
 drag.position = Vector2(215,220)
 app.touch._input(drag)
 t.check(app.touch.direction.x > .9,"dynamic touch joystick")
 touch.pressed = false
 app.touch._input(touch)
 t.equal(app.touch.direction,Vector2.ZERO,"touch release resets movement")
 touch.position = Vector2.ZERO
 touch.pressed = true
 app.touch._input(touch)
 t.equal(app.touch.finger,-1,"safe area rejects outside touch")
 var standard: int = app.run.signature()
 app.controller.toggle_profile()
 t.equal(app.run.signature(),standard,"Ultra settings cannot mutate simulation")
 app.saves.data.settings.profile = "desktop_standard"
 app.saves.mark_dirty()
 app.saves.flush()
 app.queue_free()
 await tree.process_frame
