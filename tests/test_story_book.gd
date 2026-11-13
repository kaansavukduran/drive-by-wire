extends SceneTree
const Pilot := preload("res://tests/autopilot.gd")
const H := preload("res://tests/harness.gd")
const Book := preload("res://scripts/core/story_book.gd")
const Store := preload("res://scripts/core/save_store.gd")
const Session := preload("res://scripts/game/session.gd")
var h:=H.new("story_book")
var results: Array=[]
func _initialize() -> void: call_deferred("run")
func run() -> void:
 h.eq("exactly thirteen distinct ending records",Book.data()["endings"].size(),13)
 var ids: Array=[]
 var paths: Array=[]
 var texts: Array=[]
 var state:=Book.defaults()
 for item in Book.data()["endings"]:
  ids.append(item["id"]); paths.append("/".join(item["path"])); texts.append(item["text"])
  state=Book.defaults()
  for id in item["path"]:
   state=Book.choose(state,id)
   h.check("%s choice %s belongs to the current node" % [item["id"],id],state["active"] and not Book.current(state).is_empty())
   state=Book.complete(state,true,100,true)
   h.eq("completion cannot be applied twice",Book.complete(state,true,100,true),state)
  h.eq("choice path reaches its actual ending",Book.ending(state)["id"],item["id"])
  h.eq("ending unlock is stored once",state["unlocked"],[item["id"]])
  h.check("epilogue has substantive unique prose",str(item["text"]).length()>350 and texts.count(item["text"])==1)
 h.eq("unique ids",_unique(ids),13)
 h.eq("unique paths",_unique(paths),13)
 h.eq("unknown choice cannot activate a leg",Book.choose(Book.defaults(),"invented"),Book.defaults())
 state=Book.choose(Book.defaults(),"archive")
 state=Book.complete(state,true,120,true)
 state=Book.choose(state,"seal")
 var failed:=Book.complete(state,false,999,true)
 h.eq("failure retains completed choices",failed["choices"],["archive"])
 h.eq("failure does not advance or unlock an ending",[failed["stage"],failed["unlocked"],failed["failures"]],[1,[],1])
 var store:=Store.new("user://book-test.json")
 var save: Dictionary=store.defaults()
 save["campaign"]=state
 h.check("active checkpoint can be saved",store.save_data(save))
 h.eq("checkpoint survives disk reload",store.load_data()["campaign"],state)
 h.eq("malformed state cannot unlock arbitrary endings",Book.sanitize({"stage":3,"choices":["nonsense"],"active":true,"unlocked":["fake"],"goals_completed":99})["unlocked"],[])
 store.clear()
 # Run all 39 arcade legs with unmodified HP, real spawning/collisions, weapons,
 # pickup steering and support. No teleport, time skips or invulnerability.
 Session.story_mode=true
 var unlocked: Array=[]
 for item in Book.data()["endings"]:
  state=Book.defaults(unlocked)
  var path_results: Array=[]
  for stage in 3:
   state=Book.choose(state,str(item["path"][stage]))
   Session.campaign_state=state.duplicate(true)
   var game=load("res://scenes/main.tscn").instantiate()
   root.add_child(game)
   await process_frame
   game.set_physics_process(false)
   game.store=store
   game.rng.seed=42+stage
   game._direct_action("drive_comfort")
   for tick in 60*70:
    if game.over: break
    Pilot.drive(game)
    if tick%600==0: game._direct_action("drive_comfort")
    game._simulate(1.0/60.0)
   h.check("%s leg %d survives real arcade" % [item["id"],stage+1],game.over and game.end_result.get("outcome")=="survived","hp %.0f, distance %.0f" % [game.hp,game.distance])
   h.check("%s leg %d defeats its story robot" % [item["id"],stage+1],game.boss.defeated)
   h.check("%s leg %d encounters actual traffic and supplies" % [item["id"],stage+1],game.kills>0 and game.arcade.collected>0)
   state=Session.campaign_state.duplicate(true)
   h.eq("actual completion persists checkpoint",store.load_data()["campaign"],state)
   path_results.append({"stage":stage+1,"seconds":game.game_time,"hp":game.hp,"distance":game.distance,"kills":game.kills,"pickups":game.arcade.collected})
   game.queue_free()
   await process_frame
  var actual: Dictionary=Book.ending(state)
  h.eq("%s reachable after three played legs" % item["id"],actual.get("id"),item["id"])
  unlocked=state["unlocked"].duplicate()
  results.append({"ending":item["id"],"path":item["path"],"legs":path_results})
 h.eq("all thirteen unlocked by completed arcade paths",unlocked.size(),13)
 var evidence:=FileAccess.open("user://story-runs.json",FileAccess.WRITE)
 evidence.store_string(JSON.stringify(results,"  "))
 evidence.close()
 var evidence_path: String=OS.get_environment("DBW_STORY_EVIDENCE")
 if not evidence_path.is_empty():
  var copy:=FileAccess.open(evidence_path,FileAccess.WRITE)
  copy.store_string(JSON.stringify(results,"  "))
  copy.close()
 print("STORY_RUNS "+JSON.stringify(results))
 store.clear()
 Session.story_mode=false
 Session.campaign_state={}
 quit(h.finish())
func _unique(items: Array) -> int:
 var set: Dictionary={}
 for item in items: set[item]=true
 return set.size()
