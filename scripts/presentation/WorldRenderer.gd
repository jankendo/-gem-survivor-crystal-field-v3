extends Node2D
class_name WorldRenderer
var snapshot := RenderSnapshot.new()
var enemy_renderer: EnemyRenderer
var player_position := Vector2.ZERO
var player_texture: Texture2D
var gem_positions := PackedVector2Array()
var projectile_positions := PackedVector2Array()
var room_rects: Array[Rect2] = []
var corridor_rects: Array[Rect2] = []
var room_kinds: Array[String] = []
var portals: Array[Vector2] = []
var profile := "desktop_standard"
var camera_size := Vector2(1280,720)
func _ready() -> void:
 enemy_renderer = EnemyRenderer.new()
 add_child(enemy_renderer)
 player_texture = load("res://assets/generated/characters/noah.svg")
func present(run: RunController, size: Vector2) -> void:
 camera_size = size
 player_position = run.state.player.position
 snapshot.capture(run.enemies)
 enemy_renderer.present(snapshot)
 gem_positions.clear()
 for i in range(run.gems.capacity):
  if run.gems.active[i]: gem_positions.append(run.gems.positions[i])
 projectile_positions.resize(run.projectiles.count)
 for n in range(run.projectiles.count): projectile_positions[n] = run.projectiles.positions[run.projectiles.dense[n]]
 room_rects = run.map.rooms
 corridor_rects = run.map.corridors
 room_kinds = run.map.kinds
 portals = run.map.portals
 position = size * .5 - player_position
 queue_redraw()
func _draw() -> void:
 for rect in corridor_rects: draw_rect(rect,Color(.045,.08,.12))
 for n in range(room_rects.size()):
  var rect := room_rects[n]
  var color := Color(.055,.12,.15)
  if room_kinds[n] == "risk": color = Color(.14,.045,.08)
  if room_kinds[n] == "safe": color = Color(.04,.14,.13)
  draw_rect(rect,color)
  draw_rect(rect,Color(.2,.4,.5),false,3)
 for portal in portals:
  draw_arc(portal,32,0,TAU,32,Color(.7,.4,1),4)
 for p in gem_positions:
  if p.distance_squared_to(player_position) < 900*900: draw_circle(p,4,Color(.2,1,.9))
 for p in projectile_positions:
  if p.distance_squared_to(player_position) < 900*900: draw_circle(p,4,Color(1,.85,.4))
 for p in snapshot.warnings:
  draw_circle(p,snapshot.warning_radius,Color(1,.1,.2,.2))
  draw_arc(p,snapshot.warning_radius,0,TAU,48,Color(1,.25,.2),3)
 draw_texture_rect(player_texture,Rect2(player_position-Vector2(22,22),Vector2(44,44)),false)
