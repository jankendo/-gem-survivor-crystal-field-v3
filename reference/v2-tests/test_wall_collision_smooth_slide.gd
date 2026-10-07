extends RefCounted

const WallScript = preload("res://scripts/core/CrystalWall.gd")
const SlideScript = preload("res://scripts/systems/SmoothWallSlideSystem.gd")
const MovementScript = preload("res://scripts/systems/PlayerMovementResolver.gd")

class FlatState:
	extends RefCounted
	var field_size := Vector2(1000, 1000)
	var crystal_walls: Array = []
	var passives: Dictionary = {}
	var hp := 100
	var max_hp := 100
	var ios_physics_query_count := 0
	func is_walkable_position(_position: Vector2, _radius: float = 0.0) -> bool:
		return true
	func hp_ratio() -> float:
		return 1.0

func run(t) -> void:
	var state := FlatState.new()
	state.crystal_walls.append(WallScript.new("wall", Vector2(520, 500), Vector2(40, 320), 100, false))
	var slide = SlideScript.new()
	var result: Dictionary = slide.move(state, Vector2(470, 430), Vector2(100, 90), 18.0)
	var position: Vector2 = result.get("position", Vector2.ZERO)
	t.assert_true(bool(result.get("collided", false)), "diagonal movement should detect the wall")
	t.assert_true(position.x <= 479.1, "skin width should stop movement before wall penetration")
	t.assert_true(position.y > 430.0, "blocked horizontal motion should slide along the wall")

	var resolver = MovementScript.new()
	var previous := Vector2(470, 380)
	var x_values: Array = []
	for i in range(120):
		var moved: Dictionary = resolver.resolve(state, previous, Vector2(120, 95), 1.0 / 60.0, 18.0)
		var next: Vector2 = moved.get("position", previous)
		x_values.append(next.x)
		t.assert_true(next.y >= previous.y, "wall slide should not reverse vertical movement")
		previous = next
	var jitter := 0
	for i in range(1, x_values.size()):
		if float(x_values[i]) + 0.01 < float(x_values[i - 1]):
			jitter += 1
	t.assert_eq(jitter, 0, "wall contact should not alternate pushback direction")
	t.assert_true(state.ios_physics_query_count < 3000, "swept movement should keep collision queries bounded")
