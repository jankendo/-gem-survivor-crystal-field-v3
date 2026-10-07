extends RefCounted
class_name WorldGenerator
const TERRAIN_INDICES := {"safe":1,"mining":2,"risk":3,"event":4,"shortcut":5}
# Connected rooms and orthogonal corridors; every spawn/pickup projects onto valid floor.
var rooms: Array[Rect2] = []
var corridors: Array[Rect2] = []
var kinds: Array[String] = []
var portals: Array[Vector2] = []
var seed_value := 0
func generate(seed_input: int) -> void:
 seed_value = seed_input
 var rng := RunRng.new()
 rng.set_seed_value(seed_input)
 rooms.clear()
 corridors.clear()
 portals.clear()
 kinds.clear()
 for y in range(5):
  for x in range(5):
   var center := Vector2(x - 2, y - 2) * 900.0
   var size := Vector2(rng.range_int(530, 700), rng.range_int(530, 700))
   rooms.append(Rect2(center - size / 2, size))
   kinds.append(["safe", "mining", "risk", "event", "shortcut"][(x + y * 2) % 5])
   if x > 0: corridors.append(Rect2(center - Vector2(900, 100), Vector2(900, 200)))
   if y > 0: corridors.append(Rect2(center - Vector2(100, 900), Vector2(200, 900)))
   if (x + y) % 3 == 0 and center.length() > 500: portals.append(center)
 kinds[12] = "safe"
func walkable(p: Vector2, margin: float = 0) -> bool:
 for rect in rooms:
  if rect.grow(-margin).has_point(p): return true
 for rect in corridors:
  if rect.grow(-margin).has_point(p): return true
 return false
func safe_position(p: Vector2, margin: float = 24) -> Vector2:
 if walkable(p, margin): return p
 var best := Vector2.ZERO
 var distance := INF
 for rect in rooms:
  var q := p.clamp(rect.position + Vector2.ONE * margin, rect.end - Vector2.ONE * margin)
  if p.distance_squared_to(q) < distance:
   best = q
   distance = p.distance_squared_to(q)
 for rect in corridors:
  var q := p.clamp(rect.position + Vector2.ONE * margin, rect.end - Vector2.ONE * margin)
  if p.distance_squared_to(q) < distance:
   best = q
   distance = p.distance_squared_to(q)
 return best
func move(p: Vector2, delta: Vector2, margin: float = 14) -> Vector2:
 var next := p + delta
 if walkable(next, margin): return next
 var slide := Vector2(next.x, p.y)
 if walkable(slide, margin): return slide
 slide = Vector2(p.x, next.y)
 return slide if walkable(slide, margin) else p
func room_at(p: Vector2) -> int:
 for i in range(rooms.size()):
  if rooms[i].has_point(p): return i
 return -1

func pursuit_target(from: Vector2, target: Vector2) -> Vector2:
 if rooms.size() != 25: return target
 var a := room_at(from)
 var b := room_at(target)
 if b < 0: return target
 if a < 0:
  var best := INF
  for n in range(rooms.size()):
   var dist := from.distance_squared_to(rooms[n].get_center())
   if dist < best:
    best = dist
    a = n
 if a==b: return target
 var center := rooms[a].get_center()
 var dx := b%5-a%5
 var dy := int(b/5)-int(a/5)
 if dx != 0:
  if absf(from.y-center.y)>55: return center
  return rooms[a+signi(dx)].get_center()
 if absf(from.x-center.x)>55: return center
 return rooms[a+signi(dy)*5].get_center()

func spawn_position(center: Vector2, minimum: float, maximum: float, rng: RunRng) -> Vector2:
 var best := safe_position(center)
 var distance := -1.0
 for attempt in range(8):
  var candidate := safe_position(center+Vector2.RIGHT.rotated(rng.range_float(0,TAU))*rng.range_float(minimum,maximum))
  var d := candidate.distance_squared_to(center)
  if d > distance:
   best = candidate
   distance = d
 return best

func terrain_index(p: Vector2) -> int:
 var room := room_at(p)
 if room<0: return 0
 return TERRAIN_INDICES.get(kinds[room],0)
