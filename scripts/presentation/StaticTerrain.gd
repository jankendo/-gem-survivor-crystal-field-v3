extends Node2D
class_name StaticTerrain
var rooms: Array[Rect2] = []
var corridors: Array[Rect2] = []
var kinds: Array[String] = []
var portals: Array[Vector2] = []
var cache_key := 0
var floor_texture: Texture2D
var mining_texture: Texture2D
func _ready() -> void:
 floor_texture = load("res://assets/v2/environment/star_plain/floor_albedo.png")
 mining_texture = load("res://assets/v2/environment/red_mine/floor_albedo.png")
func present(map: WorldGenerator) -> void:
 var key := [map.seed_value,map.rooms,map.corridors,map.portals].hash()
 if key == cache_key: return
 cache_key = key
 rooms = map.rooms
 corridors = map.corridors
 kinds = map.kinds
 portals = map.portals
 queue_redraw()
func _draw() -> void:
 for rect in corridors: draw_rect(rect,Color(.045,.08,.12))
 for n in range(rooms.size()):
  var rect := rooms[n]
  var texture := mining_texture if kinds[n]=="mining" else floor_texture
  draw_texture_rect(texture,rect,true,Color(.65,.65,.65))
  if kinds[n]=="risk": draw_rect(rect,Color(.7,.04,.06,.18))
  draw_rect(rect,Color(.2,.4,.5),false,3)
 for portal in portals: draw_arc(portal,32,0,TAU,32,Color(.7,.4,1),4)
