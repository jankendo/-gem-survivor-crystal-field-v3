extends RefCounted
class_name UIView
var app
var panels: Dictionary = {}
var controls: Dictionary = {}
var hud: Control
var minimap: Minimap
var scrim: ColorRect
var focus_rebuilds := 0
var typography: Array[Control] = []
var last_scale := -1.0
func initialize(root) -> void:
 app = root
 app.ui.theme = UITokens.new().build()
 scrim = ColorRect.new()
 scrim.color = Color(0,0,0,.7)
 scrim.mouse_filter = Control.MOUSE_FILTER_STOP
 app.ui.add_child(scrim)
 for name in ["TitleScreen","CharacterSelect","BlessingSelect","RunSetup","ShopScreen","CollectionScreen","SettingsScreen","PauseMenu","LevelUpPanel","ContractPanel","RewardPanel","ResultScreen","EquipmentPanel","ConfirmPanel","WarpPanel","SystemDialog","DetailPanel"]:
  var panel: Control = load("res://scenes/ui/"+name+".tscn").instantiate()
  app.ui.add_child(panel)
  panels[name] = panel
  controls[name] = {}
  index_nodes(panel,name)
  panel.minimum_size_changed.connect(func():
   if panel.is_visible_in_tree(): fit_panels.call_deferred())
  panel.hide()
 hud = load("res://scenes/ui/HUD.tscn").instantiate()
 app.ui.add_child(hud)
 index_nodes(hud,"HUD")
 node("HUD","Top").minimum_size_changed.connect(layout_hud.call_deferred)
 hud.hide()
 minimap=Minimap.new()
 minimap.mouse_filter=Control.MOUSE_FILTER_IGNORE
 minimap.clip_contents=true
 app.ui.add_child(minimap)
 minimap.hide()
 scrim.hide()
func index_nodes(node: Node, screen: String) -> void:
 if not controls.has(screen): controls[screen] = {}
 if node is Control: controls[screen][str(node.name)] = node
 if node is Label or node is Button or node is LineEdit:
  node.set_meta("ui_base_font",node.get_theme_font_size("font_size"))
  typography.append(node)
 if node is Label and node.name=="CardText":
  var card: Button=node.get_parent().get_parent()
  node.minimum_size_changed.connect(func():
   var height: float=maxf(88,node.get_combined_minimum_size().y+16)
   if absf(card.custom_minimum_size.y-height)>1: card.custom_minimum_size.y=height)
 if node is Button:
  if screen!="HUD": node.focus_entered.connect(func(): settle_focus(screen,node))
  node.custom_minimum_size.y = maxf(UITokens.TOUCH,node.custom_minimum_size.y)
  if node.name in ["Start","Confirm","Select","Resume","Continue","Retry","Buy"]: node.theme_type_variation = "PrimaryButton"
  if node.name in ["End","Home"] and screen in ["PauseMenu","ConfirmPanel"]: node.theme_type_variation = "DangerButton"
 for child in node.get_children(): index_nodes(child,screen)
func node(screen: String, key: String) -> Control: return controls[screen][key]
func text(screen: String, key: String, value: String) -> void:
 var control = node(screen,key)
 if control.text != value:
  control.text = value
  control.accessibility_name=value
 if key in ["Reason","Info"]: control.visible=not value.is_empty()
func present(screen: String) -> void:
 for panel in panels.values(): panel.hide()
 hud.visible = screen == "HUD"
 minimap.visible = screen == "HUD"
 scrim.visible = screen != "HUD"
 if panels.has(screen):
  panels[screen].show()
  node(screen,"Scroll").scroll_vertical=0
 layout()
 focus(screen)
func layout() -> void:
 scrim.size = app.ui.size
 for panel in panels.values():
  # Width must settle before wrapped labels can report their height. Assigning
  # width+height together clamps height against the previous narrow layout.
  panel.size.x=minf(800,app.ui.size.x)
 fit_panels.call_deferred()
 layout_hud()
func fit_panels() -> void:
 if app==null or not is_instance_valid(app): return
 for panel in panels.values():
  if not panel.is_visible_in_tree(): continue
  var name:=str(panel.name)
  if name=="CollectionScreen":
   var editing: bool=app.keyboard_points>0
   for key in ["Title","Filters","Scroll","Mode","Previous","Next"]: node(name,key).visible=not editing
   node(name,"Reason").visible=not editing and not node(name,"Reason").text.is_empty()
  if name=="RunSetup":
   var compact: bool=app.keyboard_points>0
   node(name,"Title").visible=not compact
   node(name,"Info").visible=not compact and not node(name,"Info").text.is_empty()
   node(name,"Reason").visible=not compact and not node(name,"Reason").text.is_empty()
   node(name,"SeedHelp").visible=not compact
   node(name,"Start").text="1〜2147483647のみ" if compact and node(name,"Start").disabled else "このビルドで出発"
  var desired:=Vector2(minf(800,app.ui.size.x),minf(640,app.ui.size.y))
  if panel.size!=desired: panel.size=desired
  panel.position=(app.ui.size-panel.size)*.5
  var actions: GridContainer=node(name,"Actions")
  var count:=actions.get_child_count()
  actions.columns=4 if name in ["LevelUpPanel","CollectionScreen"] and app.ui.size.y<500 else 3 if count>=5 and app.ui.size.y<500 else 2
  var owner: Control=app.get_viewport().gui_get_focus_owner()
  if owner!=null and node(name,"Scroll").is_ancestor_of(owner): node(name,"Scroll").ensure_control_visible.call_deferred(owner)
