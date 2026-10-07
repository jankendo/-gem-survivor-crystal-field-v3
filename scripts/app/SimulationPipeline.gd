extends RefCounted
class_name SimulationPipeline
var status := StatusSystem.new()
var enemy_sim := EnemySimulation.new()
var death := DeathSystem.new()
var level := LevelSystem.new()
var scratch := QueryBuffer.new(600)
var timings: Dictionary = {}
var profiling := false
func tick(run, direction: Vector2) -> void:
 var state: RunState = run.state
 if state.phase != "RUNNING": return
 var started := Time.get_ticks_usec()
 state.tick += 1
 if not run.warp.active: state.field_tick += 1
 death.tick(state,run.enemies,run.gems,run.damage,run.map)
 run.damage.begin_tick()
 run.damage.elite_multiplier = (1+float(state.player.stats.get("elite_damage",0)))*float(state.player.stats.get("contract_elite",1))
 run.damage.normal_multiplier = float(state.player.stats.get("contract_normal",1))
 status.tick(run.enemies,state.player,state.tick)
 var player := state.player
 var context_room: int = run.map.room_at(player.position)
 var stat := player.stats
 var move_mult := 1+float(stat.get("move",0))
 if context_room < 0:
  move_mult += float(stat.get("corridor_move",0))
  player.stats.context_damage = float(stat.get("corridor_damage",0))
  player.stats.context_armor = float(stat.get("corridor_armor",0))
  player.stats.context_area = 0
 else:
  move_mult += float(stat.get("room_move",0))
  player.stats.context_damage = 0
  player.stats.context_armor = 0
  player.stats.context_area = float(stat.get("room_area",0))
 if player.hp < player.max_hp*.3: move_mult += float(stat.get("low_hp_move",0))
 if not state.progression.rooms.has(context_room): move_mult += float(stat.get("explore_move",0))
 player.position = run.map.move(player.position,direction.limit_length() * player.speed * move_mult / 60)
 player.hp = minf(player.max_hp,player.hp + float(stat.get("regen",0)) / 60)
 if not run.warp.active:
  run.encounter.tick(state,run.db,run.map,run.enemies)
  run.encounter.boss_schedule(state,run.db,run.map,run.enemies)
 if not run.warp.active and run.pending_interact:
  run.field.interact(run)
 run.pending_interact = false
 var stamp := Time.get_ticks_usec()
 enemy_sim.move(state,run.enemies,run.map,run.db,run.damage)
 if profiling: timings["enemy_us"] = Time.get_ticks_usec() - stamp
 stamp = Time.get_ticks_usec()
 run.spatial.begin_tick()
 for n in range(run.enemies.count):
  var i: int = run.enemies.dense[n]
  run.spatial.insert(SpatialWorld.ENEMY,run.enemies.entity_id(i),run.enemies.positions[i])
 for i in range(run.gems.capacity):
  if run.gems.active[i]: run.spatial.insert(SpatialWorld.GEM,i,run.gems.positions[i])
 for i in range(run.map.portals.size()): run.spatial.insert(SpatialWorld.INTERACTABLE,i,run.map.portals[i])
 if not run.warp.active: run.field.index_spatial(run.spatial)
 for n in range(run.projectiles.count):
  var i: int = run.projectiles.dense[n]
  run.spatial.insert(SpatialWorld.PROJECTILE,i,run.projectiles.positions[i])
 if profiling: timings["spatial_us"] = Time.get_ticks_usec() - stamp
 stamp = Time.get_ticks_usec()
 run.weapons.tick(state,run.enemies,run.spatial,run.projectiles,run.damage)
 run.projectiles.tick(run.enemies,run.spatial,run.damage)
 run.combos.tick(state,run.db,run.enemies,run.spatial,run.damage)
 if profiling: timings["weapon_us"] = Time.get_ticks_usec() - stamp
 enemy_sim.contact(state,run.enemies,run.spatial,run.damage,run.db)
 death.tick(state,run.enemies,run.gems,run.damage,run.map)
 run.spatial.query_circle(SpatialWorld.GEM,player.position,float(run.db.config().magnet_radius) * (1 + float(stat.get("magnet",0))+float(stat.get("meta_magnet",0))),scratch)
 for query_index in range(scratch.count):
  var id := scratch.ids[query_index]
  var value: int = run.gems.take(id)
  if value > 0:
   level.collect(roundi(value*(1+float(stat.get("exp",0)))*float(stat.get("contract_gem",1))),state,run.db,run.unlocked)
   player.hp = minf(player.max_hp,player.hp+float(stat.get("pickup_heal",0)))
 if state.phase == "RUNNING": level.offer(state,run.db,run.unlocked)
 if int(stat.get("recall_frequency",0))>0 and state.tick % maxi(60,600-int(stat.get("recall_frequency",0))) == 0:
  run.spatial.query_circle(SpatialWorld.GEM,player.position,800,scratch)
  for query_index in range(scratch.count):
   var id := scratch.ids[query_index]
   var value: int = run.gems.take(id)
   if value>0: level.collect(roundi(value*(1+float(stat.get("exp",0)))*float(stat.get("contract_gem",1))),state,run.db,run.unlocked)
 var room: int = run.map.room_at(player.position)
 if room >= 0 and not state.progression.rooms.has(room) and not run.warp.active:
  state.progression.chain = state.progression.chain+1 if state.progression.resonance>0 else 1
  state.progression.max_chain = maxi(state.progression.max_chain,state.progression.chain)
  state.progression.rooms[room] = true
  state.progression.resonance = int(run.db.config().resonance_ticks)+int(stat.get("resonance_duration",0))
  run.gems.add(run.map.rooms[room].get_center(),20,run.map)
 state.progression.resonance = maxi(0,state.progression.resonance - 1)
 if not run.warp.active: run.field.tick(run)
 run.warp.tick(run)
 if not run.pending_contract.is_empty() and state.phase=="RUNNING": state.phase="CONTRACT"
 if profiling: timings["simulation_us"] = Time.get_ticks_usec() - started
