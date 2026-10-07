extends RefCounted
class_name UIController
var app
var panels: Dictionary = {}
var current := ""
var character_index := 0
var blessing_index := 0
var characters: Array = []
var blessings: Array = []
var minimap: Minimap
var hud: Control
var shop_ids: Array = []
var shop_index := 0
var last_hud := ""
func initialize(root) -> void:
 app = root
 for name in ["TitleScreen","PauseMenu","LevelUpPanel","RewardPanel","ResultScreen","ShopScreen","CharacterSelect","SettingsScreen","ContractPanel"]:
  var panel: Control = load("res://scenes/ui/" + name + ".tscn").instantiate()
  app.ui.add_child(panel)
  panels[name] = panel
  panel.hide()
 hud = load("res://scenes/ui/HUD.tscn").instantiate()
 app.ui.add_child(hud)
 minimap = Minimap.new()
 minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
 app.ui.add_child(minimap)
 minimap.hide()
 hud.hide()
 connect_button("TitleScreen","Start",show_character)
 connect_button("TitleScreen","Shop",show_shop)
 connect_button("TitleScreen","Collection",show_collection)
 connect_button("TitleScreen","Settings",func(): show_panel("SettingsScreen"))
 connect_button("CharacterSelect","Next",next_character)
 connect_button("CharacterSelect","Blessing",next_blessing)
 connect_button("CharacterSelect","Start",func(): app.start_run(characters[character_index],blessings[blessing_index]))
 for name in ["CharacterSelect","ShopScreen","SettingsScreen"]: connect_button(name,"Back",func(): show_panel("TitleScreen"))
 connect_button("PauseMenu","Resume",pause_toggle)
 connect_button("PauseMenu","Seed",func(): DisplayServer.clipboard_set(str(app.run.state.seed_value)))
 connect_button("PauseMenu","End",end_run)
 for i in range(3): connect_button("LevelUpPanel","Choice"+str(i),choose.bind(i))
 connect_button("RewardPanel","End",end_run)
 connect_button("RewardPanel","Continue",func(): app.run.continue_endless(); show_hud())
 connect_button("ResultScreen","Retry",func(): app.start_run(characters[character_index],blessings[blessing_index]))
 connect_button("ResultScreen","Home",func(): app.run = null; show_panel("TitleScreen"))
 connect_button("SettingsScreen","Profile",toggle_profile)
 connect_button("SettingsScreen","FPS",toggle_fps)
 connect_button("SettingsScreen","Fullscreen",func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_WINDOWED))
 connect_button("ShopScreen","Buy",buy_next)
 connect_button("ShopScreen","Next",func(): shop_index += 1; update_shop())
 connect_button("LevelUpPanel","Skip",func():
  if not app.run.state.progression.choices.is_empty():
   if app.run.state.progression.skips<=0: return
   app.run.state.progression.skips-=1
  app.run.state.progression.choices.clear()
  app.run.state.phase = "RUNNING"
  show_hud())
 connect_button("LevelUpPanel","Reroll",func():
  if app.run.pipeline.level.reroll(app.run.state,app.db,app.run.unlocked):
   current = ""
   sync_phase())
 connect_button("LevelUpPanel","Banish",func():
  if app.run.pipeline.level.banish(app.run.state):
   current = ""
   sync_phase())
 hud.get_node("Actions/Pause").pressed.connect(pause_toggle)
 hud.get_node("Actions/Speed").pressed.connect(func(): app.run.speed = 3-app.run.speed)
 hud.get_node("Actions/Warp").pressed.connect(enter_warp)
 hud.get_node("Actions/Mine").pressed.connect(interact)
 connect_button("ContractPanel","Accept",func(): app.run.contract.accept(app.run); show_hud())
 connect_button("ContractPanel","Decline",func(): app.run.pending_contract=""; app.run.state.phase="RUNNING"; show_hud())
 show_panel("TitleScreen")
 layout()