func layout_hud() -> void:
 if app==null or minimap==null: return
 var top: Control = node("HUD","Top")
 minimap.size=Vector2(120,80)
 minimap.position=Vector2(app.ui.size.x-120,0)
 top.size = Vector2(minf(app.ui.size.x-128,620),0)
 var actions: Control = node("HUD","Actions")
 actions.size = Vector2(minf(420,app.ui.size.x*.52),0)
 actions.position = Vector2(app.ui.size.x-actions.size.x,maxf(0,app.ui.size.y-actions.get_combined_minimum_size().y))
 var goal: Control = node("HUD","Goal")
 goal.position = Vector2(0,top.get_combined_minimum_size().y+8)
 goal.size = Vector2(minf(620,app.ui.size.x),42)
 var notice: Control = node("HUD","Notification")
 notice.position=Vector2(0,maxf(0,app.ui.size.y-68))
 notice.size=Vector2(maxf(100,app.ui.size.x-actions.size.x-8),64)
 hud.size = app.ui.size
func interactive(screen: String) -> Array[Control]:
 var result: Array[Control] = []
 if not controls.has(screen): return result
 for value in controls[screen].values():
  if (value is Button or value is LineEdit) and value.is_visible_in_tree() and (not value is Button or not value.disabled): result.append(value)
 return result
func focus(screen: String) -> void:
 var owner: Control = app.get_viewport().gui_get_focus_owner()
 if owner != null: owner.release_focus()
 var values := interactive(screen)
 for n in range(values.size()):
  var value := values[n]
  value.focus_neighbor_top = value.get_path_to(values[(n+values.size()-1)%values.size()])
  value.focus_neighbor_bottom = value.get_path_to(values[(n+1)%values.size()])
  value.focus_previous = value.focus_neighbor_top
  value.focus_next = value.focus_neighbor_bottom
  value.focus_neighbor_left = value.focus_neighbor_top
  value.focus_neighbor_right = value.focus_neighbor_bottom
 focus_rebuilds += 1
 if screen == "HUD" or values.is_empty(): return
 # Confirmation defaults to cancel; run-end cannot be triggered by held Enter.
 var first := values[0]
 if screen == "ConfirmPanel": first = node(screen,"Cancel")
 elif screen=="CollectionScreen": first=node(screen,"Back")
 elif screen=="RunSetup" and OS.has_feature("mobile"): first=node(screen,"Back" if node(screen,"Start").disabled else "Start")
 elif screen in ["ShopScreen","CharacterSelect","BlessingSelect"]:
  var primary: String="Buy" if screen=="ShopScreen" else "Start" if screen=="CharacterSelect" else "Select"
  first=node(screen,"Next") if node(screen,primary).disabled else node(screen,primary)
 first.call_deferred("grab_focus")
 settle_focus(screen,first)
func settle_focus(screen: String,first: Control) -> void:
 var lifetime: UIView=self # Keep coroutine owner alive until its deferred layout passes end.
 var tree: SceneTree=app.get_tree()
 # Text shaping and Container sorting finish across deferred layout passes.
 for pass_index in range(3):
  await tree.process_frame
  if lifetime.app==null or not is_instance_valid(app): return
 if lifetime.app==null or not is_instance_valid(app) or not is_instance_valid(first): return
 if app.controller.current!=screen or app.get_viewport().gui_get_focus_owner()!=first: return
 var scroll: ScrollContainer=node(screen,"Scroll")
 if scroll.is_ancestor_of(first):
  if first.size.y>scroll.size.y:
   var body: Control=node(screen,"Body")
   scroll.scroll_vertical=maxi(0,roundi(first.global_position.y-body.global_position.y))
  else: scroll.ensure_control_visible(first)
func blocked_touch(position: Vector2) -> bool:
 for control in controls.HUD.values():
  if control is Button and control.is_visible_in_tree() and control.get_global_rect().has_point(position): return true
 return false

func apply_typography(factor: float) -> void:
 if is_equal_approx(factor,last_scale): return
 last_scale=factor
 for control in typography: control.add_theme_font_size_override("font_size",roundi(int(control.get_meta("ui_base_font",18))*factor))
