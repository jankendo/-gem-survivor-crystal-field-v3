extends RefCounted
class_name EnemyWorld
# Generation is encoded above the low 20 slot bits. Dense list never allocates in iteration.
const SLOT_BITS := 20
const SLOT_MASK := (1 << SLOT_BITS) - 1
var positions := PackedVector2Array()
var velocities := PackedVector2Array()
var hp := PackedFloat64Array()
var max_hp := PackedFloat64Array()
var radius := PackedFloat32Array()
var speed := PackedFloat32Array()
var damage := PackedFloat32Array()
var xp := PackedInt32Array()
var types := PackedInt32Array()
var flags := PackedInt32Array()
var generation := PackedInt64Array()
var sparse := PackedInt32Array()
var dense := PackedInt32Array()
var free_slots := PackedInt32Array()
var contact := PackedInt32Array()
var shock := PackedInt32Array()
var poison := PackedInt32Array()
var periodic := PackedInt32Array()
var slow := PackedInt32Array()
var action := PackedInt32Array()
var warning := PackedInt32Array()
var attack_target := PackedVector2Array()
var count := 0
var capacity := 0
var free_count := 0
var reused := 0
var allocations := 0

func _init(initial_capacity: int = 600) -> void:
 reserve(initial_capacity)

func reserve(size: int) -> void:
 var old := capacity
 capacity = maxi(size, capacity)
 positions.resize(capacity)
 velocities.resize(capacity)
 hp.resize(capacity)
 max_hp.resize(capacity)
 radius.resize(capacity)
 speed.resize(capacity)
 damage.resize(capacity)
 xp.resize(capacity)
 types.resize(capacity)
 flags.resize(capacity)
 generation.resize(capacity)
 sparse.resize(capacity)
 dense.resize(capacity)
 free_slots.resize(capacity)
 contact.resize(capacity)
 shock.resize(capacity)
 poison.resize(capacity)
 periodic.resize(capacity)
 slow.resize(capacity)
 action.resize(capacity)
 warning.resize(capacity)
 attack_target.resize(capacity)
 for i in range(capacity - 1, old - 1, -1):
  sparse[i] = -1
  generation[i] = 1
  free_slots[free_count] = i
  free_count += 1
 allocations += 1

func spawn(type_id: int, pos: Vector2, definition: Dictionary, health_scale: float = 1.0, boss: bool = false) -> int:
 if free_count == 0: return -1
 free_count -= 1
 var i := free_slots[free_count]
 reused += int(generation[i] > 1)
 positions[i] = pos
 velocities[i] = Vector2.ZERO
 hp[i] = float(definition.get("hp", 4)) * health_scale
 max_hp[i] = hp[i]
 radius[i] = float(definition.get("radius", 18))
 speed[i] = float(definition.get("speed", 68))
 damage[i] = float(definition.get("damage", 8))
 xp[i] = int(definition.get("exp", 5))
 types[i] = type_id
 flags[i] = (1 if boss else 0) | (2 if definition.get("elite", false) else 0)
 contact[i] = 0
 shock[i] = 0
 poison[i] = 0
 periodic[i] = 0
 slow[i] = 0
 action[i] = 180
 warning[i] = 0
 dense[count] = i
 sparse[i] = count
 count += 1
 return entity_id(i)

func entity_id(i: int) -> int: return (generation[i] << SLOT_BITS) | i
func slot(id: int) -> int: return id & SLOT_MASK
func alive(id: int) -> bool:
 if id < 0: return false
 var i := slot(id)
 return i < capacity and sparse[i] >= 0 and generation[i] == (id >> SLOT_BITS)

func remove(id: int) -> bool:
 if not alive(id): return false
 var i := slot(id)
 count -= 1
 var moved := dense[count]
 dense[sparse[i]] = moved
 sparse[moved] = sparse[i]
 sparse[i] = -1
 generation[i] += 1
 free_slots[free_count] = i
 free_count += 1
 return true
