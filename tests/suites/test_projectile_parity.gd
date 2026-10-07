extends RefCounted
func tags() -> Array: return ["unit","deterministic","performance"]
func run(t: TestContext,_tree: SceneTree) -> void:
 var db := GameDatabase.new()
 var old := RunController.new(db,456)
 var optimized := RunController.new(db,456)
 old.enemies.maximum_radius=80 # conservative bound reproduces the original 85px broadphase
 for controller in [old,optimized]:
  controller.state.player.hp=999999
  controller.state.player.max_hp=999999
  for n in range(100):
   controller.enemies.spawn(0,Vector2(50+n%10*25,n/10*25),{"hp":1000,"speed":0,"radius":18})
  controller.enemies.spawn(0,Vector2(60,23),{"hp":1000,"speed":0,"radius":18})
  for n in range(30): controller.projectiles.add(Vector2(0,n*8),Vector2.RIGHT*200,7,"weapon:magic_bolt",2)
 for tick in range(300):
  old.pipeline.tick(old,Vector2.ZERO)
  optimized.pipeline.tick(optimized,Vector2.ZERO)
 t.equal(optimized.signature(),old.signature(),"radius-bounded projectile broadphase exact replay parity")
 t.equal(optimized.damage.totals,old.damage.totals,"projectile attribution unchanged")
 var id := optimized.enemies.spawn(0,Vector2.ZERO,{"radius":70})
 t.equal(optimized.enemies.maximum_radius,70.0,"boss broadphase radius bound")
 optimized.enemies.remove(id)
 t.equal(optimized.enemies.maximum_radius,70.0,"removal keeps conservative bound")
