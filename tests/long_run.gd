extends SceneTree
func _initialize() -> void: call_deferred("stress")
func stats(values: Array) -> Dictionary:
 values.sort()
 var sum:=0.0
 for v in values: sum+=v
 return {"mean_ms":sum/maxi(1,values.size())/1000,"p95_ms":values[int(values.size()*.95)]/1000.0,"p99_ms":values[int(values.size()*.99)]/1000.0,"max_ms":values.back()/1000.0}
func stress() -> void:
 var target_ticks:=108000
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--ticks="): target_ticks=int(arg.get_slice("=",1))
 var db:=GameDatabase.new()
 var r:=RunController.new(db,60606)
 r.map.rooms=[Rect2(-3000,-3000,6000,6000)];r.map.corridors.clear();r.map.kinds=["safe"]
 # Controlled stress fixture, not a normal-HP clear. Exact load is replenished.
 r.state.player.hp=1e9;r.state.player.max_hp=1e9;r.state.endless=true
 r.state.field_tick=108000;r.state.tick=108000;r.state.boss_stage=6
 r.state.progression.weapons={"magic_bolt":8,"bomb_seed":8,"ice_orbit":8,"thunder_chain":8}
 r.weapons.refresh(r.state,db);r.combos.refresh(r.state,db)
 for i in range(600): r.enemies.spawn(0,Vector2(300+i%25*15,-400+i/25*30),{"hp":1e9,"radius":18,"speed":0})
 r.enemies.remove(r.enemies.entity_id(r.enemies.dense[0]))
 r.enemies.spawn(-6,Vector2(350,0),{"hp":1e9,"radius":70,"speed":0,"damage":10},1,true)
 var samples: Array=[]
 var checkpoints: Array=[]
 var initial_objects:=0
 var warm_memory:=0
 var start:=Time.get_ticks_usec()
 var min_enemies:=600;var min_projectiles:=500;var min_gems:=1000
 var snapshot:=RenderSnapshot.new()
 var events:=PresentationEvents.new()
 for tick in range(target_ticks):
  while r.enemies.count<600: r.enemies.spawn(0,Vector2(700,0),{"hp":1e9,"radius":18,"speed":0})
  while r.projectiles.count<500: r.projectiles.add(Vector2(0,400),Vector2.RIGHT*100,1,"weapon:magic_bolt")
  while r.gems.count<1000: r.gems.add(Vector2(1000,1000),1,r.map)
  min_enemies=mini(min_enemies,r.enemies.count);min_projectiles=mini(min_projectiles,r.projectiles.count);min_gems=mini(min_gems,r.gems.count)
  r.state.phase="RUNNING";r.state.progression.choices.clear()
  var stamp:=Time.get_ticks_usec()
  r.pipeline.tick(r,Vector2.ZERO)
  if tick%6==0: samples.append(Time.get_ticks_usec()-stamp)
  if tick%30==0: snapshot.capture(r.enemies)
  if tick==600:
   initial_objects=int(Performance.get_monitor(Performance.OBJECT_COUNT));warm_memory=int(Performance.get_monitor(Performance.MEMORY_STATIC))
  if tick>0 and tick%9000==0:
   checkpoints.append({"simulation_seconds":tick/60.0,"objects":Performance.get_monitor(Performance.OBJECT_COUNT),"static_memory":Performance.get_monitor(Performance.MEMORY_STATIC),"enemy_capacity":r.enemies.capacity,"gem_capacity":r.gems.capacity,"projectile_capacity":ProjectileWorld.CAPACITY})
   print("LONG checkpoint ",tick," / ",target_ticks)
 # Repeated Warp transitions preserve the populated main world exactly.
 var warp_ok:=true
 for visit in range(6):
  r.state.phase="RUNNING"
  var main_enemies:=r.enemies;var main_gems:=r.gems;var main_tick:=r.state.field_tick
  warp_ok=warp_ok and r.warp.enter(r,0)
  if r.warp.active:
   for tick in range(120): r.pipeline.tick(r,Vector2.ZERO)
   r.warp.leave(r)
  warp_ok=warp_ok and r.enemies==main_enemies and r.gems==main_gems and r.state.field_tick==main_tick and r.warp.suspended.is_empty()
 var result: Dictionary={"ok":min_enemies>=600 and min_projectiles>=500 and min_gems>=1000 and warp_ok,"ticks":target_ticks,"simulation_minutes":target_ticks/3600.0,"wall_seconds":(Time.get_ticks_usec()-start)/1e6,"simulation":stats(samples),"sample_stride_ticks":6,"minimum_load":{"enemies":min_enemies,"projectiles":min_projectiles,"gems":min_gems},"checkpoints":checkpoints,"warm_objects":initial_objects,"final_objects":Performance.get_monitor(Performance.OBJECT_COUNT),"object_delta":int(Performance.get_monitor(Performance.OBJECT_COUNT))-initial_objects,"static_memory_delta":int(Performance.get_monitor(Performance.MEMORY_STATIC))-warm_memory,"warp_repetitions":6,"warp_main_freeze_resume":warp_ok,"note":"Continuous accelerated fixed-tick stress, late Endless/boss/combo/presentation event buffer. HP/phase are controlled stress fixture values; not normal run, GPU effects or real-time sustained device proof. Memory monitors are proxies, not cumulative native allocations."}
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
 FileAccess.open("res://test-output/long-run-"+str(target_ticks)+".json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
 print(JSON.stringify(result))
 quit(0 if result.ok else 1)
