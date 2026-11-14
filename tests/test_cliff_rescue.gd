extends SceneTree
const H=preload("res://tests/harness.gd")
const Book=preload("res://scripts/core/story_book.gd")
const Cliff=preload("res://scripts/core/cliff_story.gd")
const Session=preload("res://scripts/game/session.gd")
const Store=preload("res://scripts/core/save_store.gd")
const UiSkin=preload("res://scripts/game/ui_skin.gd")
const TextFit=preload("res://scripts/game/text_fit.gd")
const Art=preload("res://scripts/game/visual_art.gd")
var h:=H.new("cliff_rescue")
func _initialize() -> void:call_deferred("run")
func frames() -> void:await process_frame;await process_frame
func run() -> void:
 # The front bumper must always stay on the visible support plane.
 for step in ["approach","impact","brake"]:
  var safe:=true
  for tick in 101:
   var p:=Cliff.poses(step,Cliff.duration(step)*tick/100.0)
   if p["aion_car"].y-37<p["edge_y"]:safe=false
  h.check("front remains above grounded rim throughout "+step,safe)
 var contact:=Cliff.poses("impact",0)
 h.check("Kurt contacts left side, not rear or front",contact["kurt_car"].x<contact["aion_car"].x and absf(contact["kurt_car"].y-contact["aion_car"].y)<1 and absf(contact["kurt_car"].x+33-(contact["aion_car"].x-16))<6)
 h.eq("approach/impact seam",Cliff.poses("approach",3)["aion_car"],Cliff.poses("impact",0)["aion_car"])
 h.eq("impact/brake seam",Cliff.poses("impact",.6)["aion_car"],Cliff.poses("brake",0)["aion_car"])
 for i in 4:
  var cell:=Art.region("kurt_scene",i);var foot: Array=Art.data()["kurt_scene_feet"][i]
  h.check("registered planted paw is opaque %d"%i,Art.texture("kurt_scene").get_image().get_pixelv(Vector2i(cell.position+Vector2(foot[0],foot[1]))).a>=.94)
 for car in 3:h.check("visible bumper really touches chosen car %d"%car,visible_contact(car))
 var store:=Store.new("user://cliff-test.json");Session.story_mode=true
 for theme in ["dark","light"]:
  for dimensions in [Vector2i(640,360),Vector2i(360,640),Vector2i(320,568),Vector2i(844,390)]:
   UiSkin.configure(theme,"system");root.size=dimensions;root.content_scale_size=dimensions;await frames()
   var s:=Book.defaults();s["stage"]=1;s["phase"]="interlude";Session.campaign_state=s
   var game=load("res://scenes/road_story.tscn").instantiate();root.add_child(game);await frames();game.store=store;game.set_process(false)
   var fit:=true;var clear:=true;var all_words:=true
   for key in Cliff.STEPS:
    game.chapter={"step":key,"reply":"shaken"};game._present();await frames()
    var recovered: Array[String]=[]
    for page in game.pages.size():
     game.page=page;game._reflow();recovered.append(game.body.text)
     if not TextFit.fits(game.body) or not TextFit.fits(game.speaker):fit=false
    if " ".join(" ".join(recovered).split(" ",false))!=" ".join(str(Cliff.data()["nodes"][key]["text"]).split(" ",false)):all_words=false
    var actions: Array=game.choices.filter(func(b):return b.visible)
    if game.next_button.visible:actions.append(game.next_button)
    for b in actions:
     if b.size.y<44 or not game.panel.get_global_rect().encloses(b.get_global_rect()) or b.get_global_rect().intersects(game.body.get_global_rect()):clear=false
   h.check("cliff dialogue fits %s %s"%[theme,dimensions],fit)
   h.check("all words retained %s %s"%[theme,dimensions],all_words)
   h.check("actions reach without a wheel %s %s"%[theme,dimensions],clear)
   h.check("compact normal panel",game.panel.size.y<=140 if dimensions.y>dimensions.x else game.panel.size.y<=132)
   game.chapter={"step":"check","reply":""};game.elapsed=0;game._present();game._sync_cliff_cast()
   var before: Vector2=game.cliff_kurt.global_position
   game._process(1);h.eq("talking actor never drifts",game.cliff_kurt.global_position,before)
   game._pause(true);var t: float=game.elapsed;game._process(2);h.eq("pause freezes timeline",game.elapsed,t);game._pause(false)
   game.chapter=Cliff.defaults();game._present()
   for beat in 1200:
    if game.chapter["step"]=="complete":break
    if game._cinematic():game._process(1.0/60)
    elif game.next_button.visible:game.next_button.pressed.emit()
    elif game.choices[0].visible:game.choices[0].pressed.emit()
   h.eq("real scene reaches promise and continued",game.chapter["step"],"complete")
   h.check("commit exactly once",game._commit_completion() and not game._commit_completion())
   var saved: Dictionary=store.load_data()["campaign"]
   h.eq("end marker persists",[saved["stage"],saved["phase"]],[2,"continued"])
   h.eq("cliff checkpoint survives reopen",saved["cliff"]["step"],"complete")
   game.queue_free();await frames()
 UiSkin.configure("dark","system");Session.campaign_state={};Session.story_mode=false;store.clear();quit(h.finish())

func visible_contact(index: int) -> bool:
 var p:=Cliff.poses("impact",0)
 var occupied: Dictionary={}
 var source:=Art.region("players",index);var pixels:=Art.texture("players").get_image()
 for y in 74:
  for x in 48:
   var sample:=Vector2i(source.position+(Vector2(x,y)+Vector2(.5,.5))/Vector2(48,74)*source.size)
   if pixels.get_pixelv(sample).a>=.94:occupied[Vector2i(p["aion_car"]+Vector2(x+.5-24,y+.5-37))]=true
 source=Art.region("cliff_cars",0);pixels=Art.texture("cliff_cars").get_image()
 for y in 74:
  for x in 48:
   var sample:=Vector2i(source.position+(Vector2(x,y)+Vector2(.5,.5))/Vector2(48,74)*source.size)
   if pixels.get_pixelv(sample).a<.94:continue
   var point:=Vector2i(p["kurt_car"]+Vector2(-(y+.5-37),x+.5-24))
   for offset in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    if occupied.has(point+offset):return true
 return false
