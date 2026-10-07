extends RefCounted
class_name PickupWorld
var positions := PackedVector2Array()
var values := PackedInt32Array()
var active := PackedInt32Array()
var count := 0
var capacity := 0
var allocations := 0
var magnetized := PackedInt32Array()
var magnet_sparse := PackedInt32Array()
var magnet_count := 0
var free_slots: Array[int] = []
func _init() -> void: reserve(1024)
func reserve(size: int) -> void:
 allocations+=1
 var old := capacity
 capacity = size
 positions.resize(size)
 values.resize(size)
 active.resize(size)
 magnetized.resize(size)
 magnet_sparse.resize(size)
 for i in range(old,size): magnet_sparse[i]=-1
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
 unmagnetize(i)
 active[i] = 0
 free_slots.append(i)
 count -= 1
 return values[i]

func magnetize(i: int) -> void:
 if i<0 or i>=capacity or not active[i] or magnet_sparse[i]>=0: return
 magnet_sparse[i]=magnet_count
 magnetized[magnet_count]=i
 magnet_count+=1
func unmagnetize(i: int) -> void:
 var n := magnet_sparse[i]
 if n<0: return
 magnet_count-=1
 var tail:=magnetized[magnet_count]
 magnetized[n]=tail
 magnet_sparse[tail]=n
 magnet_sparse[i]=-1
func tick_magnets(player: Vector2,map: WorldGenerator) -> void:
 for n in range(magnet_count):
  var i:=magnetized[n]
  var delta := (player-positions[i]).limit_length(6)
  positions[i]=map.move(positions[i],delta,4)
