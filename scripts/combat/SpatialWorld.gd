extends RefCounted
class_name SpatialWorld
const ENEMY := 0
const GEM := 1
const HAZARD := 2
const INTERACTABLE := 3
const PROJECTILE := 4
const SIDE := 64
const LAYERS := 5
const CELL_COUNT := SIDE * SIDE * LAYERS
var cell_size := 128.0
var heads := PackedInt32Array()
var next := PackedInt32Array()
var ids := PackedInt64Array()
var positions := PackedVector2Array()
var touched := PackedInt32Array()
var touched_count := 0
var count := 0
var capacity := 16384
var rebuilds := 0
var bucket_allocations := 1
var query_count := 0
func _init() -> void:
 heads.resize(CELL_COUNT)
 heads.fill(-1)
 touched.resize(CELL_COUNT)
 next.resize(capacity)
 ids.resize(capacity)
 positions.resize(capacity)
func cell(p: Vector2) -> Vector2i:
 return Vector2i(clampi(floori(p.x / cell_size) + SIDE/2,0,SIDE-1),clampi(floori(p.y / cell_size) + SIDE/2,0,SIDE-1))
func begin_tick() -> void:
 for n in range(touched_count): heads[touched[n]] = -1
 touched_count = 0
 count = 0
 rebuilds += 1
func insert(kind: int, id: int, pos: Vector2) -> void:
 if count == capacity:
  capacity *= 2
  next.resize(capacity)
  ids.resize(capacity)
  positions.resize(capacity)
  bucket_allocations += 1
 var c := cell(pos)
 var h := kind * SIDE * SIDE + c.y * SIDE + c.x
 if heads[h] == -1:
  touched[touched_count] = h
  touched_count += 1
 ids[count] = id
 positions[count] = pos
 next[count] = heads[h]
 heads[h] = count
 count += 1
func query_aabb(kind: int, rect: Rect2, output: QueryBuffer) -> void:
 query(kind,rect,Vector2.ZERO,Vector2.ZERO,-1,-1,output)
func query_circle(kind: int, center: Vector2, radius: float, output: QueryBuffer) -> void:
 query(kind,Rect2(center-Vector2.ONE*radius,Vector2.ONE*radius*2),center,Vector2.ZERO,radius,-1,output)
func query_segment(kind: int, a: Vector2, b: Vector2, width: float, output: QueryBuffer) -> void:
 query(kind,Rect2(a.min(b)-Vector2.ONE*width,(b-a).abs()+Vector2.ONE*width*2),a,b,-1,width,output)
func query(kind: int, rect: Rect2, a: Vector2, b: Vector2, radius: float, width: float, output: QueryBuffer) -> void:
 output.clear()
 query_count += 1
 var lo := cell(rect.position)
 var hi := cell(rect.end)
 for y in range(lo.y,hi.y+1):
  for x in range(lo.x,hi.x+1):
   var n := heads[kind*SIDE*SIDE+y*SIDE+x]
   while n >= 0:
    var p := positions[n]
    var valid := rect.has_point(p)
    if radius >= 0: valid = valid and a.distance_squared_to(p) <= radius*radius
    if width >= 0: valid = valid and p.distance_squared_to(Geometry2D.get_closest_point_to_segment(p,a,b)) <= width*width
    if valid: output.append(ids[n])
    n = next[n]
func query_nearest(kind: int, center: Vector2, radius: float, scratch: QueryBuffer) -> int:
 # Nearest uses the same index directly; scratch is part of public reusable-buffer contract.
 scratch.clear()
 query_count += 1
 var lo := cell(center-Vector2.ONE*radius)
 var hi := cell(center+Vector2.ONE*radius)
 var best := -1
 var distance := radius*radius
 for y in range(lo.y,hi.y+1):
  for x in range(lo.x,hi.x+1):
   var n := heads[kind*SIDE*SIDE+y*SIDE+x]
   while n >= 0:
    var d := center.distance_squared_to(positions[n])
    if d < distance or (d == distance and (best < 0 or ids[n] < best)):
     distance = d
     best = ids[n]
    n = next[n]
 return best
