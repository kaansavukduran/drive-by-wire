extends SceneTree
const Pilot := preload("res://tests/autopilot.gd")
const H := preload("res://tests/harness.gd")
const Store := preload("res://scripts/core/save_store.gd")
const Session := preload("res://scripts/game/session.gd")
const Book := preload("res://scripts/core/story_book.gd")
var h:=H.new("book_flow")
func _initialize() -> void: call_deferred("run")
func frames(n:=3) -> void:
 for i in n: await process_frame
func tap(code: int=JOY_BUTTON_A) -> void:
 var e:=InputEventJoypadButton.new()
 e.button_index=code
 e.pressed=true
 Input.parse_input_event(e)
 Input.flush_buffered_events()
 await frames(1)
 e=e.duplicate()
 e.pressed=false
 Input.parse_input_event(e)
 Input.flush_buffered_events()
 await frames()
func play(game: Node) -> void:
 game.set_physics_process(false)
 game.rng.seed=42
 game._direct_action("drive_comfort")
 for tick in 60*70:
  if game.over: break
  Pilot.drive(game)
  game._simulate(1.0/60.0)
func run() -> void:
 Store.new().clear()
 Session.campaign_state={}
 change_scene_to_file("res://scenes/title.tscn")
 await frames()
 await tap()
 h.eq("title starts three-choice story",current_scene.choices.size(),3)
 for stage in 3:
  h.eq("decision screen shows current chapter",current_scene.campaign["stage"],stage)
  await tap()
  var game:=current_scene
  if stage==1:
   h.check("native A enters chapter two novel",game.get("chapter")!=null)
   game.set_process(false)
   for beat in 2000:
    if game.chapter["step"]=="complete":break
    if game._cinematic():game._process(1.0/60.0)
    else:await tap()
   h.eq("gamepad plays novel through the rescue",game.chapter["step"],"complete")
   await tap()
   h.eq("novel completion enters third decision",current_scene.campaign["stage"],2)
   continue
  if not h.check("native A choice enters arcade",game.get("lane")!=null):
   quit(h.finish());return
  h.eq("story arcade leg is 400m",game._cfg("arcade.finish_distance",0),400.0)
  play(game)
  h.check("played chapter completes",game.over and game.end_result["outcome"]=="survived")
  h.eq("next chapter checkpoint persists",Store.new().load_data()["campaign"]["stage"],stage+1)
  h.eq("result button reflects next step",game.result_buttons[0].text,"Sonu oku" if stage==2 else "Sonraki seçim")
  await tap()
 h.check("final result opens actual epilogue screen",current_scene.get("gallery")!=null and not current_scene.gallery)
 h.eq("played UI path unlocks matching ending",Book.ending(current_scene.campaign)["id"],"e01")
 await tap(JOY_BUTTON_DPAD_DOWN)
 await tap()
 h.check("native gamepad opens ending gallery",current_scene.get("gallery")==true)
 h.eq("gallery contains thirteen slots",current_scene.ending_buttons.size(),13)
 h.eq("only earned ending can be opened",current_scene.ending_buttons.filter(func(b): return not b.disabled).size(),1)
 current_scene.primary.grab_focus()
 await tap()
 h.eq("new story preserves unlocked endings",current_scene.campaign["unlocked"],["e01"])
 h.eq("new story resets chapter progress",current_scene.campaign["stage"],0)
 await tap()
 var game:=current_scene
 game.set_physics_process(false)
 game._damage_player(1000)
 h.check("fatal damage produces retry without a new ending",game.over and game.campaign["stage"]==0 and game.campaign["unlocked"]==["e01"])
 await tap()
 h.eq("failure returns to same decision",current_scene.campaign["stage"],0)
 await tap()
 game=current_scene
 game.set_physics_process(false)
 var checkpoint: Dictionary=Store.new().load_data()["campaign"]
 h.check("choice is saved before entering combat",checkpoint["active"] and checkpoint["choices"]==["signal"])
 Session.campaign_state={}
 change_scene_to_file("res://scenes/title.tscn")
 await frames()
 h.eq("fresh title restores campaign from disk",current_scene.campaign,checkpoint)
 await tap()
 h.check("resume screen retains active choice",current_scene.campaign["active"])
 await tap()
 game=current_scene
 game.set_physics_process(false)
 h.check("resume starts at chapter beginning with correct choice",game.distance<2 and game.campaign["choices"]==["signal"])
 Store.new().clear()
 Session.story_mode=false
 Session.campaign_state={}
 quit(h.finish())
