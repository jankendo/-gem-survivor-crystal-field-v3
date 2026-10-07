extends Node2D
class_name EffectRenderer
const CAPACITY := 128
var positions := PackedVector2Array()
var life := PackedFloat32Array()
var cursor := 0
var limit := 96
var submitted_tick := -1
func _ready() -> void:
 positions.resize(CAPACITY)
 life.resize(CAPACITY)
func present(events: PresentationEvents, tick: int, ultra: bool) -> void:
 limit = 12 if ultra else 96
 if tick == submitted_tick: return
 submitted_tick = tick
 for n in range(mini(limit,events.count)):
  cursor = (cursor+1)%limit
  positions[cursor] = events.positions[n]
  life[cursor] = .18
func _process(delta: float) -> void:
 for i in range(limit): life[i] = maxf(0,life[i]-delta)
 queue_redraw()
func _draw() -> void:
 for i in range(limit):
  if life[i] > 0: draw_arc(positions[i],6+(1-life[i]/.18)*18,0,TAU,12,Color(.5,1,1,life[i]*4),2)
