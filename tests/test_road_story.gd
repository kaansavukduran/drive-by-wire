extends SceneTree
const H=preload("res://tests/harness.gd")
const Story=preload("res://scripts/core/road_story.gd")
const Book=preload("res://scripts/core/story_book.gd")
const Store=preload("res://scripts/core/save_store.gd")
const Session=preload("res://scripts/game/session.gd")
const Pilot=preload("res://tests/autopilot.gd")
const UiSkin=preload("res://scripts/game/ui_skin.gd")
const TextFit=preload("res://scripts/game/text_fit.gd")
const Art=preload("res://scripts/game/story_cast_art.gd")
const Vehicles=preload("res://scripts/core/vehicles.gd")
var h=H.new("road_story")
func _initialize() -> void:call_deferred("run")
func frames() -> void:await process_frame;await process_frame
func run() -> void:
 h.eq("legacy save gets default car",Store.new().sanitize({})["vehicle"],"roadster")
 for bad in [null,"nonsense",[],0,{}]:h.eq("invalid vehicle rejected",Vehicles.sanitize(bad),"roadster")
 h.eq("forged final checkpoint cannot bypass two choices",Story.sanitize({"step":"complete"})["step"],"arrival")
 h.eq("unknown novel choice is inert",Story.choose(Story.defaults(),"oops"),Story.defaults())
 var store=Store.new("user://novel-regression.json")
 Session.story_mode=true
 var initial=Book.complete(Book.choose(Book.defaults(),"depart"),true,100,true)
 for font in ["system","lexend"]:
  UiSkin.configure("dark",font)
  for dimensions in [Vector2i(640,360),Vector2i(360,640),Vector2i(360,780),Vector2i(768,1024),Vector2i(1024,768)]:
   root.size=dimensions;root.content_scale_size=dimensions;await frames()
   Session.campaign_state=initial.duplicate(true)
   var game=load("res://scenes/road_story.tscn").instantiate();root.add_child(game);await frames()
   game.store=store;game.set_process(false)
   var all_fit:=true;var all_clear:=true;var preserved:=true
   for key in Story.STEPS:
    game.chapter={"step":key,"pace":"race","vow":"rescue" if key=="rescue" else "avenge"}
    game._present();game._layout();await frames()
    if game.portrait.get_global_rect().intersects(game.body.get_global_rect()) or game.portrait.get_global_rect().intersects(game.speaker.get_global_rect()):all_clear=false
    var recovered: Array[String]=[]
    for i in game.pages.size():
     game.page=i;game._reflow()
     recovered.append(game.body.text)
     if not TextFit.fits(game.body) or not TextFit.fits(game.speaker) or not TextFit.fits(game.page_caption):all_fit=false
    var text: String=Story.data()["nodes"][key].get("text",Story.data()["nodes"][key].get("caption",""))
    if " ".join(" ".join(recovered).split(" ",false))!=" ".join(text.split(" ",false)):preserved=false
    var controls: Array=game.choices.filter(func(b):return b.visible)
    if game.next_button.visible:controls.append(game.next_button)
    for b in controls:
     if b.size.y<44 or not game.panel.get_global_rect().encloses(b.get_global_rect()):all_clear=false
     if b.get_global_rect().intersects(game.body.get_global_rect()) or (game.page_caption.visible and b.get_global_rect().intersects(game.page_caption.get_global_rect())):all_clear=false
   h.check("all speech pages fit %s %s" % [font,dimensions],all_fit)
   h.check("every word retained %s %s" % [font,dimensions],preserved)
   h.check("44px actions clear prose %s %s" % [font,dimensions],all_clear)
   game.chapter={"step":"aftermath","pace":"together","vow":""};game._present()
   var anchors=game.actor_positions();game.motion=true
   var distinct: Array=[]
   var stable:=true
   for i in 60:
    game._process(.04)
    if not game.injury_frame() in distinct:distinct.append(game.injury_frame())
    if game.actor_positions()!=anchors:stable=false
    for j in Art.IDS.size():
     var who: String=Art.IDS[j];var sprite: Sprite2D=game.cast_sprites[who]
     var expected: Vector2=game.cast_stage.to_global(anchors[j])
     if sprite.position!=anchors[j] or sprite.global_position.distance_to(expected)>.01:stable=false
     var index:=Art.frame(who,game.ground_time,game.step_time,game.chapter["step"],game.motion)
     if sprite.offset!=-Art.anchor(who,index) or sprite.region_rect!=Art.region(who,index):stable=false
   h.check("injured actors never slide across all poses",stable)
   h.eq("all six authored injury frames actually play",distinct.size(),6)
   game.motion=false;h.eq("reduced motion uses a stable pose",game.injury_frame(),0)
   game.chapter={"step":"race","pace":"race","vow":""};game.elapsed=2
   game._pause(true);game._process(1)
   h.eq("pause freezes race",game.elapsed,2.0)
   game._pause(false);game._process(.1)
   h.check("resume advances actual race",game.elapsed>2)
   game._checkpoint();h.eq("race checkpoint reload keeps chosen pace",store.load_data()["campaign"]["chapter2"],game.chapter)
   game.chapter=Story.defaults();game._present();Pilot.story(game,0)
   h.eq("real speech buttons play through rescue",game.chapter["step"],"complete")
   h.check("completion commits once",game._commit_completion() and not game._commit_completion())
   h.eq("first interlude opens second combat",store.load_data()["campaign"]["stage"],1)
   h.check("revenge vow has epilogue consequence",Story.epilogue(store.load_data()["campaign"]).contains("Kurt"))
   game.queue_free();await frames()
 h.eq("Eren record survives actual scene completion and disk reload",store.load_data()["campaign"]["chapter2"]["record"],"sealed")
 h.eq("Eren bond is awarded exactly once by the actual scene",store.load_data()["campaign"]["bonds"]["eren"],1)
 # Vehicles persist and retain exactly the established physics and driver pivot.
 Session.story_mode=false;Session.campaign_state={}
 for id in Vehicles.IDS:
  var save=store.defaults();save["vehicle"]=id;h.check("selected vehicle saves",store.save_data(save));h.eq("selected vehicle reloads",store.load_data()["vehicle"],id)
 # Actual selected vehicle scenes use the same physical origin and muzzle sockets.
 for id in Vehicles.IDS:
  var clean=Store.new().defaults();clean["vehicle"]=id;Store.new().save_data(clean)
  var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames()
  game.set_process(false);game.set_physics_process(false)
  h.eq("real car selection is loaded",game.save["vehicle"],id)
  h.eq("each car loads its own silhouette",game.car.texture.resource_path,Vehicles.ITEMS[id]["texture"])
  var pivot: Vector2=game.car.offset
  for pose in ["drive","boost","fire","hit"]:
   game.anim=pose;game._animate(.1)
   h.eq("vehicle anchor cannot change with animation",game.car.offset,pivot)
   h.eq("vehicle render and hitbox agree",game.car.position,game._player_rect().get_center())
  game._fire({});game._execute({"intent":"drop_mine"})
  h.check("all cars fire forward and mine behind",game.bullets[-1]["pos"].y<game.car_y and game.mines[-1]["pos"].y>game.car_y)
  game.queue_free();await frames()
 Store.new().clear()
 # Test actual authored contact pixels, not alpha-centroid alignment. All
 # frame origins stay fixed while padding/trim differences use source anchors.
 for who in Art.IDS:
  var image: Image=Art.TEXTURES[who].get_image()
  var s: Dictionary=Art.spec(who);var hashes: Dictionary={}
  for i in int(s["frames"]):
   var region: Rect2=Art.region(who,i);var at: Vector2=Art.anchor(who,i)
   var cell=image.get_region(Rect2i(region))
   hashes[cell.get_data().hex_encode().sha256_text()]=true
   h.check("%s frame%d authored contact is real opaque material" % [who,i],cell.get_pixelv(Vector2i(at)).a>=.94)
   h.check("%s frame%d has cell padding" % [who,i],at.x>4 and at.y>4 and at.x<cell.get_width()-4 and at.y<cell.get_height()-4)
  h.eq("%s has distinct authored poses" % who,hashes.size(),int(s["frames"]))
 var checkpoint: Dictionary={"step":"handoff","pace":"race","vow":"avenge"}
 h.eq("old 0.9 checkpoint is not forced to invent Eren record choice",Story.sanitize(checkpoint)["record"],"")
 var witness: Dictionary={"step":"witness","pace":"race","vow":"rescue"}
 h.eq("unknown Eren record is rejected",Story.sanitize({"record":"forged"})["record"],"")
 h.eq("Eren record choice saves actual branch",Story.choose(witness,"shared")["record"],"shared")
 h.check("Eren record choice changes the epilogue",Story.epilogue({"chapter2":Story.choose(witness,"sealed")})!=Story.epilogue({"chapter2":Story.choose(witness,"shared")}))
 store.clear();UiSkin.configure("dark","system");quit(h.finish())
