extends Node2D
class_name WorldRenderer
var effects: EffectRenderer
var terrain: StaticTerrain
var field_positions := PackedVector2Array()
var field_textures: Dictionary = {}
var field_kinds := PackedStringArray()
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
var meteor_warning := false
var meteor_position := Vector2.ZERO
var danger_event := false
var danger_position := Vector2.ZERO
var camera_size := Vector2(1280,720)
func _ready() -> void:
 terrain = StaticTerrain.new()
 terrain.z_index = -10
 add_child(terrain)
 enemy_renderer = EnemyRenderer.new()
 enemy_renderer.z_index = -1
 add_child(enemy_renderer)
 effects = EffectRenderer.new()
 effects.z_index = 2
 add_child(effects)
 player_texture = load("res://assets/generated/characters/noah.svg")
func present(run: RunController, size: Vector2) -> void:
 effects.present(run.damage.presentation,run.state.tick,profile=="ios_ultra")
 meteor_warning = not run.warp.active and run.field.events.impact_tick>run.state.field_tick
 meteor_position = run.field.events.impact_position
 danger_event = not run.warp.active and run.field.event=="danger_bloom"
 if danger_event: danger_position=run.map.rooms[run.field.event_room].get_center()
 camera_size = size
 player_position = run.state.player.position
 snapshot.capture(run.enemies)
 enemy_renderer.present(snapshot)
 gem_positions.clear()
 for i in range(run.gems.capacity):
  if run.gems.active[i]: gem_positions.append(run.gems.positions[i])
 projectile_positions.resize(run.projectiles.count)
 for n in range(run.projectiles.count): projectile_positions[n] = run.projectiles.positions[run.projectiles.dense[n]]
 terrain.present(run.map)
 field_positions.clear()
 field_kinds.clear()
 if not run.warp.active:
  for i in range(run.field.positions.size()):
   if run.field.active[i]:
    field_positions.append(run.field.positions[i])
    field_kinds.append(run.field.kinds[i])
 room_rects = run.map.rooms
 corridor_rects = run.map.corridors
 room_kinds = run.map.kinds
 portals = run.map.portals
 position = size * .5 - player_position
 queue_redraw()
func _draw() -> void:
 if meteor_warning:
  draw_circle(meteor_position,70,Color(1,.3,.1,.2))
  draw_arc(meteor_position,70,0,TAU,48,Color(1,.45,.1),3)
 if danger_event: draw_arc(danger_position,220,0,TAU,64,Color(1,.1,.2),3)
 for n in range(field_positions.size()):
  var p := field_positions[n]
  if field_textures.has(field_kinds[n]): draw_texture_rect(field_textures[field_kinds[n]],Rect2(p-Vector2(24,24),Vector2(48,48)),false)
 for p in gem_positions:
  if p.distance_squared_to(player_position) < 900*900: draw_circle(p,4,Color(.2,1,.9))
 for p in projectile_positions:
  if p.distance_squared_to(player_position) < 900*900: draw_circle(p,4,Color(1,.85,.4))
 for p in snapshot.warnings:
  draw_circle(p,snapshot.warning_radius,Color(1,.1,.2,.2))
  draw_arc(p,snapshot.warning_radius,0,TAU,48,Color(1,.25,.2),3)
 draw_texture_rect(player_texture,Rect2(player_position-Vector2(22,22),Vector2(44,44)),false)

func configure(db: GameDatabase) -> void:
 enemy_renderer.configure(db)
 for id in db.table("field_gimmicks"): field_textures[id] = load(db.table("field_gimmicks")[id].generated_icon)
