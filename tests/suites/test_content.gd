extends RefCounted
func tags() -> Array: return ["unit","gameplay","deterministic"]
func run(t: TestContext,_tree: SceneTree) -> void:
 var db := GameDatabase.new()
 var save := SaveMigration.new().defaults()
 save.profile.currency=10000
 var shop := ShopSystem.new()
 t.check(not shop.available("weapons","laser_lance",save,db),"money cannot bypass laser mining prerequisite")
 save.profile.metrics={"total_crystals":20,"terrain_time":{"danger_den":60},"terrain_kills":{"crystal_corridor":1000},"gimmick_count":{"reflect_crystal":20}}
 t.check(shop.available("weapons","laser_lance",save,db),"mining condition publishes laser")
 t.check(shop.cost("weapons","laser_lance",db)>100,"original dynamic license cost")
 t.check(shop.available("weapons","wall_bounce_blaster",save,db),"specific gimmick condition")
 var c := ConditionSystem.new()
 t.check(not c.met(save,{"type":"unknown","value":0}),"unknown condition fails closed")
 t.check(not c.met(save,{"type":"exploration_rank","rank":"INVALID"}),"invalid rank fails closed")
 t.check(c.met(save,{"type":"terrain_time","terrain":"danger_den","value":60}),"terrain time")
 t.check(not c.met(save,{"type":"terrain_kills","terrain":"mine_chamber","value":1}),"terrain isolation")
 var run := RunController.new(db,456)
 run.state.progression.terrain_kills[0]=1000
 run.state.progression.terrain_crystals[2]=500
 run.state.progression.terrain_ticks[3]=18000
 run.state.progression.metrics.cursed_relics=10
 run.state.progression.metrics.shortcut_walls=100
 QuestSystem.new().settle(run,save)
 for id in ["corridor_breaker","mine_king","danger_den_master","relic_addict","shortcut_master"]: t.check(save.progression.quests.has(id),"ported quest "+id)
 t.check(not save.progression.unlocked.has("corridor_blade"),"discovery is not purchase entitlement")
 var totals: Dictionary=save.profile.metrics.duplicate(true)
 QuestSystem.new().settle(run,save)
 t.equal(save.profile.metrics,totals,"quest metrics cannot settle twice")
 var old := SaveMigration.new().migrate({"unlocked_weapons":["laser_lance"],"shop_purchases":{"weapon":{"comet_staff":true}}})
 t.check(not old.progression.unlocked.has("laser_lance"),"unproven legacy unlock is published not purchased")
 t.check(old.progression.unlocked.has("comet_staff"),"legacy purchase preserved")
 for definition in db.table("field_events").events:
  var event_run := RunController.new(db,777)
  t.check(event_run.field.events.start(event_run,0,definition.id),"event start "+str(definition.id))
  match str(definition.success_type):
   "survive": event_run.state.field_tick=event_run.field.events.deadline
   "crystal_break": event_run.field.crystals+=1
   "elite_reward": event_run.state.progression.elite_kills+=1
   "danger_time": event_run.field.events.danger_ticks=600
   "chest_open": event_run.state.progression.metrics.total_chests=1
  event_run.field.events.tick(event_run)
  t.equal(event_run.field.events_completed,1,"actual objective succeeds "+str(definition.id))
  t.equal(event_run.field.event,"","event ends "+str(definition.id))
 var failure := RunController.new(db,777)
 failure.field.events.start(failure,0,"elite_hunt")
 failure.state.field_tick=failure.field.events.deadline
 failure.field.events.tick(failure)
 t.equal(failure.field.events_completed,0,"normal kills cannot satisfy elite hunt")
 t.equal(failure.field.event,"","failed event ends")
