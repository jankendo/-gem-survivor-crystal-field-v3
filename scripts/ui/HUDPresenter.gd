extends RefCounted
class_name HUDPresenter
var ui
var last_stats: Array = []
var last_build := 0
var last_boss: Array=[]
var boss_id := -1
var critical_updates := 0
var slow_updates := 0
var string_updates := 0
var scratch := QueryBuffer.new(64)
func _init(controller) -> void: ui=controller
func reset() -> void:
 last_stats.clear()
 last_build=0
 boss_id=-1
 last_boss.clear()
func critical() -> void:
 if ui.current!="HUD" or ui.app.run==null: return
 critical_updates+=1
 var r: RunController=ui.app.run
 var s: RunState=r.state
 var values := [ceili(s.player.hp),ceili(s.player.max_hp),s.progression.level,s.field_tick/60,s.progression.kills,s.progression.exp]
 if values!=last_stats:
  last_stats=values
  ui.view.text("HUD","Stats","HP %d/%d · Lv%d · %02d:%02d" % [values[0],values[1],values[2],int(values[3])/60,int(values[3])%60])
  ui.view.text("HUD","EXP","EXP %d / %d" % [s.progression.exp,int(r.db.config().exp_base)+s.progression.level*int(r.db.config().exp_level)])
  string_updates+=1
 var hp: ProgressBar=ui.view.node("HUD","HP")
 hp.max_value=s.player.max_hp
 hp.value=s.player.hp
 var show_boss := r.enemies.alive(boss_id)
 ui.view.node("HUD","Boss").visible=show_boss
 ui.view.node("HUD","BossHP").visible=show_boss
 if show_boss:
  var i:=r.enemies.slot(boss_id)
  var boss_values: Array=[ceili(r.enemies.hp[i]),ceili(r.enemies.max_hp[i])]
  if boss_values!=last_boss:
   last_boss=boss_values
   ui.view.text("HUD","Boss","ボス — HP %d/%d" % boss_values)
   string_updates+=1
  ui.view.node("HUD","BossHP").max_value=r.enemies.max_hp[i]
  ui.view.node("HUD","BossHP").value=r.enemies.hp[i]
func slow() -> void:
 if ui.current!="HUD" or ui.app.run==null: return
 slow_updates+=1
 var r: RunController=ui.app.run
 ui.view.minimap.present(r)
 if not r.enemies.alive(boss_id):
  boss_id=-1
  for n in range(r.enemies.count):
   var i:=r.enemies.dense[n]
   if r.enemies.types[i]<0:
    boss_id=r.enemies.entity_id(i)
    break
 var s: RunState=r.state
 var guidance := "探索してGemと結晶を集める → 成長 → 5・10・15分のボス"
 if r.enemies.alive(boss_id): guidance="ボス戦 — 赤い予告円から離れ、移動しながら攻撃しましょう。"
 if r.warp.active: guidance="ワープ中 — 波 %d/%d · 残りの敵%d · 主フィールドは停止中" % [r.warp.wave_index,r.db.table("warp_rooms").types[r.warp.room_type].waves.size(),r.enemies.count]
 elif not r.field.event.is_empty(): guidance=str(r.field.events.definition.name_ja)+" — "+str(r.field.events.definition.objective_ja)+" / 残り%d秒" % maxi(0,(r.field.event_deadline-s.field_tick)/60)
 ui.view.text("HUD","Goal",guidance)
 ui.view.text("HUD","Speed","速度 %d倍" % r.speed)
 var near: int = ui.nearest_portal()
 ui.view.node("HUD","Warp").disabled=r.warp.active or near<0
 ui.view.node("HUD","Warp").tooltip_text="ワープ中です。波を倒すと戻ります。" if r.warp.active else "紫の門に近づくと入れます。" if near<0 else "危険と報酬を確認してワープに入る"
 ui.view.node("HUD","Mine").disabled=r.warp.active
 ui.view.node("HUD","Mine").tooltip_text="主フィールドに戻ると採掘できます。" if r.warp.active else "結晶・泉・宝箱へ近づいて使います。"
 var build := [s.progression.weapons,s.progression.passives,s.progression.evolutions].hash()
 if build!=last_build:
  last_build=build
  ui.view.text("HUD","Equipment","装備 %d/12" % (s.progression.weapons.size()+s.progression.passives.size()))
 ui.view.text("HUD","Notification",ui.notices.current())
