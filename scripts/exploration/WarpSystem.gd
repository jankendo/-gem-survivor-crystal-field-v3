extends RefCounted
class_name WarpSystem
var active := false
var elapsed := 0
var room_type := "normal"
var suspended: Dictionary = {}
var stream := RunRng.new()
var visits := 0
func choose(seed_value: int, visit: int, db: GameDatabase) -> String:
 var rng := RunRng.new()
 rng.set_seed_value(seed_value)
 var child = rng.stream_rng("warp",visit)
 var weighted: Array = []
 for id in db.table("warp_rooms").type_weights: weighted.append({"id":id,"weight":db.table("warp_rooms").type_weights[id]})
 return str(child.weighted_choice(weighted).id)
func enter(run, portal_index: int) -> bool:
 if active: return false
 visits += 1
 room_type = choose(run.state.seed_value,visits,run.db)
 stream = run.state.rng.stream_rng("warp",visits)
 suspended = {"enemies":run.enemies,"gems":run.gems,"projectiles":run.projectiles,"map":run.map,"position":run.state.player.position,"rng":run.state.rng,"budget":run.encounter.budget,"threat":run.encounter.threat}
 run.enemies = EnemyWorld.new()
 run.gems = PickupWorld.new()
 run.projectiles = ProjectileWorld.new()
 run.map = WorldGenerator.new()
 run.map.rooms = [Rect2(-650,-400,1300,800)]
 run.map.kinds = ["risk"]
 run.state.player.position = Vector2.ZERO
 run.state.rng = stream
 var type_data: Dictionary = run.db.table("warp_rooms").types[room_type]
 for wave in type_data.waves:
  for entry in wave.enemies:
   var index: int = run.db.enemy_index(entry.type)
   if index < 0: continue
   for n in range(int(entry.count)):
    run.enemies.spawn(index, run.map.safe_position(Vector2(stream.range_float(-600,600),stream.range_float(-360,360))), run.db.enemy_defs[index],float(type_data.enemy_hp_multiplier))
 active = true
 elapsed = 0
 return portal_index >= 0
func tick(run) -> void:
 if not active: return
 elapsed += 1
 if run.enemies.count == 0:
  var reward: Dictionary = run.db.table("warp_rooms").types[room_type].reward
  run.state.progression.currency += int(reward.score) / 10
  run.state.progression.exp += int(reward.exp)
  leave(run)
 elif elapsed >= int(run.db.config().warp_duration_ticks): leave(run)
func leave(run) -> void:
 if not active: return
 run.enemies = suspended.enemies
 run.gems = suspended.gems
 run.projectiles = suspended.projectiles
 run.map = suspended.map
 run.state.player.position = suspended.position + Vector2(80,0)
 run.state.rng = suspended.rng
 run.encounter.budget = suspended.budget
 run.encounter.threat = suspended.threat
 suspended.clear()
 active = false
