extends SceneTree
## Rendering frequency and accessibility preferences must not alter combat.
const Harness := preload("res://tests/harness.gd")
const Store := preload("res://scripts/core/save_store.gd")
const Session := preload("res://scripts/game/session.gd")
var h:=Harness.new("run_fairness")
func _initialize() -> void: call_deferred("run")
func make_game(path: String) -> Node2D:
 var game: Node2D=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 game.set_process(false)
 game.store=Store.new(path)
 game.rng.seed=42
 if game.get("companion_rng")!=null: game.companion_rng.seed=99
 return game
func state(game: Node2D) -> Dictionary:
 return {"rng":game.rng.state,"hp":game.hp,"lane":game.lane,"x":game.car_x,"distance":game.distance,"speed":game.speed,"energy":game.energy,"shield":game.shield_left,"kills":game.kills,"mines":game.mines_left,"spawn_timer":game.spawn_timer,"pickup_timer":game.pickup_timer,"enemies":game.enemies.duplicate(true),"pickups":game.pickups.duplicate(true),"obstacles":game.obstacles.duplicate(true),"bullets":game.bullets.duplicate(true),"enemy_bullets":game.enemy_bullets.duplicate(true),"score":game.arcade.score,"contract":game.arcade.contract,"collected":game.arcade.collected,"companion":game.momo.get_state(),"over":game.over}
func run() -> void:
 Session.story_mode=false
 Session.next_run_modifiers=[]
 var detailed:=make_game("user://fairness-detail.json")
 var reduced:=make_game("user://fairness-reduced.json")
 reduced.motion_enabled=false
 reduced.effects_enabled=false
 if detailed.get("visual_rng")!=null:
  detailed.visual_rng.seed=17
  reduced.visual_rng.seed=456
 detailed._damage_player(5)
 reduced._damage_player(5)
 for tick in 3600:
  if tick%600<120: Input.action_press("drive_up")
  else: Input.action_release("drive_up")
  for game in [detailed,reduced]:
   game._fire({})
   if not game.pickups.is_empty():
    var pos: Vector2=game.pickups[0]["pos"]
    if pos.y>130 and pos.y<250: game._change_lane(game._lane_of(pos.x))
   if tick%600==0: game._direct_action("drive_comfort")
  # Simulate additional camera samples, like higher rendering frequency.
  if detailed.has_method("_camera_offset"):
   for sample in 5: detailed._camera_offset()
  detailed._simulate(1.0/60.0)
  reduced._simulate(1.0/60.0)
  if state(detailed)!=state(reduced):
   h.check("visual preferences and camera samples preserve identical combat",false,"first divergent physics tick: %d" % tick)
   Input.action_release("drive_up")
   detailed.store.clear()
   reduced.store.clear()
   quit(h.finish())
   return
  if tick%120==0: h.check("combat agrees at physics tick %d" % tick,true)
 h.check("comparison includes real traffic and pickups",detailed.kills>0 and detailed.arcade.collected>0)
 h.check("decorative scenery actually differs",detailed.decals!=reduced.decals or detailed.props!=reduced.props)
 var before: int=detailed.rng.state
 detailed.shake=0.2
 detailed.shake_power=3
 var first: Vector2=detailed._camera_offset()
 for i in 10: h.eq("camera sample is stable within a physics step",detailed._camera_offset(),first)
 h.eq("camera consumes no gameplay randomness",detailed.rng.state,before)
 detailed._set_paused(true)
 h.eq("pause clears camera offset",detailed._camera_offset(),Vector2.ZERO)
 Input.action_release("drive_up")
 detailed.store.clear()
 reduced.store.clear()
 detailed.queue_free()
 reduced.queue_free()
 quit(h.finish())
