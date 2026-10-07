extends RefCounted
class_name ProgressionPresenter
var ui
var strings: UIStrings
var announced_combos: Dictionary = {}
func _init(controller) -> void:
 ui=controller
 strings=UIStrings.new(ui.app.db)
func choices() -> void:
 var r: RunController=ui.app.run
 var p: ProgressionState=r.state.progression
 ui.view.text("LevelUpPanel","Info","" if ui.app.ui.size.y<500 else "Lv%d — 自動攻撃は止まっています。1つ選んでビルドを成長させましょう。" % p.level)
 for i in range(3):
  var button: Button=ui.view.node("LevelUpPanel","Choice"+str(i))
  button.visible=i<p.choices.size()
  button.disabled=not button.visible
  if not button.visible: continue
  var c: Array=p.choices[i]
  var d: Dictionary=OverclockSystem.new().definition(c,ui.app.db) if c[0]=="overclock" else ui.app.db.table(c[0])[c[1]]
  var content := str(d.get("name_ja","成長"))+"\n"
  if c[0]=="overclock": content+="オーバークロック — 進化武器を特別に拡張\n"+str(d.get("description_ja",""))
  else:
   var owned: Dictionary=p.weapons if c[0]=="weapons" else p.passives
   var before := int(owned.get(c[1],0))
   if before>=int(d.max_level):
    button.disabled=true
    var label: Label=button.get_node("CardMargin/CardText")
    label.text=content+"最大Lv%d — これ以上は強化できません。" % before
    button.tooltip_text=label.text
    button.accessibility_name=label.text
    continue
   content+=("武器" if c[0]=="weapons" else "パッシブ")+" / "+("新規" if before==0 else "強化")+" Lv%d → %d（最大%d）\n" % [before,before+1,d.max_level]
   if c[0]=="weapons":
    var old: Dictionary=StatResolver.new().resolve(c[1],r.state,ui.app.db,false)
    # Preview uses a cold cloned state; the live state/RNG is never changed.
    var preview := RunState.new()
    preview.player.stats=r.state.player.stats.duplicate()
    preview.player.character=r.state.player.character
    preview.player.blessing=r.state.player.blessing
    preview.player.evolved=r.state.player.evolved
    preview.player.contracts=r.state.player.contracts.duplicate()
    preview.progression.weapons=p.weapons.duplicate()
    preview.progression.passives=p.passives.duplicate()
    preview.progression.evolutions=p.evolutions.duplicate()
    preview.progression.overclocks=p.overclocks.duplicate()
    preview.progression.named_overclocks=p.named_overclocks.duplicate(true)
    preview.progression.weapons[c[1]]=before+1
    var after: Dictionary=StatResolver.new().resolve(c[1],preview,ui.app.db,false)
    content+=("攻撃 %.1f / 間隔 %.2f秒で自動攻撃を開始\n" % [after.damage,float(after.cooldown_ticks)/60] if before==0 else "攻撃 %.1f → %.1f / 間隔 %.2f → %.2f秒\n" % [old.damage,after.damage,float(old.cooldown_ticks)/60,float(after.cooldown_ticks)/60])
   else:
    var effects: Dictionary=ui.app.db.table("v3_passives").get(c[1],{})
    var labels := {"damage":"攻撃倍率","move":"移動倍率","magnet":"回収範囲倍率","cooldown":"攻撃間隔倍率","area":"範囲倍率","max_hp":"HP上限","regen":"毎秒回復","currency":"報酬倍率","armor":"軽減率","projectiles":"弾数"}
    for key in effects:
     if labels.has(key):
      var base:=1.0 if key in ["damage","move","magnet","cooldown","area","currency"] else 0.0
      content+=str(labels[key])+": %.2f → %.2f\n" % [base+float(effects[key])*before,base+float(effects[key])*(before+1)]
   for e in ui.app.db.table("evolutions").values():
    if e.weapon==c[1] or e.passive==c[1]:
     content+="進化: "+strings.name("weapons",e.weapon)+" Lv"+strings.number(e.weapon_level)+" + "+strings.name("passives",e.passive)+" Lv"+strings.number(e.passive_level)+"（5分以降）\n"
     break
   content+=str(d.get("description_ja",""))
  var label: Label=button.get_node("CardMargin/CardText")
  label.text=content
  button.tooltip_text=content
  button.accessibility_name=content
  button.custom_minimum_size.y=maxf(88,label.get_combined_minimum_size().y+16)
 var rerolls := maxi(0,1+int(r.state.player.stats.get("rerolls",0))-p.rerolls_used)
 var banishes := maxi(0,1+p.banishes_bonus+int(r.state.player.stats.get("banishes",0))-p.banishes_used)
 for pair in [["Reroll",rerolls,"再抽選"],["Banish",banishes,"末尾封印"],["Skip",p.skips,"スキップ"]]:
  ui.view.text("LevelUpPanel",pair[0],"%s%d" % [pair[2],pair[1]] if ui.app.ui.size.y<500 else "%s（残り%d）" % [pair[2],pair[1]])
  ui.view.node("LevelUpPanel",pair[0]).disabled=int(pair[1])<=0
 ui.view.text("LevelUpPanel","Reason","1つ選択。封印は最後の候補を除外。数字は残り回数。")
 ui.view.focus("LevelUpPanel")
