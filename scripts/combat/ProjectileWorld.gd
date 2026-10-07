extends RefCounted
class_name ProjectileWorld
const CAPACITY := 4096
var bounces := PackedInt32Array()
var homing := PackedByteArray()
var statuses := PackedInt32Array()
var positions := PackedVector2Array()
var previous := PackedVector2Array()
var velocities := PackedVector2Array()
var damage := PackedFloat64Array()
var life := PackedInt32Array()
var sources := PackedStringArray()
var dense := PackedInt32Array()
var free_slots := PackedInt32Array()
var remaining_hits := PackedInt32Array()
var seen_count := PackedInt32Array()
var seen_ids := PackedInt64Array()
var count := 0
var free_count := CAPACITY
var scratch := QueryBuffer.new(600)
func _init() -> void:
 bounces.resize(CAPACITY)
 homing.resize(CAPACITY)
 statuses.resize(CAPACITY)
 remaining_hits.resize(CAPACITY)
 seen_count.resize(CAPACITY)
 seen_ids.resize(CAPACITY*8)
 positions.resize(CAPACITY)
 previous.resize(CAPACITY)
 velocities.resize(CAPACITY)
 damage.resize(CAPACITY)
 life.resize(CAPACITY)
 sources.resize(CAPACITY)
 dense.resize(CAPACITY)
 free_slots.resize(CAPACITY)
 for i in range(CAPACITY): free_slots[i] = CAPACITY - 1 - i
func add(pos: Vector2, velocity: Vector2, amount: float, source: String, pierce: int = 0, bounce: int = 0, seeking: bool = false, status: int = 0) -> bool:
 if free_count == 0: return false
 free_count -= 1
 var i := free_slots[free_count]
 bounces[i]=bounce
 homing[i]=int(seeking)
 statuses[i]=status
 positions[i] = pos
 previous[i] = pos
 velocities[i] = velocity
 damage[i] = amount
 sources[i] = source
 life[i] = 120
 remaining_hits[i] = mini(8,pierce+1)
 seen_count[i] = 0
 dense[count] = i
 count += 1
 return true
func remove_at(n: int) -> void:
 var i := dense[n]
 count -= 1
 dense[n] = dense[count]
 free_slots[free_count] = i
 free_count += 1
func tick(enemies: EnemyWorld, spatial: SpatialWorld, damage_system: DamageSystem,map: WorldGenerator = null) -> void:
 for n in range(count - 1, -1, -1):
  var i := dense[n]
  if homing[i] and life[i]%6==0:
   var nearest_id:=spatial.query_nearest(SpatialWorld.ENEMY,positions[i],500,scratch)
   if nearest_id>=0 and enemies.alive(nearest_id): velocities[i]=velocities[i].lerp((enemies.positions[enemies.slot(nearest_id)]-positions[i]).normalized()*velocities[i].length(),.35)
  previous[i] = positions[i]
  positions[i] += velocities[i] / 60.0
  if bounces[i]>0 and map!=null and not map.walkable(positions[i],4):
   var dx:=Vector2(positions[i].x,previous[i].y)
   var dy:=Vector2(previous[i].x,positions[i].y)
   if not map.walkable(dx,4): velocities[i].x *= -1
   if not map.walkable(dy,4): velocities[i].y *= -1
   positions[i]=previous[i]
   bounces[i]-=1
  life[i] -= 1
  var width := minf(85,enemies.maximum_radius+5.01)
  spatial.query_segment(SpatialWorld.ENEMY, previous[i], positions[i], width, scratch)
  var hit := false
  for query_index in range(scratch.count):
   var id := scratch.ids[query_index]
   if not enemies.alive(id): continue
   if enemies.hp[enemies.slot(id)] <= 0: continue
   var repeated := false
   for k in range(seen_count[i]):
    if seen_ids[i*8+k] == id: repeated = true
   if repeated: continue
   var slot := enemies.slot(id)
   var nearest := Geometry2D.get_closest_point_to_segment(enemies.positions[slot], previous[i], positions[i])
   if nearest.distance_to(enemies.positions[slot]) <= enemies.radius[slot] + 5:
    damage_system.apply(enemies, id, damage[i], sources[i])
    if statuses[i]==1: enemies.slow[slot]=90
    elif statuses[i]==2: enemies.shock[slot]=90
    elif statuses[i]==3: enemies.poison[slot]=180
    seen_ids[i*8+seen_count[i]] = id
    seen_count[i] += 1
    remaining_hits[i] -= 1
    hit = remaining_hits[i] == 0
    if hit: break
  if hit or life[i] <= 0: remove_at(n)
