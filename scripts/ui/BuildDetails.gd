extends RefCounted
class_name BuildDetails
# One cold, read-only model for collection, equipment and growth comparisons.
var db: GameDatabase
var strings: UIStrings
func _init(database: GameDatabase) -> void:
 db=database
 strings=UIStrings.new(db)
func preview(state: RunState,kind: String,id: String) -> RunState:
 var copy:=RunState.new()
 copy.player.stats=state.player.stats.duplicate()
 copy.player.character=state.player.character
 copy.player.blessing=state.player.blessing
 copy.player.evolved=state.player.evolved
 copy.player.contracts=state.player.contracts.duplicate()
 for field in ["weapons","passives","evolutions","overclocks","named_overclocks"]: copy.progression.set(field,state.progression.get(field).duplicate(true))
 copy.progression.get(kind)[id]=int(copy.progression.get(kind).get(id,0))+1
 return copy
func relationships(kind: String,id: String,state: RunState=null) -> String:
 var text:=""
 for e in db.table("evolutions").values():
  if e.weapon!=id and e.passive!=id: continue
  text+="\n進化: "+strings.name("weapons",e.weapon)+" Lv"+strings.number(e.weapon_level)+" + "+strings.name("passives",e.passive)+" Lv"+strings.number(e.passive_level)+" / 5分以降"
  if state!=null:
   text+="（武器%d/%d・パッシブ%d/%d・時間%s）" % [int(state.progression.weapons.get(e.weapon,0)),int(e.weapon_level),int(state.progression.passives.get(e.passive,0)),int(e.passive_level),"✓" if state.field_tick>=18000 else "未達"]
   if state.progression.evolutions.has(e.weapon): text+=" 成立済み"
 for c in db.table("weapon_combo_attacks").get("combos",[]):
  if kind!="weapons" or id not in [c.weapon_a,c.weapon_b]: continue
  text+="\n連携: "+str(c.display_name_ja)+" — "+strings.name("weapons",c.weapon_a)+" + "+strings.name("weapons",c.weapon_b)
  if state!=null: text+="（成立中）" if state.progression.weapons.has(c.weapon_a) and state.progression.weapons.has(c.weapon_b) else "（相方未所持）"
 if not text.is_empty(): text+="\n進化・連携は元の装備枠を保ちます。"
 return text
func equipment(kind: String,id: String,state: RunState=null) -> String:
 var d: Dictionary=db.table(kind).get(id,{})
 if d.is_empty(): return "情報がありません。"
 var text:=strings.name(kind,id)+"\n"+("武器" if kind=="weapons" else "パッシブ")+" — "+str(d.get("description_ja",""))
 var level:=int(state.progression.get(kind).get(id,0)) if state!=null else 0
 text+="\n現在Lv%d / 最大%d" % [level,int(d.max_level)] if state!=null else "\n最大Lv%d" % int(d.max_level)
 if kind=="weapons":
  if state!=null and level>0:
   var stat:=StatResolver.new().resolve(id,state,db,false)
   text+="\n実際の通常値: 攻撃%.1f / 間隔%.2f秒 / 範囲%.0f / 対象%d" % [stat.damage,float(stat.cooldown_ticks)/60,stat.radius,stat.targets]
   if level<int(d.max_level):
    var next:=StatResolver.new().resolve(id,preview(state,kind,id),db,false)
    text+="\n次Lv: 攻撃%.1f → %.1f / 間隔%.2f → %.2f秒" % [stat.damage,next.damage,float(stat.cooldown_ticks)/60,float(next.cooldown_ticks)/60]
   else: text+="\n最大Lv — 次は進化・オーバークロックを確認。"
  else:
   var runtime: Dictionary=db.table("v3_weapons")[id]
   text+="\n基礎値: 攻撃%.1f / 間隔%.2f秒（キャラクター・パッシブで変化）" % [runtime.damage,runtime.cooldown]
 else:
  var names: Dictionary={"damage":"攻撃","cooldown":"攻撃間隔","area":"範囲","move":"移動","magnet":"回収範囲","regen":"毎秒回復","armor":"軽減","max_hp":"HP上限","currency":"報酬","projectiles":"弾数"}
  for key in db.table("v3_passives").get(id,{}):
   var amount: float=float(db.table("v3_passives")[id][key])
   text+="\n"+str(names.get(key,"固有効果"))+": Lvあたり%+.2f" % amount
   if state!=null and level<int(d.max_level): text+=" / 次の装備寄与 %.2f → %.2f" % [amount*level,amount*(level+1)]
 return text+relationships(kind,id,state)
