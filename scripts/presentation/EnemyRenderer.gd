extends MultiMeshInstance2D
class_name EnemyRenderer
func _ready() -> void:
 multimesh = MultiMesh.new()
 multimesh.transform_format = MultiMesh.TRANSFORM_2D
 multimesh.use_colors = true
 var quad := QuadMesh.new()
 quad.size = Vector2.ONE
 multimesh.mesh = quad
 multimesh.instance_count = 600
 multimesh.visible_instance_count = 0
 texture = load("res://assets/generated/enemies/slime.svg")
func present(snapshot: RenderSnapshot) -> void:
 multimesh.visible_instance_count = snapshot.count
 for n in range(snapshot.count):
  var transform := Transform2D(0,snapshot.positions[n])
  transform.x *= snapshot.sizes[n]
  transform.y *= snapshot.sizes[n]
  multimesh.set_instance_transform_2d(n,transform)
  multimesh.set_instance_color(n,snapshot.colors[n])
