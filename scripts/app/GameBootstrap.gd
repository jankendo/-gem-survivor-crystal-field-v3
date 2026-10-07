extends Control
# Composition root; simulation owns gameplay, UI owns presentation/navigation only.
var save_path := SaveRepository.PATH
var db: GameDatabase
var saves: SaveRepository
var controller: UIController
var run: RunController
var renderer: WorldRenderer
var world_container: SubViewportContainer
var world_viewport: SubViewport
var ui: Control
var touch: TouchInput
var run_start_quests := 0
var safe_override := Rect2()
var temporary_profile := ""
var keyboard_neutral := true
var resizing := false
var critical_elapsed := 0.0
var slow_elapsed := 0.0
var system_elapsed := 0.0
var camera_size := Vector2(1280,720)
var ui_elapsed_us := 0
var ui_samples := 0
func _ready() -> void:
 db=GameDatabase.new()
 if not db.errors.is_empty(): print("Startup data rejected: ",db.errors)
 saves=SaveRepository.new(save_path,SaveRepository.LEGACY if save_path==SaveRepository.PATH else "user://qa_missing_legacy.save")
 world_container=SubViewportContainer.new()
 world_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 world_container.stretch=true
 world_container.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(world_container)
 world_viewport=SubViewport.new()
 world_viewport.size=Vector2i(1280,720)
 world_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 world_container.add_child(world_viewport)
 if db.errors.is_empty():
  renderer=WorldRenderer.new()
  world_viewport.add_child(renderer)
  renderer.configure(db)
 ui=Control.new()
 ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(ui)
 touch=TouchInput.new()
 touch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 touch.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(touch)
 controller=UIController.new()
 controller.initialize(self)
 get_viewport().size_changed.connect(resize_ui)
 resize_ui()
 apply_profile()
func resize_ui() -> void:
 if ui==null or resizing: return
 resizing=true
 # Canvas units are physical points on iOS, rather than a fixed720-unit UI
 # shrunk into a390pt phone. World camera/FOV is calculated independently.
 var density := maxf(1,DisplayServer.screen_get_scale())
 var logical := Vector2i(Vector2(get_tree().root.size)/density)
 if logical.x>0 and logical.y>0: get_tree().root.content_scale_size=logical
 SafeArea.new().apply(ui,safe_override)
 touch.safe_rect=Rect2(ui.position,ui.size)
 if controller!=null: controller.layout()
 update_camera()
 resizing=false
func update_camera() -> void:
 var size := get_viewport_rect().size
 if size.y<=0: return
 var aspect := size.x/size.y
 camera_size=Vector2(720*aspect,720) if aspect>=1280.0/720 else Vector2(1280,1280/aspect)
 if renderer!=null and world_viewport!=null: renderer.scale=Vector2(world_viewport.size)/camera_size
func effective_profile() -> String:
 return temporary_profile if not temporary_profile.is_empty() else str(saves.data.settings.profile)
func set_temporary_profile(value: String) -> void:
 if value not in ["","desktop_standard","ios_ultra"]: return
 temporary_profile=value
 apply_profile()
func apply_profile() -> void:
 if saves==null or world_container==null: return
 world_container.stretch_shrink=2 if effective_profile()=="ios_ultra" else 1
 if renderer!=null: renderer.profile=effective_profile()
 Engine.max_fps=int(saves.data.settings.render_fps)
 if not OS.has_feature("mobile") and DisplayServer.get_name()!="headless":
  var desired := DisplayServer.WINDOW_MODE_FULLSCREEN if saves.data.settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
  if DisplayServer.window_get_mode()!=desired: DisplayServer.window_set_mode(desired)
 if ui!=null and ui.theme!=null:
  ui.theme.default_font_size=roundi(18*float(saves.data.settings.get("ui_scale",1)))
 update_camera()
 if controller!=null:
  controller.view.apply_typography(float(saves.data.settings.get("ui_scale",1)))
  controller.layout()