func connect_button(panel: String, button: String, callable: Callable) -> void: panels[panel].get_node("Scroll/Body/"+button).pressed.connect(callable)
func layout() -> void:
 for panel in panels.values():
  panel.size = Vector2(minf(600,app.ui.size.x),minf(600,app.ui.size.y))
  panel.position = (app.ui.size-panel.size)*.5
 var touch_height := 48.0
 if OS.has_feature("ios"):
  var physical_scale: float = float(DisplayServer.window_get_size().y)/app.get_viewport_rect().size.y
  touch_height = maxf(48,44*DisplayServer.screen_get_scale()/maxf(.1,physical_scale))
 for panel in panels.values():
  for node in panel.get_node("Scroll/Body").get_children():
   if node is Button: node.custom_minimum_size.y = touch_height
 for node in hud.get_node("Actions").get_children(): node.custom_minimum_size.y = touch_height
 hud.position = Vector2.ZERO
 hud.size = Vector2(app.ui.size.x,160)
 minimap.size = Vector2(180,160)
 minimap.position = Vector2(app.ui.size.x-180,0)
func show_panel(name: String) -> void:
 for panel in panels.values(): panel.hide()
 hud.hide()
 minimap.hide()
 current = name
 panels[name].show()
 layout()
func show_hud() -> void:
 for panel in panels.values(): panel.hide()
 minimap.show()
 current = "HUD"
 hud.show()
 last_hud = ""
 update_hud()
func show_character() -> void:
 characters.clear()
 blessings.clear()
 for id in app.db.table("blessings"):
  if id=="attack" or app.saves.data.progression.unlocked.has(id): blessings.append(id)
 for id in app.db.table("characters"):
  if app.saves.data.progression.unlocked.has(id) or app.db.table("characters")[id].get("initial",false): characters.append(id)
 character_index %= characters.size()
 show_panel("CharacterSelect")
 update_character()
func next_character() -> void:
 character_index = (character_index+1) % characters.size()
 update_character()
func next_blessing() -> void:
 blessing_index = (blessing_index+1) % blessings.size()
 update_character()
func update_character() -> void:
 var d: Dictionary = app.db.table("characters")[characters[character_index]]
 panels.CharacterSelect.get_node("Scroll/Body/Info").text = str(d.name_ja)+"
"+str(d.trait_ja)+"
"+str(d.weakness_ja)+"
祝福: "+str(app.db.table("blessings")[blessings[blessing_index]].name_ja)+"
移動: WASD / 矢印 / 左側ドラッグ。攻撃は自動。"
func pause_toggle() -> void:
 if app.run == null: return
 if app.run.state.phase == "PAUSED":
  app.run.state.phase = "RUNNING"
  show_hud()
 elif app.run.state.phase == "RUNNING":
  app.run.state.phase = "PAUSED"
  panels.PauseMenu.get_node("Scroll/Body/Info").text = "シード: "+str(app.run.state.seed_value)+"
探索 → 撃破 → ジェム → BUILD → 危険報酬 → ボス"
  show_panel("PauseMenu")
func choose(index: int) -> void:
 app.run.select(index)
 show_hud()
