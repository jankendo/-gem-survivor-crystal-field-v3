extends RefCounted
func tags() -> Array: return ["UI","iOS","unit","release"]
func mouse(tree: SceneTree,control: Control) -> void:
 var event:=InputEventMouseButton.new()
 event.button_index=MOUSE_BUTTON_LEFT
 event.position=control.get_global_rect().get_center()
 event.global_position=event.position
 event.pressed=true
 Input.parse_input_event(event)
 await tree.process_frame
 event=event.duplicate()
 event.pressed=false
 Input.parse_input_event(event)
 await tree.process_frame
func key(tree: SceneTree,code: int,echo: bool=false) -> void:
 var event:=InputEventKey.new()
 event.keycode=code; event.physical_keycode=code; event.pressed=true; event.echo=echo
 Input.parse_input_event(event)
 await tree.process_frame
 event=event.duplicate(); event.pressed=false; event.echo=false
 Input.parse_input_event(event)
 await tree.process_frame
func run(t: TestContext,tree: SceneTree) -> void:
 tree.root.size=Vector2i(844,390)
 var app=load("res://scenes/Main.tscn").instantiate()
 app.save_path="user://qa_input.save"
 for path in [app.save_path,app.save_path+".bak",app.save_path+".tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
 tree.root.add_child(app)
 app.set_physics_process(false)
 app.safe_override=Rect2(44,0,756,369)
 app.resize_ui()
 for i in range(5): await tree.process_frame
 var ui: UIController=app.controller
 await mouse(tree,ui.view.node("TitleScreen","Start"))
 t.equal(ui.current,"CharacterSelect","native mouse title starts selection")
 await mouse(tree,ui.view.node("CharacterSelect","Start"))
 t.equal(ui.current,"CharacterSelect","cross-screen double tap cannot start setup")
 await tree.create_timer(.31).timeout
 ui.view.node("CharacterSelect","Start").grab_focus()
 await key(tree,KEY_ENTER)
 t.equal(ui.current,"RunSetup","native keyboard Enter starts setup")
 await key(tree,KEY_ENTER,true)
 t.equal(ui.current,"RunSetup","echo Enter cannot execute transition")
 await tree.create_timer(.31).timeout
 ui.view.node("RunSetup","Seed").text="60606"
 ui.view.node("RunSetup","Start").grab_focus()
 await key(tree,KEY_ENTER)
 t.equal(ui.current,"HUD","keyboard starts run")
 var touch:=InputEventScreenTouch.new()
 touch.position=ui.view.node("HUD","Equipment").get_global_rect().get_center()
 touch.index=0; touch.pressed=true
 app.touch._input(touch)
 t.equal(app.touch.finger,-1,"touch action area cannot claim movement")
 touch.position=Vector2(100,250)
 app.touch._input(touch)
 var drag:=InputEventScreenDrag.new()
 drag.index=0; drag.position=Vector2(-400,800)
 app.touch._input(drag)
 t.check(app.touch.direction.length()<=1 and app.touch.direction.length()>.9,"drag outside remains bounded")
 var other:=touch.duplicate(); other.index=1; other.position=Vector2(150,250)
 app.touch._input(other)
 t.equal(app.touch.finger,0,"second touch cannot steal joystick")
 other.pressed=false; app.touch._input(other)
 t.equal(app.touch.finger,0,"second release cannot cancel first finger")
 touch.canceled=true; touch.pressed=false; app.touch._input(touch)
 t.equal(app.touch.direction,Vector2.ZERO,"touch cancellation neutralizes joystick")
 await tree.create_timer(.31).timeout
 var pause_touch:=InputEventScreenTouch.new()
 pause_touch.index=2; pause_touch.position=ui.view.node("HUD","Pause").get_global_rect().get_center(); pause_touch.pressed=true
 Input.parse_input_event(pause_touch)
 await tree.process_frame
 pause_touch=pause_touch.duplicate(); pause_touch.pressed=false
 Input.parse_input_event(pause_touch)
 await tree.process_frame
 t.equal(ui.current,"PauseMenu","native touch GUI action pauses")
 var tick: int=app.run.state.tick
 await key(tree,KEY_ESCAPE,true)
 t.equal(ui.current,"PauseMenu","Escape echo cannot resume")
 t.equal(app.run.state.tick,tick,"paused input cannot advance simulation")
 ui.open_menu("SettingsScreen")
 await key(tree,KEY_ESCAPE)
 t.equal(ui.current,"PauseMenu","Escape settings returns to pause")
 ui.pause_toggle()
 ui.system_error("テスト用の保存失敗")
 app.run.state.phase="RESULT"
 ui.sync_phase()
 t.equal(ui.current,"SystemDialog","system dialog priority cannot be overridden by result")
 app.run.state.phase="PAUSED"
 app.run.paused_phase="RUNNING"
 ui.close_system()
 t.equal(ui.current,"HUD","system retry/close restores gameplay")
 t.equal(app.run.state.phase,"RUNNING","system close resumes suspended gameplay")
 t.check(ui.view.hud.is_visible_in_tree() and not ui.panels.SystemDialog.is_visible_in_tree() and app.touch.enabled,"system close actually restores HUD and touch, not only cached name")
 app.saves.last_error=ERR_CANT_CREATE; ui.poll_system()
 var focus_rebuilds: int=ui.view.focus_rebuilds
 ui.poll_system(); ui.poll_system()
 t.equal(ui.view.focus_rebuilds,focus_rebuilds,"unchanged save error cannot rebuild modal every second")
 app.saves.last_error=OK; ui.poll_system(); ui.close_system()
 app.saves.last_error=ERR_CANT_CREATE; ui.poll_system()
 t.equal(ui.current,"SystemDialog","later same-code save failure remains visible")
 app.saves.last_error=OK; ui.close_system()
 await tree.create_timer(.31).timeout
 await key(tree,KEY_ESCAPE)
 await key(tree,KEY_ESCAPE)
 t.equal(ui.current,"PauseMenu","double Escape cannot immediately resume")
 await tree.create_timer(.31).timeout
 await key(tree,KEY_P)
 t.equal(ui.current,"HUD","P resumes as well as pauses")
 await tree.create_timer(.31).timeout
 await key(tree,KEY_TAB)
 t.equal(ui.current,"EquipmentPanel","HUD Tab opens equipment before native focus traversal")
 await tree.create_timer(.31).timeout
 await key(tree,KEY_ESCAPE)
 t.equal(ui.current,"HUD","equipment Escape restores gameplay")
 app.run.state.progression.weapons.magic_bolt=8
 app.run.state.progression.choices=[["weapons","magic_bolt"]]
 app.run.state.phase="LEVEL_UP"; ui.sync_phase()
 ui.choose(0)
 t.equal(app.run.state.phase,"LEVEL_UP","max-level invalid reward cannot silently dismiss choice")
 t.equal(app.run.state.progression.weapons.magic_bolt,8,"invalid upgrade cannot exceed maximum")
 app.run.state.progression.weapons.magic_bolt=1
 ui.choose(0)
 t.check(app.saves.data.settings.tutorial_seen,"first progression marks guidance learned")
 t.check(not ui.view.node("LevelUpPanel","Choice0").accessibility_name.is_empty(),"textless growth button has screen-reader name")
 ui.pause_toggle(); ui.show_equipment()
 var nodes: int=app.get_child_count()
 var scale: float=app.saves.data.settings.ui_scale
 app.saves.data.settings.ui_scale=1.25; app.apply_profile()
 for i in range(5): await tree.process_frame
 t.check(UILayoutInspector.new().inspect(app,"EquipmentPanel").is_empty(),"125% text equipment safe area")
 t.equal(app.get_child_count(),nodes,"settings typography retains stable node tree")
 app.saves.data.settings.ui_scale=scale; app.apply_profile()
 ui.end_run(); ui.home()
 ui.show_shop()
 app.saves.data.profile.currency=10000
 ui.shop_index=ui.shop_ids.find(["meta_upgrades","base_hp"])
 ui.menu.shop()
 ui.gate=UIActionGate.new()
 var before: int=app.saves.data.profile.currency
 var definition: Dictionary=app.db.table("meta_upgrades").base_hp
 ui.dispatch("ShopScreen","Buy",ui.buy_next)
 ui.dispatch("ShopScreen","Buy",ui.buy_next)
 t.equal(app.saves.data.progression.meta.base_hp,1,"double purchase dispatch upgrades exactly once")
 t.equal(app.saves.data.profile.currency,before-int(definition.base_cost),"double purchase charged once")
 t.check(ui.view.node("ShopScreen","Reason").text.contains("購入・保存完了"),"purchase receipt visible")
 ui.shop_ids.clear(); ui.menu.shop()
 t.check(ui.view.node("ShopScreen","Buy").disabled and not ui.view.node("ShopScreen","Info").text.is_empty(),"empty shop is informative and safe")
 ui.show_character(); ui.open_menu("BlessingSelect")
 var committed: int=ui.blessing_index
 ui.cycle_blessing(1); ui.back()
 t.equal(ui.blessing_index,committed,"cancel blessing preview retains committed selection")
 ui.end_run(); ui.home()
 app.start_run("noah","attack",60606)
 ui.feedback.observe()
 app.run.field.crystals+=1
 app.run.state.progression.metrics.total_chests=1
 ui.feedback.observe()
 t.check(ui.notices.entries.any(func(entry): return entry.key=="chest"),"automatic chest reward receives visible feedback")
 var before_feedback: int=app.run.signature()
 ui.feedback.observe()
 t.equal(app.run.signature(),before_feedback,"presentation feedback cannot mutate gameplay")
 app.run.state.player.stats.meta_damage=1.0
 app.run.state.progression.weapons.magic_bolt=1
 app.run.state.progression.choices=[["weapons","magic_bolt"]]
 app.run.state.phase="LEVEL_UP"; ui.sync_phase()
 var content: String=ui.view.node("LevelUpPanel","Choice0").get_node("CardMargin/CardText").text
 var values: PackedStringArray=content.get_slice("\n",2).get_slice(" / ",0).trim_prefix("攻撃 ").split(" → ")
 t.check(values.size()==2 and float(values[1])>float(values[0]),"meta damage cannot make upgrade preview appear weaker")
 var preview_damage: float=float(values[1])
 ui.choose(0)
 var actual: float=app.run.weapons.stats[app.run.weapons.ids.find("magic_bolt")].damage
 t.check(absf(preview_damage-actual)<.051,"growth damage preview matches committed weapon runtime including meta")
 app.run.damage.normal_damage=120; app.run.damage.boss_damage=60; app.run.damage.field_damage=300
 app.run.damage.totals={"weapon:magic_bolt":180,"field:mining":300}; app.run.state.tick=600
 ui.menu.result()
 t.check(ui.view.node("ResultScreen","Info").text.contains("戦闘DPS 18.0"),"combat DPS excludes crystal mining HP")
 var font: Font=app.ui.theme.default_font
 t.check(font.has_char("結".unicode_at(0)),"Japanese font available for selected system font")
 app.queue_free()
 for i in range(4): await tree.process_frame
 tree.root.size=Vector2i(1280,720); tree.root.content_scale_size=Vector2i(1280,720)
 for path in ["user://qa_input.save","user://qa_input.save.bak","user://qa_input.save.tmp"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
