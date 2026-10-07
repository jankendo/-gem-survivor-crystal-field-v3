extends RefCounted
class_name UIController
const PHASE_SCREEN := {"RUNNING":"HUD","PAUSED":"PauseMenu","LEVEL_UP":"LevelUpPanel","CONTRACT":"ContractPanel","CLEAR":"RewardPanel","RESULT":"ResultScreen"}
# Navigation/command boundary; views never own gameplay phase or currency.
var app
var view := UIView.new()
var panels: Dictionary = {}
var current := ""
var history: Array[String] = []
var gate := UIActionGate.new()
var notices := UINotifications.new()
var menu: MenuPresenter
var progression: ProgressionPresenter
var hud_presenter: HUDPresenter
var feedback: GameplayFeedback
var characters: Array = []
var blessings: Array = []
var character_index := 0
var blessing_index := 0
var committed_blessing := 0
var shop_ids: Array = []
var shop_index := 0
var confirm_action: Callable
var warp_portal := -1
var fatal := false
var last_save_error := OK
func initialize(root) -> void:
 app=root
 view.initialize(app)
 panels=view.panels
 menu=MenuPresenter.new(self)
 progression=ProgressionPresenter.new(self)
 hud_presenter=HUDPresenter.new(self)
 feedback=GameplayFeedback.new(self)
 characters=app.db.table("characters").keys()
 blessings=app.db.table("blessings").keys()
 bind("TitleScreen","Start",show_character)
 bind("TitleScreen","Shop",show_shop)
 bind("TitleScreen","Collection",show_collection)
 bind("TitleScreen","Settings",func(): open_menu("SettingsScreen"))
 bind("CharacterSelect","Previous",cycle_character.bind(-1))
 bind("CharacterSelect","Next",cycle_character.bind(1))
 bind("CharacterSelect","Blessing",func(): open_menu("BlessingSelect"); menu.blessing())
 bind("CharacterSelect","Start",show_setup)
 bind("BlessingSelect","Previous",cycle_blessing.bind(-1))
 bind("BlessingSelect","Next",cycle_blessing.bind(1))
 bind("BlessingSelect","Select",func(): committed_blessing=blessing_index; back())
 bind("RunSetup","Start",start_selected)
 bind("ShopScreen","Previous",cycle_shop.bind(-1))
 bind("ShopScreen","Next",cycle_shop.bind(1))
 bind("ShopScreen","Buy",buy_next)
 bind("CollectionScreen","Mode",func(): menu.collection_mode=not menu.collection_mode; menu.collection())
 bind("SettingsScreen","Profile",toggle_profile)
 bind("SettingsScreen","FPS",toggle_fps)
 bind("SettingsScreen","Fullscreen",toggle_fullscreen)
 bind("SettingsScreen","Scale",toggle_scale)
 for screen in ["CharacterSelect","RunSetup","BlessingSelect","ShopScreen","SettingsScreen","CollectionScreen","EquipmentPanel","WarpPanel"]: bind(screen,"Back",back)
 bind("PauseMenu","Resume",pause_toggle)
 bind("PauseMenu","Seed",copy_seed)
 bind("PauseMenu","Equipment",show_equipment)
 bind("PauseMenu","Settings",func(): open_menu("SettingsScreen"))
 bind("PauseMenu","End",func(): confirm("ランを終了し、報酬を保存してリザルトへ進みます。",end_run))
 bind("PauseMenu","Home",func(): confirm("ランを終了して報酬を保存し、タイトルへ戻ります。",func(): end_run(); home()))
 for i in range(3): bind("LevelUpPanel","Choice"+str(i),choose.bind(i))
 bind("LevelUpPanel","Reroll",reroll)
 bind("LevelUpPanel","Banish",banish)
 bind("LevelUpPanel","Skip",skip)
 bind("LevelUpPanel","Pause",pause_toggle)
 bind("ContractPanel","Accept",func(): resolve_contract(true))
 bind("ContractPanel","Decline",func(): resolve_contract(false))
 bind("RewardPanel","End",end_run)
 bind("RewardPanel","Continue",continue_endless)
 bind("ResultScreen","Retry",start_selected)
 bind("ResultScreen","Home",home)
 bind("ConfirmPanel","Confirm",accept_confirm)
 bind("ConfirmPanel","Cancel",back)
 bind("WarpPanel","Enter",accept_warp)
 bind("SystemDialog","Retry",retry_save)
 bind("SystemDialog","Close",close_system)
 for i in range(12): bind("EquipmentPanel","Slot"+str(i),progression.slot.bind(i))
 for pair in [["Pause",pause_toggle],["Equipment",show_equipment],["Speed",change_speed],["Warp",enter_warp],["Mine",interact]]: bind("HUD",pair[0],pair[1])
 view.node("RunSetup","Seed").text_changed.connect(func(_text): validate_seed())
 view.node("RunSetup","Seed").text_submitted.connect(submit_seed)
 for screen in ["CharacterSelect","BlessingSelect","ShopScreen"]:
  view.node(screen,"Selector").item_selected.connect(func(index):
   if current!=screen: return
   if screen=="CharacterSelect": character_index=index; menu.character()
   elif screen=="BlessingSelect": blessing_index=index; menu.blessing()
   else: shop_index=index; menu.shop())
 refresh_selectors()
 app.touch.blocked=view.blocked_touch
 show_panel("TitleScreen")
 view.text("TitleScreen","Info","探索してGemを集め、成長を選び、15分の結晶王を目指します。攻撃は自動。\n移動: WASD / 矢印 / 左側ドラッグ\nポーズ: Esc / P · 装備: Tab · 採掘: M · ワープ: E")
 if not app.db.errors.is_empty(): system_error("起動に必要なデータを読み込めません。再起動しても直らない場合は配布ファイルを確認してください。",true)
 elif app.saves.load_status in ["corrupt","import_error"]: poll_system()
 elif app.saves.load_status in ["imported","recovered"]: view.text("TitleScreen","Reason","旧データの取り込み・保存の復旧が完了しました。元ファイルは保持しています。")
