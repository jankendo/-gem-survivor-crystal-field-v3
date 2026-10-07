extends SceneTree

const WallScript = preload("res://scripts/core/CrystalWall.gd")
const MovementScript = preload("res://scripts/systems/PlayerMovementResolver.gd")

class FlatState:
	extends RefCounted
	var field_size := Vector2(1200, 900)
	var crystal_walls: Array = []
	var passives: Dictionary = {}
	var hp := 100
	var max_hp := 100
	var ios_physics_query_count := 0
	func is_walkable_position(_position: Vector2, _radius: float = 0.0) -> bool:
		return true
	func hp_ratio() -> float:
		return 1.0

func _initialize() -> void:
	var state := FlatState.new()
	state.crystal_walls.append(WallScript.new("long-wall", Vector2(620, 450), Vector2(48, 860), 100, false))
	var resolver = MovementScript.new()
	var position := Vector2(570, 450)
	var failures: Array = []
	var backwards := 0
	for frame in range(18000):
		var ascending := frame % 1200 < 600
		var vertical := 80.0 if ascending else -80.0
		var result: Dictionary = resolver.resolve(state, position, Vector2(130, vertical), 1.0 / 60.0, 18.0)
		var next: Vector2 = result.get("position", position)
		if ascending and next.y + 0.01 < position.y:
			backwards += 1
		if not ascending and next.y - 0.01 > position.y:
			backwards += 1
		if next.x > 577.1:
			failures.append("player penetrated the wall skin during long contact")
			break
		position = next
	if backwards > 0:
		failures.append("wall slide reversed along-wall movement")
	if state.ios_physics_query_count > 420000:
		failures.append("wall collision query count exceeded the five-minute budget")
	if failures.is_empty():
		print("AutoPlay Wall Slide OK: 5 minute equivalent.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
