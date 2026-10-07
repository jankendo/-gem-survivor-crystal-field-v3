extends RefCounted
class_name SimulationPipeline
var status := StatusSystem.new()
var enemy_sim := EnemySimulation.new()
var death := DeathSystem.new()
var level := LevelSystem.new()
var scratch: Array = []
var timings: Dictionary = {}
var profiling := false
func tick(run, direction: Vector2) -> void:
 var state: RunState = run.state
 if state.phase != "RUNNING": return
 var started := Time.get_ticks_usec()
 state.tick += 1
 if not run.warp.active: state.field_tick += 1
 run.damage.begin_tick()
 status.tick(run.enemies,state.player,state.tick)
 var player := state.player
 player.position = run.map.move(player.position,direction.limit_length() * player.speed * (1 + .06 * int(state.progression.passives.get("move_speed",0))) / 60)
 player.hp = minf(player.max_hp,player.hp + float(run.db.config().regen_per_level) * int(state.progression.passives.get("regen",0)) / 60)
 if not run.warp.active:
  run.encounter.tick(state,run.db,run.map,run.enemies)
  run.encounter.boss_schedule(state,run.db,run.map,run.enemies)
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
 if profiling: timings["spatial_us"] = Time.get_ticks_usec() - stamp
 stamp = Time.get_ticks_usec()
 run.weapons.tick(state,run.enemies,run.spatial,run.projectiles,run.damage)
 run.projectiles.tick(run.enemies,run.spatial,run.damage)
 run.combos.tick(state,run.db,run.enemies,run.spatial,run.damage)
 if profiling: timings["weapon_us"] = Time.get_ticks_usec() - stamp
 enemy_sim.contact(state,run.enemies,run.spatial,run.damage,run.db)
 death.tick(state,run.enemies,run.gems,run.damage,run.map)
 run.spatial.query_circle(SpatialWorld.GEM,player.position,float(run.db.config().magnet_radius) * (1 + .15 * int(state.progression.passives.get("magnet",0))),scratch)
 for id in scratch:
  var value: int = run.gems.take(id)
  if value > 0: level.collect(value,state,run.db,run.unlocked)
 if state.phase == "RUNNING": level.offer(state,run.db,run.unlocked)
 var room: int = run.map.room_at(player.position)
 if room >= 0 and not state.progression.rooms.has(room) and not run.warp.active:
  state.progression.rooms[room] = true
  state.progression.resonance = int(run.db.config().resonance_ticks)
  run.gems.add(run.map.rooms[room].get_center(),20,run.map)
 state.progression.resonance = maxi(0,state.progression.resonance - 1)
 run.warp.tick(run)
 if profiling: timings["simulation_us"] = Time.get_ticks_usec() - started
