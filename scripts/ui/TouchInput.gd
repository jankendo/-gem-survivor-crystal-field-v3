extends Control
class_name TouchInput
var direction := Vector2.ZERO
var finger := -1
var origin := Vector2.ZERO
var current := Vector2.ZERO
var enabled := false
var safe_rect := Rect2()
var blocked: Callable
const RADIUS := 65.0
const DEADZONE := .12
func cancel() -> void:
 finger = -1
 direction = Vector2.ZERO
 queue_redraw()
func set_enabled(value: bool) -> void:
 if enabled == value: return
 enabled = value
 if not enabled: cancel()
func _input(event: InputEvent) -> void:
 if not enabled: return
 if event is InputEventScreenTouch:
  if event.index == finger and (not event.pressed or event.canceled):
   cancel()
   return
  if event.pressed and not event.canceled and finger < 0 and safe_rect.has_point(event.position) and event.position.x < get_viewport_rect().size.x*.55:
   if blocked.is_valid() and blocked.call(event.position): return
   finger = event.index
   origin = event.position
   current = origin
   direction = Vector2.ZERO
 elif event is InputEventScreenDrag and event.index == finger:
  current = event.position
  var raw := (current-origin)/RADIUS
  direction = Vector2.ZERO if raw.length()<=DEADZONE else raw.normalized()*minf(1,(raw.length()-DEADZONE)/(1-DEADZONE))
  queue_redraw()
func _draw() -> void:
 if finger < 0 or not enabled: return
 draw_circle(origin,RADIUS,Color(.1,.8,1,.12))
 draw_arc(origin,RADIUS,0,TAU,32,Color(.4,.9,1,.65),2)
 draw_circle(origin+direction*RADIUS,22,Color(.4,.9,1,.5))
func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_WINDOW_FOCUS_OUT]: cancel()