func sync_phase() -> void:
 var phase: String = app.run.state.phase
 if phase == "LEVEL_UP" and current != "LevelUpPanel":
  show_panel("LevelUpPanel")
  var choices: Array = app.run.state.progression.choices
  var detail := ""
  for choice in choices:
   var def: Dictionary = OverclockSystem.new().definition(choice,app.db) if choice[0]=="overclock" else app.db.table(choice[0])[choice[1]]
   detail += str(def.name_ja)+": "+str(def.get("description_ja",""))+"\n"
  panels.LevelUpPanel.get_node("Scroll/Body/Info").text = detail
  for i in range(3):
   var button: Button = panels.LevelUpPanel.get_node("Scroll/Body/Choice"+str(i))
   button.visible = i < choices.size()
   if i < choices.size():
    var c: Array = choices[i]
    var d: Dictionary = OverclockSystem.new().definition(c,app.db) if c[0]=="overclock" else app.db.table(c[0])[c[1]]
    button.text = str(d.name_ja)+" — "+("オーバークロック" if c[0]=="overclock" else "成長")
    button.tooltip_text = str(d.get("description_ja",""))
 elif phase == "CONTRACT" and current != "ContractPanel":
  show_panel("ContractPanel")
  var def: Dictionary = app.db.table("rune_contracts")[app.run.pending_contract]
  panels.ContractPanel.get_node("Scroll/Body/Info").text = str(def.name_ja)+"\n"+str(def.description_ja)
 elif phase == "CLEAR" and current != "RewardPanel": show_panel("RewardPanel")
 elif phase == "RESULT" and current != "ResultScreen":
  show_panel("ResultScreen")
  panels.ResultScreen.get_node("Scroll/Body/Info").text = result_text()
func end_run() -> void:
 app.run.state.phase = "RESULT"
 app.saves.settle(app.run)
 sync_phase()
func result_text() -> String:
 var r: RunController = app.run
 var text := "生存時間: %d秒 / 撃破: %d / 報酬: %d
死因: %s
通常敵: %.0f / ボス: %.0f / DPS: %.1f
" % [r.state.field_tick/60,r.state.progression.kills,r.state.settlement_reward,source_name(r.state.last_damage_source),r.damage.normal_damage,r.damage.boss_damage,r.damage.total()/maxf(1,r.state.tick/60.0)]
 for source in r.damage.totals:
  var id: String = str(source).get_slice(":",1)
  var name := source_name(str(source))
  if app.db.table("weapons").has(id): name = app.db.table("weapons")[id].name_ja
  elif str(source).begins_with("combo:"):
   for d in app.db.table("weapon_combo_attacks").combos:
    if d.id == id: name = d.display_name_ja
  text += "%s: %.0f (%.1f%%)
" % [name,r.damage.totals[source],100*float(r.damage.totals[source])/maxf(1,r.damage.total())]
 return text
func update_hud() -> void:
 if app.run == null or current != "HUD": return
 minimap.present(app.run)
 var s: RunState = app.run.state
 var text := "HP %d / %d   Lv %d   EXP %d   %02d:%02d   撃破 %d" % [s.player.hp,s.player.max_hp,s.progression.level,s.progression.exp,s.field_tick/3600,(s.field_tick/60)%60,s.progression.kills]
 if text != last_hud:
  hud.get_node("Stats").text = text
  last_hud = text
 var guidance := "RISK — 探索 / 5・10・15分にボス"
 if not app.run.field.event.is_empty():
  var event: Dictionary=app.run.field.events.definition
  guidance = str(event.name_ja)+" — "+str(event.objective_ja)+" %ds" % maxi(0,(app.run.field.event_deadline-s.field_tick)/60)
 var sense := float(s.player.stats.get("indicator_range",0))
 if sense>0 and app.run.field.positions.size()>0:
  var nearest := -1
  var distance := 600+sense
  for i in range(app.run.field.positions.size()):
   var d: float = app.run.field.positions[i].distance_to(s.player.position)
   if app.run.field.active[i] and d<distance:
    distance=d
    nearest=i
  if nearest>=0:
   var direction: Vector2 = app.run.field.positions[nearest]-s.player.position
   guidance += " / 報酬 "+("→" if direction.x>0 else "←")+" %dm" % int(distance)
 if hud.get_node("Goal").text!=guidance: hud.get_node("Goal").text=guidance
 var build := "BUILD: "
 for id in s.progression.weapons: build += str(app.db.table("weapons")[id].name_ja)+" Lv"+str(s.progression.weapons[id])+"  "
 if hud.get_node("Build").text != build: hud.get_node("Build").text = build
