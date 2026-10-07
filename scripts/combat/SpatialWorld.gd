extends RefCounted
class_name SpatialWorld
# Shared bucket index: enemies, gems, hazards, interactables, projectiles.
# Each bucket is retained and cleared once per tick, never rebuilt per query.
const ENEMY := 0
const GEM := 1
const HAZARD := 2
const INTERACTABLE := 3
const PROJECTILE := 4
var cell_size := 128.0
var buckets: Dictionary = {}
var points: Dictionary = {}
var rebuilds := 0
var bucket_allocations := 0
var query_count := 0

func begin_tick() -> void:
 for b in buckets.values(): b.clear()
 points.clear()
 rebuilds += 1

func insert(kind: int, id: int, pos: Vector2) -> void:
 var key := Vector3i(int(floor(pos.x / cell_size)), int(floor(pos.y / cell_size)), kind)
 if not buckets.has(key):
  buckets[key] = []
  bucket_allocations += 1
 buckets[key].append(id)
 points[Vector2i(kind, id)] = pos

func query_aabb(kind: int, rect: Rect2, output: Array) -> void:
 output.clear()
 query_count += 1
 var lo := Vector2i(floor(rect.position / cell_size))
 var hi := Vector2i(floor(rect.end / cell_size))
 for y in range(lo.y, hi.y + 1):
  for x in range(lo.x, hi.x + 1):
   var key := Vector3i(x, y, kind)
   if not buckets.has(key): continue
   for id in buckets[key]:
    if rect.has_point(points[Vector2i(kind, id)]): output.append(id)

func query_circle(kind: int, center: Vector2, radius: float, output: Array) -> void:
 query_aabb(kind, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), output)
 var n := 0
 for id in output:
  if center.distance_squared_to(points[Vector2i(kind, id)]) <= radius * radius:
   output[n] = id
   n += 1
 output.resize(n)

func query_segment(kind: int, a: Vector2, b: Vector2, width: float, output: Array) -> void:
 query_aabb(kind, Rect2(a.min(b) - Vector2.ONE * width, (b - a).abs() + Vector2.ONE * width * 2), output)
 var n := 0
 for id in output:
  var p: Vector2 = points[Vector2i(kind, id)]
  if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) <= width:
   output[n] = id
   n += 1
 output.resize(n)

func query_nearest(kind: int, center: Vector2, radius: float, scratch: Array) -> int:
 query_circle(kind, center, radius, scratch)
 var best := -1
 var dist := INF
 for id in scratch:
  var d := center.distance_squared_to(points[Vector2i(kind, id)])
  if d < dist or (d == dist and id < best):
   best = id
   dist = d
 return best
