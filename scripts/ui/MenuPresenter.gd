extends RefCounted
class_name MenuPresenter
var ui
var strings: UIStrings
var collection_mode := false
func _init(controller) -> void:
 ui=controller
 strings=UIStrings.new(ui.app.db)
func character() -> void:
 if ui.characters.is_empty(): return
 var id: String=ui.characters[ui.character_index]
 var d: Dictionary=ui.app.db.table("characters")[id]
 var owned: bool=ui.app.saves.data.progression.unlocked.has(id) or d.get("initial",false)
 var blessing := str(ui.blessings[ui.blessing_index])
 ui.view.text("CharacterSelect","Info",strings.name("characters",id)+"\n"+str(d.get("trait_ja",""))+"\n弱点: "+str(d.get("weakness_ja",""))+"\n祝福: "+strings.name("blessings",blessing)+"\n"+("解放済み" if owned else "未解放 — "+strings.condition(ShopSystem.new().condition("characters",id,ui.app.db))))
 var blessing_owned: bool=blessing=="attack" or ui.app.saves.data.progression.unlocked.has(blessing)
 ui.view.node("CharacterSelect","Start").disabled=not owned or not blessing_owned
 ui.view.node("CharacterSelect","Selector").select(ui.character_index)
 ui.view.text("CharacterSelect","Reason","未解放の祝福です。祝福を選び直してください。" if not blessing_owned else "" if owned else "ショップで条件を達成し、永久解放すると選べます。")
func blessing() -> void:
 var id: String=ui.blessings[ui.blessing_index]
 var d: Dictionary=ui.app.db.table("blessings")[id]
 var owned: bool=id=="attack" or ui.app.saves.data.progression.unlocked.has(id)
 ui.view.text("BlessingSelect","Info",strings.name("blessings",id)+"\n"+str(d.get("description_ja",""))+"\n"+("解放済み" if owned else strings.condition(d.get("unlock",{}))))
 ui.view.node("BlessingSelect","Select").disabled=not owned
 ui.view.node("BlessingSelect","Selector").select(ui.blessing_index)
 ui.view.text("BlessingSelect","Reason","" if owned else "未解放の祝福です。ショップで解放してください。")
func settings() -> void:
 var saved: Dictionary=ui.app.saves.data.settings
 var effective: String=ui.app.effective_profile()
 ui.view.text("SettingsScreen","Info","変更は即時反映・自動保存します。UIは縮小せず、描画品質はworldのみ変更します。\n選択品質: "+profile_name(str(saved.profile))+" / 有効品質: "+profile_name(effective)+("（一時override）" if effective!=saved.profile else ""))
 ui.view.text("SettingsScreen","Profile","品質: "+profile_name(str(saved.profile)))
 ui.view.text("SettingsScreen","FPS","描画: %d FPS（simulationは60Hz）" % int(saved.render_fps))
 ui.view.text("SettingsScreen","Scale","UI文字サイズ: %d%%" % roundi(100*float(saved.get("ui_scale",1))))
 ui.view.node("SettingsScreen","Fullscreen").disabled=OS.has_feature("mobile")
 ui.view.text("SettingsScreen","Fullscreen","全画面: "+("ON" if saved.fullscreen else "OFF"))
 ui.view.text("SettingsScreen","Reason","iOSは横画面・全画面です。" if OS.has_feature("mobile") else "音声なし。全画面は即時反映します。")
