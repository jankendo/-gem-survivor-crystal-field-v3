extends RefCounted
class_name GameplayFeedback
# Read-only, bounded presentation observation. Never creates rewards or touches RNG.
var ui
var previous_run
var crystals:=0
var chests:=0
var events:=0
var event_id:=""
var warped:=false
var evolutions: Dictionary={}
func _init(controller) -> void: ui=controller
func observe() -> void:
 var r: RunController=ui.app.run
 if r!=previous_run:
  previous_run=r; crystals=r.field.crystals; chests=int(r.state.progression.metrics.get("total_chests",0)); events=r.field.events_completed
  event_id=r.field.event; warped=r.warp.active; evolutions=r.state.progression.evolutions.duplicate()
  return
 var p: ProgressionState=r.state.progression
 if r.field.crystals>crystals: ui.notices.add("mined","結晶を破壊！Gemと貨を獲得しました。",1)
 var current_chests:=int(p.metrics.get("total_chests",0))
 if current_chests>chests: ui.notices.add("chest","宝箱を開封！貨・EXPと装備の成長を獲得。装備で確認できます。",2)
 if r.field.events_completed>events: ui.notices.add("event_done","イベント達成！Gem・貨と追加報酬を獲得しました。",2)
 elif not event_id.is_empty() and r.field.event.is_empty(): ui.notices.add("event_end","イベントは終了しました。次の探索を続けましょう。",1)
 if warped and not r.warp.active: ui.notices.add("warp_return","主フィールドへ戻りました。未回収のGemは門付近に残っています。",2)
 if p.evolutions.size()!=evolutions.size():
  ui.progression.progression_feedback(evolutions)
  evolutions=p.evolutions.duplicate()
 crystals=r.field.crystals; chests=current_chests; events=r.field.events_completed; event_id=r.field.event; warped=r.warp.active