func start_run(character: String="noah",blessing: String="attack",seed_input: int=-1) -> void:
 if saves.blocked_load or not db.errors.is_empty() or not db.table("characters").has(character) or not db.table("blessings").has(blessing): return
 if run!=null and run.state.phase!="RESULT": return
 if not (saves.data.progression.unlocked.has(character) or db.table("characters")[character].get("initial",false)): return
 if blessing!="attack" and not saves.data.progression.unlocked.has(blessing): return
 controller.character_index=controller.characters.find(character)
 controller.blessing_index=controller.blessings.find(blessing)
 run_start_quests=saves.data.progression.quests.size()
 run=RunController.new(db,seed_input if seed_input>=1 else int(Time.get_unix_time_from_system())%2147483647,character,saves.data.progression.unlocked)
 run.state.player.blessing=blessing
 var meta: Dictionary=saves.data.progression.get("meta",{})
 run.state.player.max_hp*=1+.03*int(meta.get("base_hp",0))
 run.state.player.hp=run.state.player.max_hp
 run.state.player.stats["meta_damage"] = .015*int(meta.get("base_damage",0))
 run.state.player.stats["meta_magnet"] = .03*int(meta.get("base_magnet",0))
 run.weapons.refresh(run.state,db)
 controller.progression.announced_combos.clear()
 controller.notices.entries.clear()
 controller.feedback.previous_run=null
 controller.show_hud()
 renderer.player_texture=load(db.table("characters")[character].generated_sprite)
 if not saves.data.settings.get("tutorial_seen",false): controller.notices.add("first_move","移動してGemへ近づくと回収できます。攻撃は自動。結晶は近づいて採掘。",3)
func reset_input() -> void:
 keyboard_neutral=true
 if touch!=null: touch.set_enabled(false); touch.cancel()
func input_direction(_tick: int) -> Vector2:
 if run==null or run.state.phase!="RUNNING" or controller.current!="HUD": return Vector2.ZERO
 var x := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
 var y := float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
 var keyboard := Vector2(x,y)
 if keyboard_neutral:
  if keyboard!=Vector2.ZERO: return touch.direction
  keyboard_neutral=false
 return (keyboard+touch.direction).limit_length()
func _physics_process(_delta: float) -> void:
 if run==null: return
 for n in range(run.speed): run.pipeline.tick(run,input_direction(run.state.tick))
 if run.state.phase=="RESULT": saves.settle(run)
 controller.sync_phase()
func _process(delta: float) -> void:
 if saves!=null: saves.tick(delta)
 if controller==null: return
 system_elapsed+=delta
 if system_elapsed>=1:
  system_elapsed=0
  controller.poll_system()
 if run!=null and renderer!=null:
  update_camera()
  renderer.present(run,camera_size)
 var started := Time.get_ticks_usec()
 critical_elapsed+=delta
 slow_elapsed+=delta
 if critical_elapsed>=1.0/30:
  critical_elapsed=fmod(critical_elapsed,1.0/30)
  controller.hud_presenter.critical()
 if slow_elapsed>=.2:
  slow_elapsed=fmod(slow_elapsed,.2)
  controller.hud_presenter.slow()
 ui_elapsed_us+=Time.get_ticks_usec()-started
 ui_samples+=1
func _input(event: InputEvent) -> void:
 if not event is InputEventKey: return
 if event.echo and event.keycode in [KEY_ENTER,KEY_SPACE,KEY_ESCAPE]: get_viewport().set_input_as_handled(); return
 # Gameplay shortcuts must precede native Tab focus traversal.
 if controller!=null and controller.current=="HUD" and event.keycode in [KEY_ESCAPE,KEY_P,KEY_TAB,KEY_M,KEY_E] and controller.key(event): get_viewport().set_input_as_handled()
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and controller!=null and controller.key(event): get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
  reset_input()
  if run!=null and run.pause() and controller!=null: controller.sync_phase()
 if what in [NOTIFICATION_WM_CLOSE_REQUEST,NOTIFICATION_APPLICATION_PAUSED] and saves!=null: saves.flush()

func _exit_tree() -> void:
 if controller!=null: controller.dispose()