func toggle_profile() -> void:
 app.saves.data.settings.profile = "desktop_standard" if app.saves.data.settings.profile == "ios_ultra" else "ios_ultra"
 app.saves.mark_dirty()
 app.apply_profile()
func toggle_fps() -> void:
 app.saves.data.settings.render_fps = 90-int(app.saves.data.settings.render_fps)
 app.saves.mark_dirty()
 app.apply_profile()
func enter_warp() -> void:
 if app.run == null or app.run.warp.active: return
 for i in range(app.run.map.portals.size()):
  if app.run.map.portals[i].distance_to(app.run.state.player.position) < 100:
   app.run.warp.enter(app.run,i)
   return
func interact() -> void: app.run.interact()
func show_shop() -> void:
 shop_ids.clear()
 panels.ShopScreen.get_node("Scroll/Body/Buy").show()
 panels.ShopScreen.get_node("Scroll/Body/Next").show()
 for kind in ["characters","weapons","passives","blessings","meta_upgrades"]:
  for id in app.db.table(kind):
   if kind=="meta_upgrades" or not app.saves.data.progression.unlocked.has(id): shop_ids.append([kind,id])
 show_panel("ShopScreen")
 update_shop()
func update_shop() -> void:
 if shop_ids.is_empty():
  panels.ShopScreen.get_node("Scroll/Body/Info").text = "すべて解放済み"
  return
 shop_index %= shop_ids.size()
 var entry: Array = shop_ids[shop_index]
 var d: Dictionary = app.db.table(entry[0])[entry[1]]
 var shop := ShopSystem.new()
 var cost: int = shop.cost(entry[0],entry[1],app.db) if entry[0]!="meta_upgrades" else 0
 if entry[0]=="meta_upgrades": cost = int(d.base_cost)+int(d.cost_step)*int(app.saves.data.progression.get("meta",{}).get(entry[1],0))
 panels.ShopScreen.get_node("Scroll/Body/Info").text = "クリスタル貨: %d
%s — %d貨
永久解放は購入でのみ成立します" % [app.saves.data.profile.currency,d.name_ja,cost]
 var available: bool = entry[0]=="meta_upgrades" or shop.available(entry[0],entry[1],app.saves.data,app.db)
 panels.ShopScreen.get_node("Scroll/Body/Buy").disabled = not available
 if not available: panels.ShopScreen.get_node("Scroll/Body/Info").text += "\n条件未達: "+str(shop.condition(entry[0],entry[1],app.db))
func buy_next() -> void:
 if shop_ids.is_empty(): return
 var entry: Array = shop_ids[shop_index]
 var d: Dictionary = app.db.table(entry[0])[entry[1]]
 if entry[0]=="meta_upgrades": app.saves.buy_meta(entry[1],d)
 elif app.saves.buy_item(entry[0],entry[1],app.db): shop_ids.remove_at(shop_index)
 update_shop()
func show_collection() -> void:
 show_panel("ShopScreen")
 panels.ShopScreen.get_node("Scroll/Body/Buy").hide()
 panels.ShopScreen.get_node("Scroll/Body/Next").hide()
 var text := "図鑑登録: %d / 累計ラン: %d\n" % [app.saves.data.progression.collection.size(),app.saves.data.profile.runs]
 for id in app.db.table("quests"):
  var d: Dictionary = app.db.table("quests")[id]
  text += ("達成済み — " if app.saves.data.progression.quests.has(id) else "進行中 — ")+str(d.name_ja)+": "+str(d.description_ja)+"\n"
 panels.ShopScreen.get_node("Scroll/Body/Info").text = text

func source_name(id: String) -> String:
 return {"enemy":"敵との接触","boss":"ボスの攻撃","field:mining":"結晶採掘","field:lightning":"雷導結晶","field:meteor":"予告された流星","status:poison":"毒状態"}.get(id,id)
