extends SceneTree
const H=preload("res://tests/harness.gd")
const Session=preload("res://scripts/game/session.gd")
const Controls=preload("res://scripts/game/controls.gd")
const Book=preload("res://scripts/core/story_book.gd")
const Biomes=preload("res://scripts/game/road_biomes.gd")
const Store=preload("res://scripts/core/save_store.gd")
const TextFit=preload("res://scripts/game/text_fit.gd")
const Loader=preload("res://scripts/game/loading_screen.gd")
var h:=H.new("road_presentation")
func _initialize() -> void:call_deferred("run")
func frames() -> void:await process_frame;await process_frame
func run() -> void:
 h.check("strawberry is a shipped Godot resource",ResourceLoader.exists(Loader.BRAND_PATH))
 var logo: Texture2D=load(Loader.BRAND_PATH);h.eq("original strawberry dimensions preserved",logo.get_size(),Vector2(1058,1487))
 for stage in 2:
  for distance in [0,179,180,280,399,400]:h.eq("one biome throughout stage %d at %d"%[stage,distance],Biomes.index(stage,distance),[2,3][stage])
 var configurations: Array=[]
 for key in Book.data()["nodes"]:
  var replies: Array=Book.data()["nodes"][key]["responses"]
  h.eq("three actual narrative replies in "+key,replies.size(),3)
  var next_states: Array=[]
  for reply in replies:
   var state:=Book.defaults();state["stage"]=int(key.trim_prefix("chapter_"))-1
   var answered:=Book.answer(state,reply["id"])
   h.eq("reply is really saved",Book.radio_reply(answered)["id"],reply["id"])
   next_states.append(Book.current(Book.choose(answered,"depart")))
  h.check("all replies lead to same driving rules",next_states[0]==next_states[1] and next_states[1]==next_states[2])
 Session.story_mode=false;Session.campaign_state={}
 for view in [Vector2i(640,360),Vector2i(640,480),Vector2i(360,640),Vector2i(360,780),Vector2i(320,568)]:
  root.size=view;root.content_scale_size=view;await frames()
  var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await frames();game.set_physics_process(false);game.set_process(false)
  game.touch_enabled=true;game._layout();game._update_hud()
  h.eq("only two visible combat action owners",game.touch_by_action.keys().size(),2)
  h.check("fire and mine are the two actions",game.touch_by_action.has("drive_fire") and game.touch_by_action.has("drive_mine"))
  h.check("plain compact health bar replaces panel",not game.ui_panels[0].visible and game.hp_bar.size.y<=12)
  h.check("notifications are bare text",game.toast.get_theme_stylebox("normal") is StyleBoxEmpty and game.story_caption.get_theme_stylebox("normal") is StyleBoxEmpty)
  game._say("omer: Yolu açık tut. Yanındayım.",true);game._update_hud()
  h.check("real character dialogue keeps its panel",game.ui_panels[1].visible and game.bubble.visible)
  game.boss.active=true;game.boss.stage=0;game.boss.hp=200;game.boss.max_hp=200
  for rear_y in [200,390,500]:
   game.boss.rear=rear_y>200;game.boss.position.y=rear_y;game._update_hud();await frames()
   h.check("boss instruction fits without covering radio %s y%d"%[view,rear_y],TextFit.fits(game.story_caption) and not game.story_caption.get_global_rect().intersects(game.ui_panels[1].get_global_rect()))
  if view.y>view.x:
   h.check("mobile metrics clear boss bar",not game.distance_caption.get_global_rect().intersects(game.route_bar.get_global_rect()) and not game.score_label.get_global_rect().intersects(game.distance_caption.get_global_rect()))
  game.boss.active=false
  for action in Controls.RETIRED:
   h.check("removed action has no physical bindings",InputMap.action_get_events(action).is_empty())
   Input.action_press(action);game._direct_action(action)
   h.check("old synthetic hold cannot reactivate ability",not game._held(action))
   Input.action_release(action)
  for kind in ["rammer","pickup"]:
   var spawn: float=game._traffic_spawn_y(kind)
   var visible_top: float=game.world_origin.y+(spawn-54)*game.scale.y
   h.check("entire rear car begins beyond actual viewport %s %s"%[kind,view],visible_top>view.y+50)
   game.enemies.clear();game._add_enemy(kind,1,spawn);game._update_enemies(.1)
   h.eq("distant rear spawn is retained until arrival",game.enemies.size(),1)
   h.check("arrival moves forward continuously",game.enemies[0]["pos"].y<spawn and game.enemies[0]["pos"].y>spawn-60)
   var before: Vector2=game.enemies[0]["pos"];game._layout();h.eq("layout never teleports existing traffic",game.enemies[0]["pos"],before)
  game.enemies.clear();game.distance=0;game.spawn_timer=0;game._spawn(.01)
  h.check("normal real spawner also starts offscreen",game.enemies.size()==1 and absf(game.enemies[0]["pos"].y-game._traffic_spawn_y(game.enemies[0]["type"]))<.01)
  game.queue_free();await frames()
 Controls.install();Session.story_mode=false;quit(h.finish())