func equipment() -> void:
 var p: ProgressionState=ui.app.run.state.progression
 var slots := p.weapons.keys()+p.passives.keys()
 for i in range(12):
  var kind := "weapons" if i<6 else "passives"
  var ids: Array=p.weapons.keys() if i<6 else p.passives.keys()
  var index := i%6
  var button: Button=ui.view.node("EquipmentPanel","Slot"+str(i))
  button.text="空き %d" % (index+1)
  button.tooltip_text="成長の候補から新しい装備を選べます。"
  if index<ids.size():
   var id: String=ids[index]
   var level := int((p.weapons if i<6 else p.passives)[id])
   var d: Dictionary=ui.app.db.table(kind)[id]
   var maxed: bool=level>=int(d.max_level)
   button.text=("◆ " if p.evolutions.has(id) else "◇ ")+strings.name(kind,id)+(" 最大" if maxed else " Lv%d" % level)
   button.tooltip_text=button.text+"\n"+str(d.get("description_ja",""))
 ui.view.text("EquipmentPanel","Info","武器%d / 6・パッシブ%d / 6。枠を押すと全文と進化条件を確認できます。" % [p.weapons.size(),p.passives.size()])
func slot(index: int) -> void:
 var p: ProgressionState=ui.app.run.state.progression
 var kind := "weapons" if index<6 else "passives"
 var ids: Array=p.weapons.keys() if index<6 else p.passives.keys()
 var text := "空き枠 — 成長画面で新しい装備を選びましょう。"
 if index%6<ids.size():
  var id: String=ids[index%6]
  text=ui.view.node("EquipmentPanel","Slot"+str(index)).tooltip_text
  for e in ui.app.db.table("evolutions").values():
   if e.weapon==id or e.passive==id: text+="\n進化条件: "+strings.name("weapons",e.weapon)+" Lv"+strings.number(e.weapon_level)+" + "+strings.name("passives",e.passive)+" Lv"+strings.number(e.passive_level)+"、5分以降。元武器の枠を保ちます。"
 ui.view.text("EquipmentPanel","Info",text)
func progression_feedback(before: Dictionary) -> void:
 var p: ProgressionState=ui.app.run.state.progression
 for weapon in p.evolutions:
  if not before.has(weapon):
   var d: Dictionary=ui.app.db.table("evolutions")[p.evolutions[weapon]]
   ui.notices.add("evolution:"+weapon,strings.name("evolutions",p.evolutions[weapon])+"に進化！ "+strings.name("weapons",weapon)+"最大Lv + "+strings.name("passives",d.passive)+"。元の装備枠を維持します。",3)
 for combo in ui.app.run.combos.active:
  if announced_combos.has(combo.id): continue
  announced_combos[combo.id]=true
  ui.notices.add("combo:"+str(combo.id),str(combo.display_name_ja)+"："+strings.name("weapons",combo.weapon_a)+" + "+strings.name("weapons",combo.weapon_b)+"で連携。両武器を維持します。",2)