func bind(screen: String,button: String,action: Callable) -> void:
 view.node(screen,button).pressed.connect(func(): dispatch(screen,button,action))
func dispatch(screen: String,button: String,action: Callable) -> void:
 if current!=screen or view.node(screen,button).disabled or not gate.allow(screen+":"+button): return
 if not gate.allow("activation",-1,220): return
 action.call()
func layout() -> void: view.layout()
func show_panel(name: String) -> void:
 if app.run!=null and app.run.state.phase=="RUNNING": app.run.pause()
 current=name
 app.reset_input()
 view.present(name)
 if name=="TitleScreen":
  view.node(name,"Start").disabled=app.saves.blocked_load
  if app.saves.blocked_load: view.text(name,"Reason","保存データの復旧待ちです。元データを保護するため、開始・購入を停止しています。")
func show_hud() -> void:
 if app.run==null: return
 if app.run.state.phase!="RUNNING": sync_phase(); return
 current="HUD"
 app.reset_input()
 view.present("HUD")
 app.touch.set_enabled(true)
 hud_presenter.reset()
 update_hud()
func open_menu(name: String) -> void:
 history.append(current)
 show_panel(name)
 if name=="SettingsScreen": menu.settings()
func back() -> void:
 if current=="BlessingSelect": blessing_index=committed_blessing; menu.character()
 if current=="PauseMenu": pause_toggle(); return
 if current=="SystemDialog": close_system(); return
 confirm_action=Callable()
 var target: String=history.pop_back() if not history.is_empty() else "TitleScreen"
 if target=="HUD":
  if app.run!=null: app.run.resume()
  sync_phase()
 else: show_panel(target)
func show_character() -> void:
 history=["TitleScreen"]
 show_panel("CharacterSelect")
 menu.character()
func cycle_character(delta: int) -> void:
 if characters.is_empty(): return
 character_index=posmod(character_index+delta,characters.size())
 menu.character()
func next_character() -> void: cycle_character(1)
func cycle_blessing(delta: int) -> void:
 if blessings.is_empty(): return
 blessing_index=posmod(blessing_index+delta,blessings.size())
 menu.blessing()
func next_blessing() -> void: cycle_blessing(1)
func show_setup() -> void:
 open_menu("RunSetup")
 view.text("RunSetup","Info",menu.strings.name("characters",characters[character_index])+" / 祝福: "+menu.strings.name("blessings",blessings[blessing_index])+"\n15分ボス撃破でクリア。終了かエンドレス継続を選べます。")
 validate_seed()
