extends RefCounted
class_name ProjectileWorld
const CAPACITY := 4096
var positions := PackedVector2Array()
var previous := PackedVector2Array()
var velocities := PackedVector2Array()
var damage := PackedFloat64Array()
var life := PackedInt32Array()
var sources := PackedStringArray()
var dense := PackedInt32Array()
var free_slots := PackedInt32Array()
var count := 0
var free_count := CAPACITY
var scratch: Array = []
func _init() -> void:
 positions.resize(CAPACITY)
 previous.resize(CAPACITY)
 velocities.resize(CAPACITY)
 damage.resize(CAPACITY)
 life.resize(CAPACITY)
 sources.resize(CAPACITY)
 dense.resize(CAPACITY)
 free_slots.resize(CAPACITY)
 for i in range(CAPACITY): free_slots[i] = CAPACITY - 1 - i
func add(pos: Vector2, velocity: Vector2, amount: float, source: String) -> bool:
 if free_count == 0: return false
 free_count -= 1
 var i := free_slots[free_count]
 positions[i] = pos
 previous[i] = pos
 velocities[i] = velocity
 damage[i] = amount
 sources[i] = source
 life[i] = 120
 dense[count] = i
 count += 1
 return true
func remove_at(n: int) -> void:
 var i := dense[n]
 count -= 1
 dense[n] = dense[count]
 free_slots[free_count] = i
 free_count += 1
func tick(enemies: EnemyWorld, spatial: SpatialWorld, damage_system: DamageSystem) -> void:
 for n in range(count - 1, -1, -1):
  var i := dense[n]
  previous[i] = positions[i]
  positions[i] += velocities[i] / 60.0
  life[i] -= 1
  spatial.query_segment(SpatialWorld.ENEMY, previous[i], positions[i], 65, scratch)
  var hit := false
  for id in scratch:
   if not enemies.alive(id): continue
   var slot := enemies.slot(id)
   var nearest := Geometry2D.get_closest_point_to_segment(enemies.positions[slot], previous[i], positions[i])
   if nearest.distance_to(enemies.positions[slot]) <= enemies.radius[slot] + 5:
    damage_system.apply(enemies, id, damage[i], sources[i])
    hit = true
    break
  if hit or life[i] <= 0: remove_at(n)
