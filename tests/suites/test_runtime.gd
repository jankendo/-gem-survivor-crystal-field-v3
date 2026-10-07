extends RefCounted
func tags() -> Array: return ["unit","deterministic","gameplay"]
func run(t: TestContext, _tree: SceneTree) -> void:
 var db := GameDatabase.new()
 t.equal(db.errors.size(),0,"database validation")
 var world := EnemyWorld.new(4)
 var id := world.spawn(0,Vector2.ZERO,{"hp":20})
 var slot := world.slot(id)
 world.contact[slot] = 60
 world.poison[slot] = 60
 world.shock[slot] = 60
 world.periodic[slot] = 60
 world.slow[slot] = 60
 var status := StatusSystem.new()
 var player := PlayerState.new()
 for tick in range(30): status.tick(world,player,tick)
 for v in [world.contact[slot],world.poison[slot],world.shock[slot],world.periodic[slot],world.slow[slot]]: t.equal(v,30,"timer decrements exactly once")
 t.check(world.remove(id),"remove live entity")
 t.check(not world.alive(id),"stale ID rejected")
 var new_id := world.spawn(0,Vector2.ONE,{"hp":8})
 t.check(new_id != id and world.slot(new_id) == slot,"generation on reuse")
 t.equal(world.allocations,1,"no growth after reuse")
 t.equal(world.count,1,"dense count correct")
 var damage := DamageSystem.new()
 damage.begin_tick()
 damage.apply(world,new_id,20,"combo:pair")
 damage.apply(world,new_id,20,"weapon:other")
 t.equal(damage.total(),8.0,"actual damage only once")
 t.equal(damage.death_count,1,"death event once")
 t.equal(damage.totals.get("weapon:other",0),0,"no attribution double count")
 var spatial := SpatialWorld.new()
 spatial.begin_tick()
 spatial.insert(SpatialWorld.ENEMY,10,Vector2(10,0))
 spatial.insert(SpatialWorld.ENEMY,11,Vector2(100,0))
 spatial.insert(SpatialWorld.GEM,12,Vector2(5,0))
 var buffer := QueryBuffer.new()
 spatial.query_circle(SpatialWorld.ENEMY,Vector2.ZERO,20,buffer)
 t.equal(buffer.to_array(),[10],"circle query")
 spatial.query_aabb(SpatialWorld.ENEMY,Rect2(0,-20,150,40),buffer)
 t.equal(buffer.size(),2,"aabb query")
 spatial.query_segment(SpatialWorld.ENEMY,Vector2.ZERO,Vector2(110,0),2,buffer)
 t.equal(buffer.size(),2,"segment query")
 t.equal(spatial.query_nearest(SpatialWorld.GEM,Vector2.ZERO,20,buffer),12,"nearest query layer")
 var allocations := spatial.bucket_allocations
 var query_allocations := buffer.allocations
 for n in range(100): spatial.query_circle(SpatialWorld.ENEMY,Vector2.ZERO,200,buffer)
 t.equal(buffer.allocations,query_allocations,"query buffer storage reused")
 t.equal(spatial.bucket_allocations,allocations,"query does not allocate buckets")
 t.equal(spatial.rebuilds,1,"queries do not rebuild index")
 spatial.deactivate_enemy(10)
 t.equal(spatial.query_nearest(SpatialWorld.ENEMY,Vector2.ZERO,200,buffer),11,"dead enemy excluded without index rebuild")
 var run := RunController.new(db,123)
 for n in range(60): run.pipeline.tick(run,Vector2.ZERO)
 t.equal(run.weapons.ids.size(),1,"only equipped active")
 t.equal(run.weapons.processed,60,"only equipped processed")
 t.check(run.encounter.spawned <= 13,"linear budget")
 for n in range(600): run.pipeline.tick(run,Vector2.ZERO)
 t.check(run.enemies.count <= run.encounter.target_alive(run.state,db),"target population bound")
 var map := WorldGenerator.new()
 map.generate(345)
 var map2 := WorldGenerator.new()
 map2.generate(345)
 t.equal(map.rooms,map2.rooms,"map seed reproducible")
 for n in range(100):
  var p := map.safe_position(Vector2(n*90-4500,n*30-1500))
  t.check(map.walkable(p,20),"reachable safe pickup")
 for a in range(map.portals.size()):
  for b in range(a+1,map.portals.size()): t.check(map.portals[a].distance_to(map.portals[b]) > 64,"portals do not overlap")
 var spawn_rng := RunRng.new()
 spawn_rng.set_seed_value(55)
 for rect in map.rooms:
  var player_pos := rect.end-Vector2(30,30)
  var spawn := map.spawn_position(player_pos,380,500,spawn_rng)
  t.check(spawn.distance_to(player_pos)>=200,"safe spawn never projects onto player")
 var warp := WarpSystem.new()
 t.equal(warp.choose(123,1,db),warp.choose(123,1,db),"warp seeded room type")
 var field_before := run.state.field_tick
 var rng_before := run.state.rng.snapshot()
 var enemy_before := run.enemies
 run.state.phase = "RUNNING"
 run.warp.enter(run,0)
 for n in range(10): run.pipeline.tick(run,Vector2.ZERO)
 t.equal(run.state.field_tick,field_before,"main field frozen")
 run.warp.leave(run)
 t.check(run.enemies == enemy_before,"main enemies restored")
 t.equal(run.state.rng.snapshot(),rng_before,"main RNG frozen")
 run.state.progression.weapons = {"magic_bolt":8,"bomb_seed":8}
 run.state.progression.passives = {"might":3,"cooldown":3}
 run.state.field_tick = 18000
 EvolutionSystem.new().refresh(run.state,db)
 t.check(run.state.progression.evolutions.has("magic_bolt"),"evolution recipe")
 run.combos.refresh(run.state,db)
 t.check(run.combos.active.size() > 0,"combo recipe preserves weapons")
 t.equal(run.state.progression.weapons.size(),2,"combo does not consume weapons")
 # Same tick-indexed input sequence at distinct render cadences and speed.
 var signatures: Array = []
 for mode in [[30,1],[60,1],[30,2],[60,2]]:
  var r := RunController.new(db,333)
  r.speed = mode[1]
  r.state.player.hp = 99999
  r.state.player.max_hp = 99999
  var input := func(tick: int) -> Vector2: return Vector2.RIGHT.rotated(tick*.001)
  while r.state.tick < 1200:
   var delta := minf(1.0/float(mode[0]), float(1200-r.state.tick)/60.0/float(r.speed))
   r.advance(delta,input)
   if r.state.phase == "LEVEL_UP": r.select(0)
  signatures.append(r.signature())
 for signature in signatures: t.equal(signature,signatures[0],"30/60fps + 1x/2x parity")