func validate_seed() -> void:
 var text: String=view.node("RunSetup","Seed").text
 var valid := text.is_empty() or (text.is_valid_int() and int(text)>=1 and int(text)<=2147483647)
 view.node("RunSetup","Start").disabled=not valid
 view.text("RunSetup","Reason","" if valid else "シードは1〜2147483647の整数にしてください。")
func submit_seed(_text: String) -> void:
 if current!="RunSetup": return
 validate_seed()
 view.node("RunSetup","Seed").release_focus()
 if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD): DisplayServer.virtual_keyboard_hide()
 view.node("RunSetup","Back" if view.node("RunSetup","Start").disabled else "Start").grab_focus()
func start_selected() -> void:
 if current not in ["RunSetup","ResultScreen"] or characters.is_empty() or blessings.is_empty(): return
 var text: String=view.node("RunSetup","Seed").text
 if current=="RunSetup" and not text.is_empty() and (not text.is_valid_int() or int(text)<1 or int(text)>2147483647): return
 if not gate.allow("start_run"): return
 history.clear()
 app.start_run(characters[character_index],blessings[blessing_index],int(text) if not text.is_empty() else -1)
func pause_toggle() -> void:
 if app.run==null or current=="SystemDialog": return
 if app.run.state.phase=="PAUSED":
  if current!="PauseMenu": return
  app.run.resume()
  history.clear()
  sync_phase()
 elif app.run.pause():
  history.clear()
  show_panel("PauseMenu")
  view.text("PauseMenu","Info","ゲーム処理と入力は停止しています。シード: "+str(app.run.state.seed_value))
func choose(index: int) -> void:
 if app.run==null or current!="LevelUpPanel": return
 var before: Dictionary=app.run.state.progression.evolutions.duplicate()
 if not app.run.select(index):
  view.text("LevelUpPanel","Reason","この候補は選べません。最大Lv・装備枠を確認し、他の候補を選んでください。")
  return
 progression.progression_feedback(before)
 if not app.saves.data.settings.get("tutorial_seen",false):
  app.saves.data.settings.tutorial_seen=true
  app.saves.mark_dirty()
  notices.add("first_build","成長を選択しました。装備から進化条件を確認できます。紫の門は危険と報酬のある別室です。",3)
 sync_phase()
func reroll() -> void:
 if app.run.pipeline.level.reroll(app.run.state,app.db,app.run.unlocked): progression.choices()
func banish() -> void:
 if app.run.pipeline.level.banish(app.run.state):
  if app.run.state.phase=="LEVEL_UP": progression.choices()
  else: sync_phase()
func skip() -> void:
 if app.run.skip_choice(): sync_phase()
func resolve_contract(accept: bool) -> void:
 if app.run.resolve_contract(accept): sync_phase()
func continue_endless() -> void:
 if app.run==null or app.run.state.phase!="CLEAR": return
 app.run.continue_endless()
 notices.add("endless","クリア済み — エンドレスへ進みました。ポーズからいつでも終了できます。",3)
 sync_phase()
func sync_phase() -> void:
 if app.run==null or current=="SystemDialog": return
 var screen: String=PHASE_SCREEN.get(app.run.state.phase,"SystemDialog")
 if app.run.state.phase=="PAUSED" and current in ["SettingsScreen","EquipmentPanel","ConfirmPanel","WarpPanel","SystemDialog"]: return
 if current==screen: return
 if screen=="HUD": show_hud(); return
 show_panel(screen)
 if screen=="LevelUpPanel": progression.choices()
 elif screen=="ContractPanel":
  var d: Dictionary=app.db.table("rune_contracts").get(app.run.pending_contract,{})
  view.text(screen,"Info",str(d.get("name_ja","契約"))+"\n"+str(d.get("description_ja",""))+"\n断ってもランを続けられます。")
 elif screen=="PauseMenu": view.text(screen,"Info","ゲーム処理と入力は停止しています。シード: "+str(app.run.state.seed_value))
 elif screen=="RewardPanel": view.text(screen,"Info","15分の結晶王を撃破しました！終了して報酬を保存するか、同じビルドでエンドレスを続けられます。")
 elif screen=="ResultScreen": menu.result()
func end_run() -> void:
 if app.run==null: return
 app.run.finish()
 app.saves.settle(app.run)
 history.clear()
 sync_phase()
