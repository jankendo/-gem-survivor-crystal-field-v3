extends SceneTree
var db: GameDatabase
func _initialize() -> void:
 call_deferred("run_benchmark")
func run_benchmark() -> void:
 db = GameDatabase.new()
 var mode := "performance"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--mode="): mode = arg.get_slice("=",1)
 var report := balance() if mode == "balance" else {"ok":true,"boss_TTK":boss_benchmark()} if mode == "boss" else performance(mode in ["performance_world","performance_late"],mode=="performance_late")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
 FileAccess.open("res://test-output/"+mode+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print(JSON.stringify(report))
 quit(0 if report.ok else 1)
func fixture(id: String, population: int, scenario: String) -> RunController:
 var run := RunController.new(db,60606)
 run.state.progression.weapons = {id:8}
 run.state.progression.gem_turret_charge=99
 run.state.player.hp = 1e9
 run.state.player.max_hp = 1e9
 run.state.phase = "RUNNING"
 run.map.rooms.clear()
 run.map.corridors.clear()
 run.map.kinds.clear()
 run.map.portals.clear()
 if scenario=="narrow_corridor": run.map.corridors.append(Rect2(-3000,-100,6000,200))
 else: run.map.rooms.append(Rect2(-3000,-3000,6000,6000))
 run.map.kinds.append("safe")
 run.weapons.refresh(run.state,db)
 for n in range(population):
  var pos := Vector2.RIGHT.rotated(n*2.399963) * (80 + sqrt(float(n))*15)
  if scenario == "narrow_corridor": pos = Vector2(n*4 - population*2, float(n%5)*12-24)
  var elite := scenario == "elite_mix" and n % 5 == 0
  run.enemies.spawn(0,pos,{"hp":200 if elite else 80,"speed":0,"radius":18,"exp":1,"elite":elite},1,population==1)
 return run
func combat_tick(run: RunController, moving: bool = false, mobility: bool = false) -> void:
 run.state.tick += 1
 run.damage.begin_tick()
 run.pipeline.status.tick(run.enemies,run.state.player,run.state.tick,run.damage,int(db.config().status.poison_period_ticks),float(db.config().status.poison_damage))
 run.spatial.begin_tick()
 for n in range(run.enemies.count):
  var i := run.enemies.dense[n]
  if moving: run.enemies.positions[i] = run.enemies.positions[i].rotated(.008)
  if mobility: run.enemies.positions[i] = Vector2.RIGHT.rotated(run.state.tick*.035)*280
  if run.enemies.hp[i]>0: run.spatial.insert(SpatialWorld.ENEMY,run.enemies.entity_id(i),run.enemies.positions[i],run.enemies.radius[i])
 run.deployments.tick(run.enemies,run.spatial,run.damage)
 run.weapons.tick(run.state,run.enemies,run.spatial,run.projectiles,run.damage,run)
 run.projectiles.tick(run.enemies,run.spatial,run.damage,run.map)
 for n in range(run.damage.death_count):
  var id := run.damage.death_ids[n]
  var i := run.enemies.slot(id)
  var pos := run.enemies.positions[i]
  var elite := run.enemies.flags[i]&2
  var boss := run.enemies.flags[i]&1
  run.enemies.remove(id)
  run.enemies.spawn(0,pos,{"hp":200 if elite else 80,"radius":18,"elite":elite != 0,"speed":0},1,boss != 0)
  run.state.progression.kills += 1
func balance() -> Dictionary:
 var results: Array = []
 var utility_ok := true
 var scenarios := {"single_boss":1,"30_enemies":30,"100_enemies":100,"300_enemies":300,"600_enemies":600,"narrow_corridor":100,"open_field":100,"moving_swarm":100,"elite_mix":100,"high_mobility_boss":1}
 for weapon in db.table("weapons"):
  var utility := utility_benchmark(weapon)
  var modifiers: Dictionary=db.table("v3_weapons")[weapon].modifiers
  if modifiers.has("gem_pull"): utility_ok=utility_ok and utility.gem_displacement>0 and utility.gems_collected>0
  if modifiers.has("mining"): utility_ok=utility_ok and utility.mining_damage>0
  if modifiers.has("pull") or modifiers.has("knockback"): utility_ok=utility_ok and utility.enemy_displacement>0
  if modifiers.has("ward"): utility_ok=utility_ok and utility.protection_uptime>0
  for scenario in scenarios:
   var run := fixture(weapon,scenarios[scenario],scenario)
   var covered := 0
   var cc := 0
   var risk := 0
   for tick in range(300):
    var before := run.damage.total()
    combat_tick(run,scenario=="moving_swarm",scenario=="high_mobility_boss")
    covered += int(run.damage.total() > before)
    for n in range(run.enemies.count):
     var i := run.enemies.dense[n]
     cc += int(run.enemies.slow[i] > 0 or run.enemies.shock[i] > 0)
     risk += int(run.enemies.positions[i].distance_squared_to(run.state.player.position) < 100*100)
   results.append({"weapon":weapon,"scenario":scenario,"DPS":run.damage.total()/5,"total_damage":run.damage.total(),"kills_per_second":run.state.progression.kills/5.0,"boss_DPS":run.damage.boss_damage/5,"bonus_currency":run.state.progression.currency,"damage_per_target":run.damage.total()/int(scenarios[scenario]),"coverage_uptime":covered/300.0,"overkill":run.damage.overkill,"CC_uptime":cc/(300.0*int(scenarios[scenario])),"utility":utility,"player_risk_exposure":risk/(300.0*int(scenarios[scenario]))})
  print("benchmarked ",weapon)
 var boss_results := boss_benchmark()
 var boss_ok := true
 for row in boss_results:
  var lo := 40 if row.build_strength<1 else 25 if row.build_strength==1 else 12
  var hi := 70 if row.build_strength<1 else 40 if row.build_strength==1 else 25
  boss_ok = boss_ok and row.TTK_seconds>=lo and row.TTK_seconds<=hi
 return {"ok":results.size()==db.table("weapons").size()*10 and boss_ok and utility_ok,"utility_gate":utility_ok,"seed":60606,"seconds_per_scenario":5,"weapon_results":results,"boss_TTK":boss_results,"limitation":"Repeatable combat and separate measured utility fixture; utility values are not an aggregate score. Boss TTK uses measured stationary build DPS; mechanics and human fun require playtest."}
func performance(real_world: bool = false,late_boss: bool = false) -> Dictionary:
 var run := fixture("magic_bolt",600,"600_enemies")
 if real_world:
  run.map.generate(run.state.rng.stream_seed("map"))
  for n in range(run.enemies.count):
   var i:=run.enemies.dense[n]
   run.enemies.positions[i]=run.map.safe_position(run.enemies.positions[i])
   run.enemies.speed[i]=68
   run.enemies.hp[i]=1e9
   run.enemies.max_hp[i]=1e9
 if late_boss:
  var id:=run.enemies.entity_id(run.enemies.dense[0])
  var position:=run.enemies.positions[run.enemies.slot(id)]
  run.enemies.remove(id)
  run.enemies.spawn(-6,position,{"hp":1e9,"radius":70,"speed":68},1,true)
  run.state.field_tick=108000
  run.state.boss_stage=6
 run.state.progression.weapons = {"magic_bolt":8,"bomb_seed":8,"ice_orbit":8,"thunder_chain":8}
 run.weapons.refresh(run.state,db)
 run.combos.refresh(run.state,db)
 for n in range(500): run.projectiles.add(Vector2(n%25*30-360,n/25*30-300),Vector2.RIGHT*100,1,"weapon:magic_bolt")
 for n in range(1000): run.gems.add(Vector2(n%40*25-500,n/40*25-300),1,run.map)
 var snapshot := RenderSnapshot.new()
 var total: Array = []
 var render: Array = []
 var enemy: Array = []
 var spatial: Array = []
 var weapons: Array = []
 var gem_allocations:=run.gems.allocations
 var warm_objects := 0
 var warm_memory := 0
 var allocations := run.enemies.allocations
 var initial_projectiles := run.projectiles.count
 var minimum_enemies:=600
 var minimum_projectiles:=initial_projectiles
 var minimum_gems:=run.gems.count
 var warm_query_reservations:=run.projectiles.scratch.allocations
 run.pipeline.profiling = true
 for frame in range(240):
  # Load is replenished between samples, not reduced to improve timing.
  while run.enemies.count < 600: run.enemies.spawn(0,Vector2(600,0),{"hp":1e9,"speed":0,"radius":18})
  while run.gems.count < 1000: run.gems.add(Vector2(1800,1800),1,run.map)
  while run.projectiles.count < 500: run.projectiles.add(Vector2(0,400),Vector2.RIGHT*100,1,"weapon:magic_bolt")
  minimum_enemies=mini(minimum_enemies,run.enemies.count)
  minimum_projectiles=mini(minimum_projectiles,run.projectiles.count)
  minimum_gems=mini(minimum_gems,run.gems.count)
  run.state.phase = "RUNNING"
  run.state.progression.choices.clear()
  var start := Time.get_ticks_usec()
  run.pipeline.tick(run,Vector2.ZERO)
  var sim := Time.get_ticks_usec()-start
  start = Time.get_ticks_usec()
  snapshot.capture(run.enemies)
  var prep := Time.get_ticks_usec()-start
  if frame==20:
   warm_query_reservations=run.projectiles.scratch.allocations
   warm_objects=int(Performance.get_monitor(Performance.OBJECT_COUNT))
   warm_memory=int(Performance.get_monitor(Performance.MEMORY_STATIC))
  if frame >= 20:
   total.append(sim)
   render.append(prep)
   enemy.append(run.pipeline.timings.get("enemy_us",0))
   spatial.append(run.pipeline.timings.get("spatial_us",0))
   weapons.append(run.pipeline.timings.get("weapon_us",0))
 return {"ok":run.enemies.allocations==allocations and minimum_enemies>=600 and minimum_projectiles>=500 and minimum_gems>=1000,"seed":60606,"samples":total.size(),"simulation":stats(total),"cpu_fixture_frame":stats(combine(total,render)),"render_preparation":stats(render),"enemy_update":stats(enemy),"spatial_update":stats(spatial),"weapon_update":stats(weapons),"enemy_count":run.enemies.count,"projectile_count":run.projectiles.count,"initial_projectile_count":initial_projectiles,"gem_count":run.gems.count,"gem_capacity":run.gems.capacity,"fixture_minimum_start_counts":{"enemy":minimum_enemies,"projectile":minimum_projectiles,"gem":minimum_gems},"engine_memory":{"warm_objects":warm_objects,"final_objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"object_delta":int(Performance.get_monitor(Performance.OBJECT_COUNT))-warm_objects,"warm_static_bytes":warm_memory,"final_static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"static_bytes_delta":int(Performance.get_monitor(Performance.MEMORY_STATIC))-warm_memory,"limit":"Godot live objects/static memory monitors, not cumulative heap allocation count"},"allocation_proxy":{"gem_capacity_growth":run.gems.allocations-gem_allocations,"projectile_query_buffer_reservations":run.projectiles.scratch.allocations,"projectile_query_buffer_growth":run.projectiles.scratch.allocations-warm_query_reservations,"enemy_capacity_growth":run.enemies.allocations-allocations,"spatial_capacity_growth":run.spatial.bucket_allocations-1},"real_generated_world":real_world,"late_boss":late_boss,"maximum_enemy_radius":run.enemies.maximum_radius,"note":"Headless Linux CPU only. Effects draw calls/GPU/Windows/iPhone frame time are not measured."}
func stats(values: Array) -> Dictionary:
 values.sort()
 var sum := 0.0
 for value in values: sum += float(value)
 return {"mean_ms":sum/values.size()/1000,"p95_ms":float(values[int(values.size()*.95)])/1000,"p99_ms":float(values[int(values.size()*.99)])/1000,"max_ms":float(values.back())/1000}

func combine(a: Array,b: Array) -> Array:
 var result: Array = []
 for n in range(a.size()): result.append(float(a[n])+float(b[n]))
 return result

func boss_benchmark() -> Array:
 var result: Array = []
 var specs := [
  {"name":"weak","weapons":{"magic_bolt":8,"laser_lance":8,"bomb_seed":8,"drone_bit":8},"passives":{"might":2,"cooldown":2,"area":2}},
  {"name":"median","weapons":{"magic_bolt":8,"thunder_chain":8,"bomb_seed":8,"laser_lance":8},"passives":{"might":3,"cooldown":3,"area":3,"elite_hunter":2}},
  {"name":"strong","weapons":{"magic_bolt":8,"thunder_chain":8,"bomb_seed":8,"laser_lance":8,"shrine_beam":8},"passives":{"might":5,"cooldown":5,"area":5,"elite_hunter":5}}
 ]
 for spec in specs:
  var run := fixture("magic_bolt",1,"single_boss")
  run.state.progression.weapons = spec.weapons
  run.state.progression.passives = spec.passives
  run.state.field_tick = 54000
  EvolutionSystem.new().refresh(run.state,db)
  run.weapons.refresh(run.state,db)
  run.damage.elite_multiplier = 1+float(run.state.player.stats.get("elite_damage",0))
  var enemy := run.enemies.dense[0]
  run.enemies.hp[enemy] = 1e9
  for tick in range(600): combat_tick(run)
  var dps := run.damage.total()/10
  result.append({"build":spec.name,"build_strength":.6 if spec.name=="weak" else 1.0 if spec.name=="median" else 1.8,"weapons":spec.weapons,"passives":spec.passives,"evolutions":run.state.progression.evolutions,"measured_DPS":dps,"TTK_seconds":float(db.config().boss_reference_dps[2])*float(db.config().boss_ttk_seconds)/maxf(.01,dps)})
 return result

func utility_benchmark(weapon: String) -> Dictionary:
 var run:=fixture(weapon,60,"open_field")
 run.state.progression.rooms[0]=true
 var original:=run.enemies.positions.duplicate()
 for n in range(run.enemies.count):
  var i:=run.enemies.dense[n]
  run.enemies.hp[i]=1e9
  run.enemies.max_hp[i]=1e9
  run.enemies.contact[i]=10000 # Isolate protection from hit-invulnerability in this utility fixture.
 run.field.positions=PackedVector2Array([Vector2(90,0)])
 run.field.hp=PackedFloat32Array([10000])
 run.field.active=PackedInt32Array([1])
 run.field.kinds=PackedStringArray(["reflect_crystal"])
 run.field.rifts.clear()
 var gem_ids:=PackedInt32Array()
 var gem_origins:=PackedVector2Array()
 for n in range(20):
  var position:=Vector2.RIGHT.rotated(n*TAU/20)*(220+n*4)
  gem_ids.append(run.gems.add(position,1,run.map))
  gem_origins.append(position)
 var protected:=0
 var charged:=run.state.progression.gem_turret_charge
 for tick in range(300):
  run.state.phase="RUNNING"
  run.state.progression.choices.clear()
  run.pipeline.tick(run,Vector2.ZERO)
  protected+=int(run.state.player.invulnerability>0)
 var gem_distance:=0.0
 for n in range(gem_ids.size()):
  var i:=gem_ids[n]
  gem_distance+=gem_origins[n].distance_to(run.gems.positions[i] if run.gems.active[i] else run.state.player.position)
 var enemy_distance:=0.0
 for n in range(run.enemies.count):
  var i:=run.enemies.dense[n]
  enemy_distance+=original[i].distance_to(run.enemies.positions[i])
 return {"fixture_seconds":5,"gem_displacement":gem_distance,"gems_collected":run.state.progression.gems,"enemy_displacement":enemy_distance,"mining_damage":run.damage.field_damage,"protection_uptime":protected/300.0,"net_gem_charge_spent":maxi(0,charged-run.state.progression.gem_turret_charge),"status":run.db.table("v3_weapons")[weapon].status,"archetype":run.db.table("v3_weapons")[weapon].archetype}
