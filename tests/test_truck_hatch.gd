extends SceneTree
const H=preload("res://tests/harness.gd")
const Hatch=preload("res://scripts/game/truck_hatch.gd")
const Session=preload("res://scripts/game/session.gd")
var h=H.new("truck_hatch")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for amount in [0.0,.1,.25,.5,.75,1.0]:
  var doors:=Hatch.leaves(amount)
  for side in 2:
   var door: Dictionary=doors[side];var hinge: Vector2=door["hinge"];var free: Vector2=door["free"]
   h.eq("hinge cannot slide with opening",hinge,Hatch.LEFT if side==0 else Hatch.RIGHT)
   h.near("rigid door retains its true width",hinge.distance_to(free),Hatch.LEAF,.0001)
   h.check("doors open behind the body, never through its roof",free.y>=hinge.y)
   h.near("door keeps its projected height",door["corners"][0].distance_to(door["corners"][3]),Hatch.HEIGHT,.0001)
 var closed:=Hatch.leaves(0);var opened:=Hatch.leaves(1)
 h.eq("closed door edges actually meet",closed[0]["free"],closed[1]["free"])
 h.check("fully open leaves clear both sides of the aperture",opened[0]["free"].x<Hatch.LEFT.x and opened[1]["free"].x>Hatch.RIGHT.x)
 h.check("release is aligned with the actual rear mouth",is_equal_approx(Hatch.RELEASE.x,(Hatch.LEFT.x+Hatch.RIGHT.x)/2) and Hatch.RELEASE.y>Hatch.LEFT.y)
 Session.story_mode=false;Session.campaign_state={}
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.set_process(false);game.set_physics_process(false)
 game.speed=game.run_cfg["enemies"]["truck"]["speed"]
 game.enemies.clear();game.obstacles.clear();game._spawn_enemy_for_test("truck",0,80)
 var truck: Dictionary=game.enemies[0];truck["cd"]=0
 var root_position: Vector2=truck["pos"]
 game._update_enemies(0)
 h.eq("attack warning begins with the doors shut",truck["hatch_open"],0.0)
 var previous:=0.0
 for tick in 39:
  game._update_enemies(.01)
  h.check("opening is gradual and monotonic",truck["hatch_open"]>previous and truck["hatch_open"]<1)
  h.eq("opening cannot move the chassis",truck["pos"],root_position)
  previous=truck["hatch_open"]
 h.eq("nothing can leave while the doors are opening",game.obstacles.size(),0)
 for tick in 40:
  game._update_enemies(.01)
  if not game.obstacles.is_empty():break
 h.eq("natural warning releases exactly one cargo",game.obstacles.size(),1)
 h.eq("doors are fully open on the release tick",truck["hatch_open"],1.0)
 h.eq("actual cargo uses the visible rear mouth",game.obstacles[0]["pos"],root_position+Hatch.RELEASE)
 h.eq("released obstacle keeps its actual source",game.obstacles[0]["source_id"],truck["id"])
 h.eq("windup feedback clears once released",game._enemy_warnings().size(),0)
 var released_state: int=game.rng.state
 for tick in 10:game._update_enemies(.01)
 h.eq("doors hold open until cargo clears the mouth",truck["hatch_open"],1.0)
 previous=truck["hatch_open"]
 for tick in 30:
  game._update_enemies(.01)
  h.check("closing is monotonic rather than a frame swap",truck["hatch_open"]<=previous)
  previous=truck["hatch_open"]
 h.eq("doors close completely",truck["hatch_open"],0.0)
 h.eq("visual animation never consumes attack RNG",game.rng.state,released_state)
 h.eq("open-close cycle does not duplicate cargo",game.obstacles.size(),1)
 # An unsafe late drop is cancelled; its doors must close without snapping.
 game.enemies.clear();game.obstacles.clear();game._spawn_enemy_for_test("truck",0,80)
 truck=game.enemies[0];truck["cd"]=0;game._update_enemies(0)
 for tick in 30:game._update_enemies(.01)
 previous=truck["hatch_open"];truck["pos"].y=game.car_y-79
 game._update_enemies(.01)
 h.check("cancelled attack starts closing smoothly",truck["hatch_open"]>0 and truck["hatch_open"]<previous)
 h.eq("cancel never creates cargo",game.obstacles.size(),0)
 for tick in 30:game._update_enemies(.01)
 h.eq("cancelled hatch returns to fully shut",truck["hatch_open"],0.0)
 game.queue_free();await process_frame;quit(h.finish())
