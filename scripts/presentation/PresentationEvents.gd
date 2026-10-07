extends RefCounted
class_name PresentationEvents
const CAPACITY := 512
var positions := PackedVector2Array()
var kinds := PackedByteArray()
var count := 0
var dropped := 0
func _init() -> void:
 positions.resize(CAPACITY)
 kinds.resize(CAPACITY)
func clear() -> void: count = 0
func emit(pos: Vector2, kind: int) -> void:
 if count >= CAPACITY:
  dropped += 1
  return
 positions[count] = pos
 kinds[count] = kind
 count += 1
