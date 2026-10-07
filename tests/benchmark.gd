extends SceneTree
var db: GameDatabase
func _initialize() -> void:
 call_deferred("run_benchmark")
func run_benchmark() -> void:
 db = GameDatabase.new()
 var mode := "performance"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--mode="): mode = arg.get_slice("=",1)
 var report := balance() if mode == "balance" else {"ok":true,"boss_TTK":boss_benchmark()} if mode == "boss" else performance()
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://test-output"))
 FileAccess.open("res://test-output/"+mode+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print(JSON.stringify(report))
 quit(0 if report.ok else 1)
func fixture(id: String, population: int, scenario: String) -> RunController:
 var run := RunController.new(db,60606)
 run.state.progression.weapons = {id:8}
 run.state.player.hp = 1e9
 run.state.player.max_hp = 1e9
 run.state.phase = "RUNNING"
 run.map.rooms.clear()
 run.map.corridors.clear()
 run.map.kinds.clear()
 run.map.portals.clear()
 run.map.rooms.append(Rect2(-3000,-3000,6000,6000))
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
 run.pipeline.status.tick(run.enemies,run.state.player,run.state.tick)
 run.spatial.begin_tick()
 for n in range(run.enemies.count):
  var i := run.enemies.dense[n]
  if moving: run.enemies.positions[i] = run.enemies.positions[i].rotated(.008)
  if mobility: run.enemies.positions[i] = Vector2.RIGHT.rotated(run.state.tick*.035)*280
  run.spatial.insert(SpatialWorld.ENEMY,run.enemies.entity_id(i),run.enemies.positions[i])
 run.weapons.tick(run.state,run.enemies,run.spatial,run.projectiles,run.damage)
 run.projectiles.tick(run.enemies,run.spatial,run.damage)
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
 var scenarios := {"single_boss":1,"30_enemies":30,"100_enemies":100,"300_enemies":300,"600_enemies":600,"narrow_corridor":100,"open_field":100,"moving_swarm":100,"elite_mix":100,"high_mobility_boss":1}
 for weapon in db.table("weapons"):
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
     cc += int(run.enemies.slow[i] > 0 or run.enemies.shock[i] > 0 or run.enemies.poison[i] > 0)
     risk += int(run.enemies.positions[i].distance_squared_to(run.state.player.position) < 100*100)
   results.append({"weapon":weapon,"scenario":scenario,"DPS":run.damage.total()/5,"total_damage":run.damage.total(),"kills_per_second":run.state.progression.kills/5.0,"boss_DPS":run.damage.boss_damage/5,"damage_per_target":run.damage.total()/int(scenarios[scenario]),"coverage_uptime":covered/300.0,"overkill":run.damage.overkill,"CC_uptime":cc/(300.0*int(scenarios[scenario])),"utility":{"status":db.table("v3_weapons")[weapon].status,"archetype":db.table("v3_weapons")[weapon].archetype},"player_risk_exposure":risk/(300.0*int(scenarios[scenario]))})
  print("benchmarked ",weapon)
 var boss_results := boss_benchmark()
 var boss_ok := true
 for row in boss_results:
  var lo := 40 if row.build_strength<1 else 25 if row.build_strength==1 else 12
  var hi := 70 if row.build_strength<1 else 40 if row.build_strength==1 else 25
  boss_ok = boss_ok and row.TTK_seconds>=lo and row.TTK_seconds<=hi
 return {"ok":results.size()==db.table("weapons").size()*10 and boss_ok,"seed":60606,"seconds_per_scenario":5,"weapon_results":results,"boss_TTK":boss_results,"limitation":"Repeatable combat fixture; utility descriptors are not a numerical value judgment. Boss TTK uses measured stationary build DPS; mechanics and human fun require playtest."}
func performance() -> Dictionary:
 var run := fixture("magic_bolt",600,"600_enemies")
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
 var allocations := run.enemies.allocations
 var initial_projectiles := run.projectiles.count
 run.pipeline.profiling = true
 for frame in range(240):
  # Load is replenished between samples, not reduced to improve timing.
  while run.enemies.count < 600: run.enemies.spawn(0,Vector2(600,0),{"hp":1e9,"speed":0,"radius":18})
  while run.gems.count < 1000: run.gems.add(Vector2(1800,1800),1,run.map)
  while run.projectiles.count < 500: run.projectiles.add(Vector2(0,400),Vector2.RIGHT*100,1,"weapon:magic_bolt")
  run.state.phase = "RUNNING"
  run.state.progression.choices.clear()
  var start := Time.get_ticks_usec()
  run.pipeline.tick(run,Vector2.ZERO)
  var sim := Time.get_ticks_usec()-start
  start = Time.get_ticks_usec()
  snapshot.capture(run.enemies)
  var prep := Time.get_ticks_usec()-start
  if frame >= 20:
   total.append(sim)
   render.append(prep)
   enemy.append(run.pipeline.timings.get("enemy_us",0))
   spatial.append(run.pipeline.timings.get("spatial_us",0))
   weapons.append(run.pipeline.timings.get("weapon_us",0))
 return {"ok":run.enemies.allocations==allocations,"seed":60606,"samples":total.size(),"simulation":stats(total),"cpu_fixture_frame":stats(combine(total,render)),"render_preparation":stats(render),"enemy_update":stats(enemy),"spatial_update":stats(spatial),"weapon_update":stats(weapons),"enemy_count":run.enemies.count,"projectile_count":initial_projectiles,"gem_count":1000,"allocation_proxy":{"enemy_capacity_growth":run.enemies.allocations-allocations,"spatial_capacity_growth":run.spatial.bucket_allocations-1},"note":"Headless Linux CPU only. Effects draw calls/GPU/Windows/iPhone frame time are not measured."}
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
