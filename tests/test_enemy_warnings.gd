extends SceneTree
const Harness := preload("res://tests/harness.gd")
const Store := preload("res://scripts/core/save_store.gd")
const Session := preload("res://scripts/game/session.gd")
var h:=Harness.new("enemy_warnings")
var game: Node2D
func _initialize() -> void: call_deferred("run")
func advance(seconds: float) -> void:
 for i in int(round(seconds*60)):
  game._update_enemies(1.0/60.0)
func reset_traffic() -> void:
 game.enemies.clear()
 game.obstacles.clear()
 game.enemy_bullets.clear()
 game.pickups.clear()
 game.bullets.clear()
func run() -> void:
 Session.story_mode=false
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_process(false)
 game.set_physics_process(false)
 game.store=Store.new("user://warnings-test.json")
 h.check("essential cue layer renders above the player vehicle",game.get_node("EnemyWarnings").z_index>game.car.z_index)
 game.rng.seed=42
 game.companion_rng.seed=99
 game._spawn_enemy_for_test("pickup",0,80)
 var enemy: Dictionary=game.enemies[0]
 enemy["slot"]=80.0
 enemy["cd"]=0.0
 enemy["lane_cd"]=99.0
 game._update_enemies(0.0)
 h.eq("shooter warns before firing",enemy["state"],"windup")
 h.eq("warning does not create a projectile",game.enemy_bullets.size(),0)
 var locked_aim: Vector2=Vector2(game.car_x,game.PLAYER_Y)
 var warnings: Array=game._enemy_warnings()
 h.check("shot cue shows locked target and distinct kind",warnings.size()==1 and warnings[0]["kind"]=="shot" and warnings[0]["target"]==locked_aim)
 game._change_lane(2)
 for i in 12: game.car_x=move_toward(game.car_x,game._lane_x(game.lane),64.0/0.16/60)
 h.eq("moving after the warning does not retarget shot",game._enemy_warnings()[0]["target"],locked_aim)
 advance(0.3)
 h.eq("no shot before warning duration",game.enemy_bullets.size(),0)
 h.check("visible charge progresses",game._enemy_warnings()[0]["progress"]>0.4)
 game._set_paused(true)
 var held: float=enemy["t"]
 var paused_warning: Array=game._enemy_warnings()
 game._simulate(2.0)
 h.eq("pause preserves warning timer",enemy["t"],held)
 h.eq("pause preserves warning target and progress",game._enemy_warnings(),paused_warning)
 game._set_paused(false)
 advance(0.3)
 h.eq("one shot after the real windup",game.enemy_bullets.size(),1)
 if not game.enemy_bullets.is_empty():
  var bullet: Dictionary=game.enemy_bullets[0]
  var expected: Vector2=(locked_aim-bullet["pos"]).normalized()
  h.check("released projectile uses the advertised direction",bullet["vel"].normalized().distance_to(expected)<0.0001)
 h.eq("released shot clears its windup cue",game._enemy_warnings().size(),0)
 advance(0.3)
 h.eq("attack frame cannot release duplicate shots",game.enemy_bullets.size(),1)
 # Vital warnings remain present with both decorative motion and shake disabled.
 reset_traffic()
 game.motion_enabled=false
 game.effects_enabled=false
 game._spawn_enemy_for_test("truck",0,100)
 var truck: Dictionary=game.enemies[0]
 truck["cd"]=0.0
 game._update_enemies(0.0)
 h.eq("truck warns before dropping an obstacle",truck["state"],"windup")
 h.eq("no obstacle at the warning start",game.obstacles.size(),0)
 warnings=game._enemy_warnings()
 h.check("reduced motion keeps the essential drop cue",warnings.size()==1 and warnings[0]["kind"]=="drop")
 h.eq("drop cue identifies actual release point",warnings[0]["target"],truck["pos"]+Vector2(0,52))
 advance(0.5)
 h.eq("truck cannot drop before warning duration",game.obstacles.size(),0)
 advance(0.2)
 h.eq("warned drop creates one obstacle",game.obstacles.size(),1)
 h.eq("drop clears its cue",game._enemy_warnings().size(),0)
 # A truck moving past the safe drop region cancels rather than dropping on us.
 reset_traffic()
 game._spawn_enemy_for_test("truck",game.lane,209)
 truck=game.enemies[0]
 truck["cd"]=0.0
 game._update_enemies(0.0)
 advance(0.8)
 h.eq("passed truck cancels unsafe late drop",game.obstacles.size(),0)
 h.eq("cancelled drop clears windup",truck["state"],"drive")
 reset_traffic()
 game._spawn_enemy_for_test("rammer",0,250)
 game.enemies[0]["lane_cd"]=0.0
 game._update_enemies(1.0/60.0)
 warnings=game._enemy_warnings()
 h.check("rammer lane crossing has a directional cue",warnings.size()==1 and warnings[0]["kind"]=="ram" and warnings[0]["lane"]==game.lane)
 reset_traffic()
 game._spawn_enemy_for_test("rammer",1,410)
 game._spawn_enemy_for_test("pickup",1,400)
 h.eq("multiple rear pursuers share one lane marker",game._enemy_warnings().size(),1)
 game._spawn_enemy_for_test("rammer",2,410)
 h.eq("different threatened lanes keep separate markers",game._enemy_warnings().size(),2)
 var rng_state: int=game.rng.state
 for i in 10: game._enemy_warnings()
 h.eq("reading warning feedback never advances gameplay RNG",game.rng.state,rng_state)
 reset_traffic()
 game.bullets.append({"pos":Vector2(-100,game.PLAYER_Y),"vel":Vector2(-420,0)})
 game._update_bullets(1.0/60.0)
 h.eq("missed horizontal shots leave bounded memory",game.bullets.size(),0)
 for pos in [Vector2(-100,100),Vector2(300,-150),Vector2(300,600)]:
  game.enemy_bullets.append({"pos":pos,"vel":Vector2.ZERO,"dmg":8,"near":false,"passed":false})
 var hp_before: float=game.hp
 game._update_bullets(1.0/60.0)
 h.eq("out of field enemy projectiles expire in all directions",game.enemy_bullets.size(),0)
 h.eq("expired projectiles do not damage the player",game.hp,hp_before)
 game._spawn_enemy_for_test("rammer",game.lane,410)
 var pursuer: Dictionary=game.enemies[0]
 game.fire_cooldown=0
 game._fire({})
 h.check("front gun cannot target an offscreen rear pursuer",game.bullets[-1]["vel"].y<0)
 game._execute({"intent":"drop_mine"})
 for i in 90:
  game._update_mines(1.0/60.0)
  game._update_enemies(1.0/60.0)
 h.check("rear mine actually damages or destroys warned pursuer",pursuer["hp"]<pursuer["max_hp"])
 game.over=true
 h.eq("result screen removes action cues",game._enemy_warnings(),[])
 game.store.clear()
 game.queue_free()
 quit(h.finish())
