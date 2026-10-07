extends Control
# Composition root: no combat logic, timers or damage here.
var db: GameDatabase
var saves: SaveRepository
var controller: UIController
var run: RunController
var renderer: WorldRenderer
var world_container: SubViewportContainer
var world_viewport: SubViewport
var ui: Control
var touch: TouchInput
var dirty_ticks := 0
func _ready() -> void:
 db = GameDatabase.new()
 if not db.errors.is_empty():
  push_error(str(db.errors))
  return
 saves = SaveRepository.new()
 world_container = SubViewportContainer.new()
 world_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 world_container.stretch = true
 world_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(world_container)
 world_viewport = SubViewport.new()
 world_viewport.size = Vector2i(1280,720)
 world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 world_container.add_child(world_viewport)
 renderer = WorldRenderer.new()
 world_viewport.add_child(renderer)
 renderer.configure(db)
 ui = Control.new()
 add_child(ui)
 SafeArea.new().apply(ui)
 touch = TouchInput.new()
 touch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 touch.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(touch)
 controller = UIController.new()
 controller.initialize(self)
 get_viewport().size_changed.connect(resize_ui)
 resize_ui()
func resize_ui() -> void:
 if ui == null: return
 SafeArea.new().apply(ui)
 if controller != null: controller.layout()
 apply_profile()
func apply_profile() -> void:
 if saves == null or world_container == null: return
 var ultra := str(saves.data.settings.profile) == "ios_ultra"
 world_container.stretch_shrink = 2 if ultra else 1
 renderer.scale = Vector2.ONE / float(world_container.stretch_shrink)
 renderer.profile = str(saves.data.settings.profile)
 Engine.max_fps = int(saves.data.settings.render_fps)
func start_run(character: String = "noah", blessing: String = "attack") -> void:
 run = RunController.new(db,int(Time.get_unix_time_from_system()) % 2147483647,character,saves.data.progression.unlocked)
 run.state.player.blessing = blessing
 var meta: Dictionary = saves.data.progression.get("meta",{})
 run.state.player.max_hp *= 1+.03*int(meta.get("base_hp",0))
 run.state.player.hp = run.state.player.max_hp
 run.state.player.stats["meta_damage"] = .015*int(meta.get("base_damage",0))
 run.state.player.stats["meta_magnet"] = .03*int(meta.get("base_magnet",0))
 run.weapons.refresh(run.state,db)
 controller.show_hud()
 renderer.player_texture = load(db.table("characters")[character].generated_sprite)
func input_direction(_tick: int) -> Vector2:
 var x := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
 var y := float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
 return (Vector2(x,y) + touch.direction).limit_length()
func _physics_process(_delta: float) -> void:
 if run == null: return
 for n in range(run.speed):
  run.pipeline.tick(run,input_direction(run.state.tick))
 if run.state.phase == "RESULT": saves.settle(run)
 controller.sync_phase()
func _process(delta: float) -> void:
 if saves != null: saves.tick(delta)
 if run != null and renderer != null:
  renderer.present(run,get_viewport_rect().size)
  dirty_ticks += 1
  if dirty_ticks >= 6:
   controller.update_hud()
   dirty_ticks = 0
func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_ESCAPE: controller.pause_toggle()
  if run != null and run.state.phase == "LEVEL_UP" and event.keycode >= KEY_1 and event.keycode <= KEY_3: controller.choose(event.keycode-KEY_1)
func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
  if saves != null: saves.flush()
