extends RefCounted
class_name CollectionPresenter
var ui
var model: CollectionModel
var details: BuildDetails
var saved_scroll:=0
var saved_focus: Control
func _init(controller) -> void:
 ui=controller
 model=CollectionModel.new(ui.app.db)
 details=BuildDetails.new(ui.app.db)
 var view: UIView=ui.view
 for pair in [["Category",["すべて"]+CollectionModel.LABELS],["Status",["全状態","解放・達成済み","未解放・未達成","進行中Quest"]],["Sort",["標準順","名前順","解放順","達成率順"]]]:
  var selector: OptionButton=view.node("CollectionScreen",pair[0])
  for label in pair[1]: selector.add_item(label)
  selector.item_selected.connect(func(index):
   model.set("category" if pair[0]=="Category" else "status" if pair[0]=="Status" else "sorting",index)
   model.page=0; update())
 view.node("CollectionScreen","Search").text_changed.connect(func(value): model.query=value; model.page=0; update())
 view.node("CollectionScreen","Search").text_submitted.connect(func(_value):
  view.node("CollectionScreen","Search").release_focus()
  if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD): DisplayServer.virtual_keyboard_hide()
  view.node("CollectionScreen","Back").grab_focus())
 for i in range(CollectionModel.PAGE_SIZE): ui.bind("CollectionScreen","Row"+str(i),open_detail.bind(i))
 ui.bind("CollectionScreen","Clear",clear)
 ui.bind("CollectionScreen","Previous",change_page.bind(-1))
 ui.bind("CollectionScreen","Next",change_page.bind(1))
func clear() -> void:
 ui.view.node("CollectionScreen","Search").text=""
 model.query=""; model.page=0; update()
func change_page(offset: int) -> void:
 model.page+=offset; update()
 ui.view.node("CollectionScreen","Scroll").scroll_vertical=0
func update() -> void:
 model.update(ui.app.saves.data)
 ui.view.text("CollectionScreen","Title","図鑑・クエスト — %d件（%d/%d）" % [model.filtered.size(),model.page+1,maxi(1,ceili(float(model.filtered.size())/CollectionModel.PAGE_SIZE))])
 ui.view.text("CollectionScreen","Info","" if not model.filtered.is_empty() else "一致する項目はありません。検索・分類を変えてください。")
 ui.view.text("CollectionScreen","Reason","")
 for i in range(CollectionModel.PAGE_SIZE):
  var button: Button=ui.view.node("CollectionScreen","Row"+str(i))
  var index:=model.page*CollectionModel.PAGE_SIZE+i
  button.visible=index<model.filtered.size()
  if not button.visible: continue
  var e: Dictionary=model.entries[model.filtered[index]]
  var status: String="✓ 達成済み" if e.owned else "進行中" if e.ratio>0 else "未達成"
  if e.kind!="quests": status="✓ 解放・記録済み" if e.owned else "未解放・未記録"
  button.text=e.name+"\n"+status+(" / %d%%" % roundi(e.ratio*100) if e.kind=="quests" else " / "+CollectionModel.LABELS[CollectionModel.KINDS.find(e.kind)])
  button.accessibility_name=button.text
 ui.view.node("CollectionScreen","Previous").disabled=model.page==0
 ui.view.node("CollectionScreen","Next").disabled=(model.page+1)*CollectionModel.PAGE_SIZE>=model.filtered.size()
 ui.view.node("CollectionScreen","Category").select(model.category)
 ui.view.node("CollectionScreen","Status").select(model.status)
 ui.view.node("CollectionScreen","Sort").select(model.sorting)
 ui.view.layout()
func quests() -> void:
 model.category=6 if model.category!=6 else 0; model.page=0; update()
 ui.view.text("CollectionScreen","Mode","図鑑" if model.category==6 else "クエスト")
func open_detail(row: int) -> void:
 var index:=model.page*CollectionModel.PAGE_SIZE+row
 if index<0 or index>=model.filtered.size(): return
 saved_scroll=ui.view.node("CollectionScreen","Scroll").scroll_vertical
 saved_focus=ui.view.node("CollectionScreen","Row"+str(row))
 var e: Dictionary=model.entries[model.filtered[index]]
 var d: Dictionary=e.definition
 var text: String=e.name+"\n"+str(d.get("description_ja",""))
 if e.kind in ["weapons","passives"]: text=details.equipment(e.kind,e.id)
 elif e.kind=="quests": text+="\n"+ConditionSystem.new().progress_label(ui.app.saves.data,d.condition)+"\n達成率%d%%" % roundi(e.ratio*100)+"\n"+("✓ 達成済み" if e.owned else "探索終了時に条件を判定・報酬を保存します。")
 elif e.kind=="characters": text+="\n"+str(d.trait_ja)+"\n弱点: "+str(d.weakness_ja)+"\n開始装備: "+details.strings.name("weapons",d.initial_weapon)
 elif e.kind=="evolutions": text+=details.relationships("weapons",d.weapon)
 elif e.kind=="combos": text+="\n"+details.strings.name("weapons",d.weapon_a)+" + "+details.strings.name("weapons",d.weapon_b)+"\n両武器の所持で成立。元装備は保持します。"
 if e.kind in ["weapons","passives","characters"]: text+="\n解放条件: "+details.strings.condition(ShopSystem.new().condition(e.kind,e.id,ui.app.db))
 ui.open_menu("DetailPanel")
 ui.view.text("DetailPanel","Title","図鑑の詳細")
 ui.view.text("DetailPanel","Info",text)
func restore() -> void:
 var lifetime: CollectionPresenter=self
 var tree: SceneTree=ui.app.get_tree()
 for i in range(4):
  await tree.process_frame
  if lifetime.ui==null: return
 if ui.current!="CollectionScreen": return
 ui.view.node("CollectionScreen","Scroll").scroll_vertical=saved_scroll
 # Preserve the reading position; an offscreen row must not auto-scroll on focus.
 if is_instance_valid(saved_focus) and saved_focus.get_global_rect().intersection(ui.view.node("CollectionScreen","Scroll").get_global_rect()).size==saved_focus.size: saved_focus.grab_focus()