func profile_name(id: String) -> String: return "省電力 Ultra" if id=="ios_ultra" else "標準"
func shop() -> void:
 var buy: Button=ui.view.node("ShopScreen","Buy")
 if ui.shop_ids.is_empty():
  ui.view.text("ShopScreen","Info","商品はありません。図鑑から解放状況を確認できます。")
  ui.view.text("ShopScreen","Reason","購入できる商品がありません。")
  buy.disabled=true
  for key in ["Previous","Next","Selector"]: ui.view.node("ShopScreen",key).disabled=true
  return
 for key in ["Previous","Next","Selector"]: ui.view.node("ShopScreen",key).disabled=false
 ui.shop_index=posmod(ui.shop_index,ui.shop_ids.size())
 ui.view.node("ShopScreen","Selector").select(ui.shop_index)
 var entry: Array=ui.shop_ids[ui.shop_index]
 var d: Dictionary=ui.app.db.table(entry[0])[entry[1]]
 var data: Dictionary=ui.app.saves.data
 var owned: bool=data.progression.unlocked.has(entry[1])
 var level := int(data.progression.get("meta",{}).get(entry[1],0))
 var is_meta: bool=entry[0]=="meta_upgrades"
 var cost := int(d.get("base_cost",0))+int(d.get("cost_step",0))*level if is_meta else ShopSystem.new().cost(entry[0],entry[1],ui.app.db)
 var maxed: bool=is_meta and level>=int(d.max_level)
 var available: bool=is_meta or ShopSystem.new().available(entry[0],entry[1],data,ui.app.db)
 var currency := int(data.profile.currency)
 var reason := ""
 if owned and not is_meta: reason="購入済み — 永久解放されています。"
 elif maxed: reason="最大Lv — これ以上は購入できません。"
 elif not available: reason="条件未達 — 商品説明で解放条件を確認してください。"
 elif currency<cost: reason="必要: %d貨 / 所持: %d貨（%d貨不足）" % [cost,currency,cost-currency]
 elif ui.app.saves.blocked_load: reason="保存を復旧するまで購入できません。"
 else: reason="購入可能: %d貨 / 所持: %d貨" % [cost,currency]
 buy.disabled=(owned and not is_meta) or maxed or not available or currency<cost or ui.app.saves.blocked_load
 ui.view.text("ShopScreen","Buy","最大Lv" if maxed else "購入済み" if owned and not is_meta else "購入 %d貨" % cost)
 var detail := strings.name(entry[0],entry[1])+"\n"+str(d.get("description_ja",d.get("trait_ja","")))
 detail+="\n"+("永久強化: Lv%d → %d / 最大%d" % [level,mini(level+1,int(d.max_level)),int(d.max_level)] if is_meta else "永久解放 — 購入後、次のランから選択候補になります。\n条件: "+strings.condition(ShopSystem.new().condition(entry[0],entry[1],ui.app.db)))
 ui.view.text("ShopScreen","Info",detail)
 ui.view.text("ShopScreen","Reason",reason)
 buy.tooltip_text=reason
func collection() -> void:
 var data: Dictionary=ui.app.saves.data
 var text := ""
 if collection_mode:
  for id in ui.app.db.table("quests"):
   var d: Dictionary=ui.app.db.table("quests")[id]
   text+=("✓ 達成済み" if data.progression.quests.has(id) else "○ 進行中")+" — "+str(d.name_ja)+"\n"+str(d.description_ja)+"\n\n"
  if text.is_empty(): text="クエストはありません。探索で記録を増やしましょう。"
 else:
  text="図鑑登録: %d / 累計ラン: %d\n\n" % [data.progression.collection.size(),data.profile.runs]
  for kind in ["weapons","passives","characters"]:
   for id in ui.app.db.table(kind):
    text+=("✓ 解放済み — " if data.progression.unlocked.has(id) else "○ 未解放 — ")+strings.name(kind,id)+"\n"
  if data.progression.collection.is_empty(): text+="\n初めての探索で装備の記録が増えます。"
 ui.view.text("CollectionScreen","Title","クエスト" if collection_mode else "図鑑")
 ui.view.text("CollectionScreen","Info",text)
 ui.view.text("CollectionScreen","Mode","図鑑を見る" if collection_mode else "クエストを見る")
func result() -> void:
 var r: RunController=ui.app.run
 var p: ProgressionState=r.state.progression
 var status := "クリア" if r.state.boss_stage>=3 and p.bosses>=3 else "死亡" if r.state.player.hp<=0 else "ラン終了"
 var text := "%s\n生存 %02d:%02d / 最終Lv%d\n敵撃破 %d / ボス撃破 %d / Gem回収 %d\nラン報酬 %d貨 / 所持 %d貨\n" % [status,r.state.tick/3600,(r.state.tick/60)%60,p.level,p.kills,p.bosses,p.gems,r.state.settlement_reward,ui.app.saves.data.profile.currency]
 if r.state.player.hp<=0: text+="死因: "+strings.damage_name(r.state.last_damage_source)+"\n"
 var sources: Array=r.damage.totals.keys()
 sources.sort_custom(func(a,b): return r.damage.totals[a]>r.damage.totals[b])
 if sources.is_empty(): text+="まだダメージ記録はありません。\n"
 else:
  text+="主な攻撃: "+strings.damage_name(str(sources[0]))+"\n"
  text+="敵へのダメージ %.0f / ボスへのダメージ %.0f / DPS %.1f\n" % [r.damage.normal_damage,r.damage.boss_damage,r.damage.total()/maxf(1,r.state.tick/60.0)]
  for source in sources: text+="%s: %.0f（%.1f%%）\n" % [strings.damage_name(str(source)),r.damage.totals[source],100*float(r.damage.totals[source])/maxf(1,r.damage.total())]
 text+="\n完成した進化: "
 for id in p.evolutions.values(): text+=strings.name("evolutions",str(id))+" / "
 if p.evolutions.is_empty(): text+="なし（武器最大Lvと対応Passiveで目指せます）"
 text+="\n新しいクエスト達成: %d件\n次の探索: 図鑑で条件を確認 → ショップで永久解放" % maxi(0,ui.app.saves.data.progression.quests.size()-ui.app.run_start_quests)
 ui.view.text("ResultScreen","Title",status+" — リザルト")
 ui.view.text("ResultScreen","Info",text)
