extends Control
class_name Minimap
var rooms: Array[Rect2] = []
var discovered: Dictionary = {}
var player := Vector2.ZERO
var range_limit := 1400.0
func present(run: RunController) -> void:
 rooms = run.map.rooms
 discovered = run.state.progression.rooms
 player = run.state.player.position
 range_limit = 1400+float(run.state.player.stats.get("map_range",0))
 queue_redraw()
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color(.02,.04,.08,.85))
 var scale := size.x / 4800.0
 for n in range(rooms.size()):
  var center := rooms[n].get_center()
  if not discovered.has(n) and center.distance_to(player)>range_limit: continue
  var color := Color(.2,.7,.7,.8) if discovered.has(n) else Color(.25,.3,.4,.65)
  draw_rect(Rect2((center-player)*scale+size*.5-Vector2(8,8),Vector2(16,16)),color)
 draw_circle(size*.5,4,Color(1,.85,.3))
