extends RefCounted
func tags() -> Array: return ["unit","deterministic","gameplay","release"]
func run(t: TestContext,_tree: SceneTree) -> void:
 var db:=GameDatabase.new()
 var save:=SaveMigration.new().normalize(SaveMigration.new().defaults())
 for id in db.table("characters"):
  var r:=RunController.new(db,8181,id)
  var d: Dictionary=db.table("characters")[id]
  t.equal(r.weapons.ids,[d.initial_weapon],"character actual starting weapon "+str(id))
  t.check(r.state.player.hp>0 and r.state.player.speed>0,"character finite initial stats "+str(id))
  t.check(not LoadoutSystem.new().candidates(r.state,db,r.unlocked).is_empty(),"character first choices "+str(id))
  var shop:=ShopSystem.new()
  t.check(save.progression.unlocked.has(id) or d.get("initial",false) or not shop.condition("characters",id,db).is_empty(),"character save/meta condition "+str(id))
  t.check(not r.state.player.stats.is_empty(),"character traits resolved "+str(id))
 var r:=RunController.new(db,91)
 r.damage.apply_player(r.state,10,"boss:telegraph")
 r.damage.apply_player(r.state,10,"boss:telegraph")
 t.equal(r.damage.player_hit_count,1,"received damage invulnerability counted once")
 t.equal(r.damage.player_boss_hits,1,"actual boss received hits")
 t.equal(r.damage.player_damage_total,10.0,"actual clamped received HP loss")
 var before:=r.signature()
 var diagnostic:=RunDiagnostics.new(r)
 diagnostic.observe()
 t.equal(r.signature(),before,"QA diagnostics cannot change simulation")

 var warning_run:=RunController.new(db,3)
 warning_run.map.rooms=[Rect2(-3000,-3000,6000,6000)]
 warning_run.map.corridors.clear()
 var warning_boss:=warning_run.enemies.spawn(-3,Vector2(200,0),{"hp":1000,"radius":50},1,true)
 var warning_slot:=warning_run.enemies.slot(warning_boss)
 warning_run.enemies.warning[warning_slot]=60
 warning_run.enemies.attack_target[warning_slot]=Vector2(180,0)
 var driver:=AutoplayDriver.new()
 t.check(driver.direction(warning_run,"close_range").x>0,"QA bot does not dodge a distant safe boss circle")
 warning_run.enemies.attack_target[warning_slot]=Vector2.ZERO
 t.check(driver.direction(warning_run,"close_range").x<.95,"QA bot evades an actual locked attack circle")

 for seed in [60606,314159,20261007]:
  var map:=WorldGenerator.new();map.generate(seed)
  var paths: Array=[[map.rooms[12].get_center(),map.corridors[0].get_center()],[map.corridors[8].get_center(),map.rooms[24].get_center()],[map.corridors[0].get_center(),map.corridors[17].get_center()]]
  for route in paths:
   var position: Vector2=route[0]
   var target: Vector2=route[1]
   for tick in range(5000):
    if position.distance_to(target)<8: break
    position=map.move(position,(map.pursuit_target(position,target)-position).normalized()*4)
   t.check(position.distance_to(target)<8,"corridor pursuit route reaches target seed"+str(seed))
