extends RefCounted
class_name EnemySimulation
var scratch := QueryBuffer.new(600)
func move(state: RunState, enemies: EnemyWorld, map: WorldGenerator, db: GameDatabase, damage: DamageSystem) -> void:
 for n in range(enemies.count):
  var i := enemies.dense[n]
  if enemies.hp[i]<=0: continue
  var direction := (map.pursuit_target(enemies.positions[i],state.player.position) - enemies.positions[i]).normalized()
  var speed: float = enemies.speed[i] * (.52 if enemies.slow[i] > 0 else 1)
  if enemies.shock[i]>0: speed=0
  if enemies.behaviors[i]==1:
   if enemies.action[i]==0:
    enemies.action[i] = 180
    enemies.warning[i] = 45
    enemies.attack_target[i] = state.player.position
   if enemies.warning[i]>0: speed *= .2
   elif enemies.action[i]>105:
    direction = (enemies.attack_target[i]-enemies.positions[i]).normalized()
    speed *= 2.2
  if enemies.behaviors[i]==2:
   if enemies.action[i]>90: enemies.flags[i] |= 8
   else: enemies.flags[i] &= ~8
   if enemies.action[i]==0: enemies.action[i]=180
  if enemies.flags[i] & 1:
   if enemies.action[i] == 0:
    enemies.action[i] = int(db.config().boss_attack_period_ticks)
    enemies.warning[i] = int(db.config().boss_warning_ticks)
    enemies.attack_target[i] = state.player.position
   if enemies.warning[i] == 1 and enemies.attack_target[i].distance_to(state.player.position) < float(db.config().boss_attack_radius):
    damage.apply_player(state, enemies.damage[i], "boss:telegraph")
   if enemies.warning[i] > 0: speed = 0
  enemies.velocities[i] = direction * speed+enemies.impulses[i]
  enemies.impulses[i]*=.85
  enemies.positions[i] = map.move(enemies.positions[i], enemies.velocities[i] / 60, minf(18,enemies.radius[i]))
func contact(state: RunState, enemies: EnemyWorld, spatial: SpatialWorld, damage: DamageSystem, db: GameDatabase) -> void:
 spatial.query_circle(SpatialWorld.ENEMY, state.player.position, 100, scratch)
 for query_index in range(scratch.count):
  var id := scratch.ids[query_index]
  if not enemies.alive(id): continue
  var i := enemies.slot(id)
  if enemies.hp[i] > 0 and enemies.contact[i] == 0 and enemies.positions[i].distance_to(state.player.position) < enemies.radius[i] + 14:
   damage.apply_player(state,enemies.damage[i],"boss:contact" if enemies.flags[i]&1 else "enemy")
   enemies.contact[i] = int(db.config().contact_ticks)
