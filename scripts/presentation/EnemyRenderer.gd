extends Node2D
class_name EnemyRenderer
var buckets: Array[MultiMeshInstance2D] = []
var counts := PackedInt32Array()
var normal_types := 0
func configure(db: GameDatabase) -> void:
 normal_types = db.enemy_ids.size()
 for id in db.enemy_ids: add_bucket(db.table("enemies")[id].get("generated_sprite","res://assets/generated/enemies/slime.svg"))
 for id in db.table("bosses"): add_bucket(db.table("bosses")[id].generated_sprite)
 counts.resize(buckets.size())
func add_bucket(path: String) -> void:
 var node := MultiMeshInstance2D.new()
 node.multimesh = MultiMesh.new()
 node.multimesh.transform_format = MultiMesh.TRANSFORM_2D
 node.multimesh.use_colors = true
 var quad := QuadMesh.new()
 quad.size = Vector2.ONE
 node.multimesh.mesh = quad
 node.multimesh.instance_count = 600
 node.multimesh.visible_instance_count = 0
 node.texture = load(path)
 add_child(node)
 buckets.append(node)
func present(snapshot: RenderSnapshot) -> void:
 counts.fill(0)
 for n in range(snapshot.count):
  var bucket := snapshot.types[n] if snapshot.types[n] >= 0 else normal_types + mini(-snapshot.types[n]-1,buckets.size()-normal_types-1)
  if bucket < 0 or bucket >= buckets.size(): continue
  var mesh := buckets[bucket].multimesh
  var index := counts[bucket]
  counts[bucket] += 1
  var transform := Transform2D(0,snapshot.positions[n])
  transform.x *= snapshot.sizes[n]
  transform.y *= snapshot.sizes[n]
  mesh.set_instance_transform_2d(index,transform)
  mesh.set_instance_color(index,snapshot.colors[n])
 for b in range(buckets.size()): buckets[b].multimesh.visible_instance_count = counts[b]