func home() -> void:
 if app.run!=null and app.run.state.phase!="RESULT": return
 app.run=null
 feedback.previous_run=null
 history.clear()
 show_panel("TitleScreen")
func result_text() -> String:
 menu.result()
 return view.node("ResultScreen","Info").text
func update_hud() -> void:
 hud_presenter.critical()
 hud_presenter.slow()
func show_equipment() -> void:
 if app.run==null: return
 open_menu("EquipmentPanel")
 progression.equipment()
func change_speed() -> void:
 if app.run!=null and app.run.state.phase=="RUNNING": app.run.speed=3-app.run.speed; hud_presenter.slow()
func nearest_portal() -> int:
 if app.run==null or app.run.warp.active: return -1
 for i in range(app.run.map.portals.size()):
  if app.run.map.portals[i].distance_to(app.run.state.player.position)<100: return i
 return -1
func enter_warp() -> void:
 warp_portal=nearest_portal()
 if warp_portal<0: notices.add("warp_help","紫の門に近づくとワープに入れます。"); return
 open_menu("WarpPanel")
 view.text("WarpPanel","Info","主フィールドの敵・Gem・時間を停止し、別の部屋で波を戦います。撃破すると報酬を得て戻ります。敵が強い場合もあるため、HPとビルドを確認してください。")
func accept_warp() -> void:
 if current!="WarpPanel" or app.run==null: return
 app.run.resume()
 if app.run.warp.enter(app.run,warp_portal): notices.add("warp_enter","ワープに入りました。全ての波を倒すと報酬！",3)
 history.clear()
 sync_phase()
func interact() -> void:
 if app.run!=null and app.run.state.phase=="RUNNING": app.run.interact()
func show_shop() -> void:
 shop_ids.clear()
 for kind in ["characters","weapons","passives","blessings","meta_upgrades"]:
  for id in app.db.table(kind): shop_ids.append([kind,id])
 history=["TitleScreen"]
 refresh_selectors()
 show_panel("ShopScreen")
 menu.shop()
func cycle_shop(delta: int) -> void:
 if shop_ids.is_empty(): return
 shop_index=posmod(shop_index+delta,shop_ids.size())
 menu.shop()
func update_shop() -> void: menu.shop()
func buy_next() -> void:
 if current!="ShopScreen" or shop_ids.is_empty() or view.node("ShopScreen","Buy").disabled or not gate.allow("purchase"): return
 var entry: Array=shop_ids[shop_index].duplicate()
 var success: bool=app.saves.buy_meta(entry[1],app.db.table(entry[0])[entry[1]]) if entry[0]=="meta_upgrades" else app.saves.buy_item(entry[0],entry[1],app.db)
 menu.shop()
 if success: view.text("ShopScreen","Reason","✓ 購入・保存完了 — "+menu.strings.name(entry[0],entry[1]))
 else: poll_system()
func show_collection() -> void:
 history=["TitleScreen"]
 show_panel("CollectionScreen")
 menu.collection()
func toggle_profile() -> void:
 app.saves.data.settings.profile="desktop_standard" if app.saves.data.settings.profile=="ios_ultra" else "ios_ultra"
 app.saves.mark_dirty()
 app.apply_profile()
 menu.settings()
func toggle_fps() -> void:
 app.saves.data.settings.render_fps=30 if int(app.saves.data.settings.render_fps)==60 else 60
 app.saves.mark_dirty()
 app.apply_profile()
 menu.settings()
func toggle_fullscreen() -> void:
 if OS.has_feature("mobile"): return
 app.saves.data.settings.fullscreen=not app.saves.data.settings.fullscreen
 app.saves.mark_dirty()
 app.apply_profile()
 menu.settings()
func toggle_scale() -> void:
 var old := float(app.saves.data.settings.get("ui_scale",1))
 app.saves.data.settings.ui_scale=1.15 if old<1.1 else 1.25 if old<1.2 else 1.0
 app.saves.mark_dirty()
 app.apply_profile()
 menu.settings()
func copy_seed() -> void:
 DisplayServer.clipboard_set(str(app.run.state.seed_value))
 view.text("PauseMenu","Reason","✓ シードをコピーしました。ランの準備で貼り付けられます。")
func confirm(text: String,action: Callable) -> void:
 confirm_action=action
 open_menu("ConfirmPanel")
 view.text("ConfirmPanel","Info",text)
