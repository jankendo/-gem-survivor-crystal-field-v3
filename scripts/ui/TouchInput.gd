extends Control
class_name TouchInput
var direction := Vector2.ZERO
var finger := -1
var origin := Vector2.ZERO
var current := Vector2.ZERO
func _input(event: InputEvent) -> void:
 var safe := SafeArea.new().logical_rect(get_viewport_rect().size,Vector2(DisplayServer.window_get_size()),DisplayServer.get_display_safe_area()) if OS.has_feature("ios") else Rect2(Vector2.ONE*16,get_viewport_rect().size-Vector2.ONE*32)
 if event is InputEventScreenTouch:
  if event.pressed and finger < 0 and event.position.x < get_viewport_rect().size.x * .55 and safe.has_point(event.position):
   finger = event.index
   origin = event.position
   current = origin
  elif not event.pressed and event.index == finger:
   finger = -1
   direction = Vector2.ZERO
 if event is InputEventScreenDrag and event.index == finger:
  current = event.position
  direction = ((current-origin)/65).limit_length()
 queue_redraw()
func _draw() -> void:
 if finger < 0: return
 draw_circle(origin,65,Color(.1,.8,1,.12))
 draw_arc(origin,65,0,TAU,32,Color(.4,.9,1,.65),2)
 draw_circle(origin+direction*65,22,Color(.4,.9,1,.5))

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
  finger = -1
  direction = Vector2.ZERO
