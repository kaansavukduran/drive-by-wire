extends SceneTree
const Pilot=preload("res://tests/autopilot.gd")
const H=preload("res://tests/harness.gd")
const Store=preload("res://scripts/core/save_store.gd")
const Session=preload("res://scripts/game/session.gd")
const Book=preload("res://scripts/core/story_book.gd")
var h:=H.new("book_flow")
func _initialize() -> void:call_deferred("run")
func frames(n:=3) -> void:
 for i in n:await process_frame
func tap(code: int=JOY_BUTTON_A) -> void:
 var e:=InputEventJoypadButton.new();e.button_index=code;e.pressed=true;Input.parse_input_event(e);Input.flush_buffered_events();await frames(1)
 e=e.duplicate();e.pressed=false;Input.parse_input_event(e);Input.flush_buffered_events();await frames()
func run() -> void:
 Store.new().clear();Session.campaign_state={};change_scene_to_file("res://scenes/title.tscn");await frames();await tap()
 h.eq("one linear departure action",current_scene.choices.size(),1)
 for stage in 2:
  h.eq("chapter index follows fixed order",current_scene.campaign["stage"],stage)
  await tap();var game:=current_scene
  if not h.check("A enters actual combat for both stages",game.get("boss")!=null):quit(h.finish());return
  game.set_physics_process(false);game.rng.seed=42+stage
  for tick in 60*90:
   if game.over:break
   Pilot.drive(game);game._simulate(1.0/60.0)
  h.check("real 400m and boss completed",game.over and game.end_result.get("outcome")=="survived" and game.boss.defeated)
  h.eq("checkpoint enters corresponding interlude",[Store.new().load_data()["campaign"]["stage"],Store.new().load_data()["campaign"]["phase"]],[stage,"interlude"])
  h.eq("clear result action","Ara sahneye geç",game.result_buttons[0].text)
  await tap();game=current_scene
  h.eq("interlude number matches combat",game.cliff_scene,stage==1)
  game.set_process(false)
  var seen:=[]
  for beat in 3000:
   var step: String=game.chapter["step"]
   if not step in seen:seen.append(step)
   if step=="complete":break
   if game._cinematic():game._process(1.0/60.0)
   else:await tap()
  h.eq("gamepad advances full interlude",game.chapter["step"],"complete")
  if stage==1:h.check("rescue animation and promise actually reached",seen.has("impact") and seen.has("exit") and seen.has("check") and seen.has("thanks") and seen.has("promise"))
  while game.page+1<game.pages.size():await tap()
  await tap()
 h.eq("end of current content, no third route",current_scene.heading.text,"DEVAM EDECEK")
 h.eq("persisted boundary",[Store.new().load_data()["campaign"]["stage"],Store.new().load_data()["campaign"]["phase"]],[2,"continued"])
 Session.campaign_state={};change_scene_to_file("res://scenes/title.tscn");await frames();await tap()
 h.eq("reopening completed save stays at continued",current_scene.heading.text,"DEVAM EDECEK")
 await tap();h.eq("explicit restart opens first chapter",current_scene.campaign["stage"],0)
 await tap();var game:=current_scene;game.set_physics_process(false);game._damage_player(1000);await tap()
 h.eq("failure retries same stage",current_scene.campaign["stage"],0)
 Store.new().clear();Session.story_mode=false;Session.campaign_state={};quit(h.finish())
