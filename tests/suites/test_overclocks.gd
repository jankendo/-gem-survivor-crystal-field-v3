extends RefCounted
func tags() -> Array: return ["unit","gameplay","deterministic"]
func run(t: TestContext,_tree: SceneTree) -> void:
 var db:=GameDatabase.new()
 var clocks:=OverclockSystem.new()
 t.equal(db.table("v3_overclocks").size(),20,"all source overclock IDs have runtime definitions")
 for evolution in db.table("overclocks"):
  var weapon: String=db.table("evolutions")[evolution].weapon
  for definition in db.table("overclocks")[evolution]:
   var controller:=RunController.new(db,987)
   controller.state.progression.weapons={weapon:8}
   controller.state.progression.evolutions={weapon:evolution}
   var choice: Array=["overclock",weapon,definition.id]
   t.check(clocks.apply(choice,controller.state,db),"named overclock selectable "+str(definition.id))
   t.check(not clocks.apply(choice,controller.state,db),"duplicate overclock rejected "+str(definition.id))
   t.check(not clocks.definition(choice,db).is_empty(),"Japanese overclock definition "+str(definition.id))
   controller.weapons.refresh(controller.state,db)
   t.check(controller.weapons.definitions[0].has("modifiers"),"cached overclock modifiers "+str(definition.id))
 var run:=RunController.new(db,987)
 run.damage.source_effects={"weapon:magic_bolt":{"death_burst_radius":100,"death_burst_damage":20}}
 run.spatial.begin_tick()
 var first: int=-1
 for n in range(3):
  var id:=run.enemies.spawn(0,Vector2(20+n*20,0),{"hp":5})
  run.spatial.insert(SpatialWorld.ENEMY,id,Vector2(20+n*20,0))
  if first<0: first=id
 run.damage.apply(run.enemies,first,10,"weapon:magic_bolt")
 DeathSystem.new().tick(run.state,run.enemies,run.gems,run.damage,run.map)
 t.equal(run.enemies.count,0,"chained death bursts drain appended deaths")
 t.equal(run.state.progression.kills,3,"chained death rewards counted once")
 t.equal(run.damage.total(),15.0,"chain attribution clamps HP once")
 t.equal(run.damage.death_count,0,"death event buffer fully drained")