func accept_confirm() -> void:
 if current!="ConfirmPanel" or not confirm_action.is_valid(): return
 var action := confirm_action
 confirm_action=Callable()
 action.call()
func system_error(message: String,is_fatal: bool=false) -> void:
 if current!="SystemDialog": history.append(current)
 fatal=is_fatal
 show_panel("SystemDialog")
 view.text("SystemDialog","Info",message)
 view.text("SystemDialog","Retry","再起動" if fatal else "復旧データを再確認" if app.saves.blocked_load else "保存を再試行")
 view.text("SystemDialog","Close","終了" if fatal else "閉じる")
func poll_system() -> void:
 if app.saves.last_error==OK:
  last_save_error=OK
  return
 if app.saves.last_error==last_save_error: return
 last_save_error=app.saves.last_error
 print("Save status: ",app.saves.load_status," reason=",last_save_error)
 system_error("保存データを読み込めませんでした。元ファイルを保持し、上書きを止めています。保存を復旧するまで購入できません。" if app.saves.blocked_load else "保存できませんでした。元データは保持しています。空き容量や保存先を確認して、再試行してください。購入が失敗した場合、貨と商品は変更されません。")
func retry_save() -> void:
 if fatal: app.get_tree().reload_current_scene(); return
 if app.saves.recover_blocked():
  last_save_error=OK
  view.text("TitleScreen","Reason","✓ 保存データの復旧・保存が完了しました。")
  close_system()
 else: view.text("SystemDialog","Reason","まだ保存できません。元データを保持しています。")
func close_system() -> void:
 if fatal: app.get_tree().quit(); return
 var target: String=history.pop_back() if not history.is_empty() else "TitleScreen"
 if target=="HUD":
  # Force phase presentation, not only the cached name, when dismissing scrim.
  current=""
  app.run.resume()
  sync_phase()
 else: show_panel(target)
func key(event: InputEventKey) -> bool:
 if not event.pressed or event.echo: return false
 if event.keycode==KEY_ESCAPE:
  if not gate.allow("keyboard_navigation",-1,220): return true
  if current=="HUD" or current=="LevelUpPanel" or current=="ContractPanel": pause_toggle()
  elif current=="ResultScreen": home()
  elif current!="TitleScreen": back()
  return true
 if event.keycode==KEY_P and current in ["HUD","PauseMenu","LevelUpPanel","ContractPanel"]:
  if gate.allow("keyboard_navigation",-1,220): pause_toggle()
  return true
 if current=="HUD":
  match event.keycode:
   KEY_TAB:
    if gate.allow("keyboard_navigation",-1,220): show_equipment()
   KEY_M: interact()
   KEY_E: enter_warp()
   _: return false
  return true
 if current=="LevelUpPanel" and event.keycode>=KEY_1 and event.keycode<=KEY_3:
  if gate.allow("activation",-1,220): choose(event.keycode-KEY_1)
  return true
 if event.keycode in [KEY_W,KEY_A,KEY_S,KEY_D]:
  var owner: Control = app.get_viewport().gui_get_focus_owner()
  if owner is LineEdit: return false
  var values := view.interactive(current)
  if not values.is_empty(): values[posmod(values.find(owner)+(-1 if event.keycode in [KEY_W,KEY_A] else 1),values.size())].grab_focus()
  return true
 return false
func source_name(id: String) -> String: return menu.strings.damage_name(id)

func dispose() -> void:
 if menu!=null: menu.ui=null
 if progression!=null: progression.ui=null
 if hud_presenter!=null: hud_presenter.ui=null
 if feedback!=null: feedback.ui=null; feedback.previous_run=null
 view.app=null
 app=null

func refresh_selectors() -> void:
 for screen in ["CharacterSelect","BlessingSelect","ShopScreen"]:
  var selector: OptionButton=view.node(screen,"Selector")
  selector.clear()
  var ids: Array=characters if screen=="CharacterSelect" else blessings if screen=="BlessingSelect" else shop_ids
  for id in ids:
   var kind: String="characters" if screen=="CharacterSelect" else "blessings" if screen=="BlessingSelect" else str(id[0])
   var key: String=str(id) if screen!="ShopScreen" else str(id[1])
   selector.add_item(menu.strings.name(kind,key))
  selector.disabled=ids.is_empty()
