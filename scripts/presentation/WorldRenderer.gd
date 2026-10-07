extends Node2D
class_name WorldRenderer
var compass_direction := Vector2.ZERO
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
var deployed_ends := PackedVector2Array()
var deployed_positions := PackedVector2Array()
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
 compass_direction=Vector2.ZERO
 var nearest := pow(650*float(run.state.player.stats.get("char_compass_range",1)),2)
 for i in range(run.map.rooms.size()):
  if run.state.progression.rooms.has(i): continue
  var offset: Vector2=run.map.rooms[i].get_center()-player_position
  if offset.length_squared()<nearest:
   nearest=offset.length_squared()
   compass_direction=offset.normalized()
 snapshot.capture(run.enemies)
 enemy_renderer.present(snapshot)
 gem_positions.clear()
 for i in range(run.gems.capacity):
  if run.gems.active[i]: gem_positions.append(run.gems.positions[i])
 deployed_positions.resize(run.deployments.count)
 deployed_ends.resize(run.deployments.count)
 for n in range(run.deployments.count):
  var i:=run.deployments.dense[n]
  deployed_positions[n]=run.deployments.positions[i]
  deployed_ends[n]=deployed_positions[n]+run.deployments.directions[i]*run.deployments.lengths[i]
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
 position = (size * .5 - player_position) * scale
 queue_redraw()
func _draw() -> void:
 if compass_direction!=Vector2.ZERO: draw_line(player_position+compass_direction*35,player_position+compass_direction*65,Color(.3,1,.8),4)
 if meteor_warning:
  draw_circle(meteor_position,70,Color(1,.3,.1,.2))
  draw_arc(meteor_position,70,0,TAU,48,Color(1,.45,.1),3)
 if danger_event: draw_arc(danger_position,220,0,TAU,64,Color(1,.1,.2),3)
 for n in range(field_positions.size()):
  var p := field_positions[n]
  if field_textures.has(field_kinds[n]): draw_texture_rect(field_textures[field_kinds[n]],Rect2(p-Vector2(24,24),Vector2(48,48)),false)
  else:
   draw_rect(Rect2(p-Vector2(16,16),Vector2(32,32)),Color(.1,.3,.4))
   draw_rect(Rect2(p-Vector2(16,16),Vector2(32,32)),Color(.6,1,1),false,3)
 for p in gem_positions:
  if p.distance_squared_to(player_position) < 900*900: draw_circle(p,4,Color(.2,1,.9))
 for n in range(mini(deployed_positions.size(),8 if profile=="ios_ultra" else 32)):
  draw_arc(deployed_positions[n],24,0,TAU,16,Color(.4,.6,1),2)
  if deployed_positions[n]!=deployed_ends[n]: draw_line(deployed_positions[n],deployed_ends[n],Color(.6,.8,1),5)
 for p in projectile_positions:
  if p.distance_squared_to(player_position) < 900*900: draw_circle(p,4,Color(1,.85,.4))
 for p in snapshot.warnings:
  draw_circle(p,snapshot.warning_radius,Color(1,.1,.2,.2))
  draw_arc(p,snapshot.warning_radius,0,TAU,48,Color(1,.25,.2),3)
 draw_texture_rect(player_texture,Rect2(player_position-Vector2(22,22),Vector2(44,44)),false)

func configure(db: GameDatabase) -> void:
 enemy_renderer.configure(db)
 for id in db.table("field_gimmicks"):
  var path: String=str(db.table("field_gimmicks")[id].get("generated_icon",""))
  if not path.is_empty() and ResourceLoader.exists(path): field_textures[id]=load(path)
