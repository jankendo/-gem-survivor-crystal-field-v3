extends RefCounted
class_name PickupWorld
var positions := PackedVector2Array()
var values := PackedInt32Array()
var active := PackedInt32Array()
var count := 0
var capacity := 0
var free_slots: Array[int] = []
func _init() -> void: reserve(1024)
func reserve(size: int) -> void:
 var old := capacity
 capacity = size
 positions.resize(size)
 values.resize(size)
 active.resize(size)
 for i in range(size - 1, old - 1, -1): free_slots.append(i)
func add(pos: Vector2, value: int, map: WorldGenerator) -> int:
 if free_slots.is_empty(): reserve(capacity * 2)
 var i: int = free_slots.pop_back()
 positions[i] = map.safe_position(pos)
 values[i] = value
 active[i] = 1
 count += 1
 return i
func take(i: int) -> int:
 if active[i] == 0: return 0
 active[i] = 0
 free_slots.append(i)
 count -= 1
 return values[i]
