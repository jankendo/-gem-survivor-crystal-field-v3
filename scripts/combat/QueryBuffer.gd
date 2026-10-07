extends RefCounted
class_name QueryBuffer
var ids := PackedInt64Array()
var count := 0
var capacity := 256
var allocations := 1
func _init(initial_capacity: int = 256) -> void:
 capacity = initial_capacity
 ids.resize(capacity)
func clear() -> void: count = 0
func append(id: int) -> void:
 if count==capacity:
  capacity *= 2
  ids.resize(capacity)
  allocations += 1
 ids[count] = id
 count += 1
func size() -> int: return count
func is_empty() -> bool: return count==0
func to_array() -> Array:
 var result: Array = []
 for n in range(count): result.append(ids[n])
 return result
