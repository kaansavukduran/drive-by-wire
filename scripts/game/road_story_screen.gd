extends Node2D
## Two authored interludes; shared compact dialogue, pause and checkpoint UI.
const Story=preload("res://scripts/core/road_story.gd")
const CliffStory=preload("res://scripts/core/cliff_story.gd")
var story_model: Script=Story
var cliff_scene:=false
var cliff_cast: Node2D
var cliff_kurt: Sprite2D
var cliff_aion: Sprite2D
const Book=preload("res://scripts/core/story_book.gd")
const Store=preload("res://scripts/core/save_store.gd")
const Session=preload("res://scripts/game/session.gd")
const Vehicles=preload("res://scripts/core/vehicles.gd")
const UiSkin=preload("res://scripts/game/ui_skin.gd")
const Controls=preload("res://scripts/game/controls.gd")
const Portrait=preload("res://scripts/game/cast_portrait.gd")
const TextFit=preload("res://scripts/game/text_fit.gd")
const Sounds=preload("res://scripts/game/sounds.gd")
const Sheets=preload("res://scripts/game/sheets.gd")
const QA=preload("res://scripts/game/qa_snapshot.gd")
const VisualArt=preload("res://scripts/game/visual_art.gd")
const Art=preload("res://scripts/game/story_cast_art.gd")
const CRASH=preload("res://assets/sprites/emre_trap.png")
const DRIVER=preload("res://assets/sprites/aion_roadster.png")
const EMRE_BODY=preload("res://assets/sprites/courier_body.png")
const ROAD=preload("res://assets/road/road_tile.png")
var store:=Store.new()
var save: Dictionary
var campaign: Dictionary
var chapter: Dictionary
var elapsed:=0.0
var road_time:=0.0
var pose_time:=0.0
var paused:=false
var save_failed:=false
var motion:=true
var effects:=true
var completed:=false
var panel: Panel
var heading: Label
var speaker: Label
var body: Label
var page_caption: Label
var portrait: Control
var next_button: Button
var choices: Array[Button]=[]
var pause_button: Button
var pause_panel: Panel
var resume_button: Button
var leave_button: Button
var warning: Label
var pages: Array[String]=[]
var page:=0
var reading_offset:=0
var stage_rect:=Rect2()
var sounds: Node
var sheets:=Sheets.new()
var car_texture: Texture2D
var layout_ready:=false
var last_portrait:=false
var cast_stage: Node2D
var cast_sprites: Dictionary={}
var ground_time:=0.0
var step_time:=0.0
func _ready() -> void:
 material=VisualArt.material()
 Engine.time_scale=1
 save=store.load_data();car_texture=Vehicles.texture_for(save.get("vehicle"))
 campaign=Book.sanitize(Session.campaign_state if not Session.campaign_state.is_empty() else save["campaign"])
 if campaign["phase"]!="interlude":
  get_tree().call_deferred("change_scene_to_file","res://scenes/journey.tscn");return
 cliff_scene=int(campaign["stage"])==1
 story_model=CliffStory if cliff_scene else Story
 chapter=story_model.sanitize(campaign["cliff" if cliff_scene else "chapter2"])
 motion=save["settings"]["motion"];effects=save["settings"]["effects"]
 Controls.install(save["settings"]["bindings"],save["settings"]["pad_bindings"],save["settings"]["deadzone"])
 sounds=Sounds.new();sounds.enabled=save["settings"]["sound"];sounds.volume=save["settings"]["volume"];add_child(sounds)
 _build_cast()
 _build_cliff_cast()
 panel=Panel.new();panel.theme=UiSkin.theme();panel.add_theme_stylebox_override("panel",UiSkin.panel());add_child(panel)
 heading=_label(self,"Yan yana · İkinci bölüm",13)
 speaker=_label(panel,"",12);speaker.theme_type_variation="AccentLabel"
 body=_label(panel,"",13)
 page_caption=_label(panel,"",10);page_caption.theme_type_variation="MutedLabel"
 portrait=Portrait.new();panel.add_child(portrait);portrait.custom_minimum_size=Vector2.ZERO
 next_button=_button(panel,"Devam · A / Enter",_next)
 for i in 2:choices.append(_button(panel,"",func():_choose(i)))
 pause_button=_button(self,"Mola",func():_pause(true))
 pause_panel=Panel.new();pause_panel.theme=UiSkin.theme();pause_panel.add_theme_stylebox_override("panel",UiSkin.panel());pause_panel.z_index=20;add_child(pause_panel)
 warning=_label(pause_panel,"Mola · Sahne durdu. Seçimlerin bu cihazda saklanır.",13)
 resume_button=_button(pause_panel,"Devam et · A",func():_pause(false))
 leave_button=_button(pause_panel,"Ana menüye dön",_leave)
 pause_panel.hide()
 get_viewport().size_changed.connect(_layout)
 Input.joy_connection_changed.connect(func(_id: int,connected: bool):
  if not connected:_pause(true))
 _present();_layout();_focus()
func _label(parent: Node,text: String,font_size: int) -> Label:
 var l:=Label.new();l.theme=UiSkin.theme();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",font_size);parent.add_child(l);return l
func _button(parent: Node,text: String,action: Callable) -> Button:
 var b:=Button.new();b.theme=UiSkin.theme();b.text=text;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.clip_text=true;UiSkin.style_button(b);b.pressed.connect(action);parent.add_child(b);return b
func _cinematic() -> bool:return float(story_model.data()["nodes"][chapter["step"]].get("duration",0))>0
func _ground_scene() -> bool:return not cliff_scene and chapter.get("step") in ["aftermath","eren","plea","reveal","promise","rescue","witness","handoff","complete"]
func _present() -> void:
 var node: Dictionary=story_model.data()["nodes"][chapter["step"]]
 var cinema:=_cinematic()
 speaker.text=str(Portrait.NAMES[node.get("speaker","omega")])
 portrait.speaker=node.get("speaker","omega")
 next_button.visible=not cinema
 for i in choices.size():
  choices[i].visible=not cinema and node.has("choices")
  if choices[i].visible:choices[i].text=str(node["choices"][i]["label"])
 next_button.visible=not cinema and not node.has("choices")
 next_button.text=("Devam edecek · A" if cliff_scene else "2. etaba geç · A") if chapter["step"]=="complete" else "Devam · A / Enter"
 _layout();_focus();queue_redraw()
func _reflow(remember: bool=true) -> void:
 if remember:reading_offset=TextFit.offset_at(pages,page)
 var node: Dictionary=story_model.data()["nodes"][chapter["step"]]
 var prose: String=str(node.get("text",node.get("caption","")))
 if cliff_scene and chapter["step"]=="thanks" and chapter.get("reply")=="joke":prose="Teşekkür ederim, Kurt. Şakayı sonra yaparım… Bir saniye daha geç kalsaydın…"
 pages=TextFit.pages(prose,body)
 page=TextFit.page_at(pages,reading_offset)
 body.text=pages[page]
 page_caption.text=""
 page_caption.hide()
 heading.text="Kayıt yazılamadı · oturumda korunuyor" if save_failed else ("Uçurumun kıyısı · 2. ara sahne" if cliff_scene else "Yan yana · 1. ara sahne")
 var who: String=str(Portrait.NAMES[node.get("speaker","omega")])
 speaker.text=who+((" · %d / %d" % [page+1,pages.size()]) if pages.size()>1 else "")
 # Choices are actionable only after the whole speech is read.
 if not _cinematic() and node.has("choices"):
  for b in choices:b.visible=page==pages.size()-1
  next_button.visible=page<pages.size()-1
  next_button.text="Repliği sürdür · A"
 _links()
func _links() -> void:
 var actions: Array=choices.filter(func(b):return b.visible)
 if next_button.visible:actions.append(next_button)
 actions.append(pause_button)
 for i in actions.size():
  for direction in ["top","left"]:actions[i].set("focus_neighbor_"+direction,actions[i].get_path_to(actions[posmod(i-1,actions.size())]))
  for direction in ["bottom","right"]:actions[i].set("focus_neighbor_"+direction,actions[i].get_path_to(actions[(i+1)%actions.size()]))
 for direction in ["top","bottom","left","right"]:
  resume_button.set("focus_neighbor_"+direction,resume_button.get_path_to(leave_button));leave_button.set("focus_neighbor_"+direction,leave_button.get_path_to(resume_button))
func _focus() -> void:
 if paused:resume_button.grab_focus()
 elif choices[0].visible:choices[0].grab_focus()
 elif next_button.visible:next_button.grab_focus()
 else:pause_button.grab_focus()
func _next() -> void:
 if paused or _cinematic():return
 if page+1<pages.size():page+=1;_reflow();_focus();return
 if chapter["step"]=="complete":_finish();return
 if story_model.data()["nodes"][chapter["step"]].has("choices"):return
 chapter=story_model.advance(chapter);_enter()
func _choose(index: int) -> void:
 if paused or index<0 or index>=choices.size() or not choices[index].visible:return
 var options: Array=story_model.data()["nodes"][chapter["step"]].get("choices",[])
 if options.size()!=2:return
 chapter=story_model.choose(chapter,str(options[index]["id"]));_enter()
func _enter() -> void:
 elapsed=0;page=0;reading_offset=0;step_time=0
 if chapter["step"]=="aftermath":ground_time=0
 _checkpoint();_present()
 if chapter["step"]=="trap":sounds.cue("kill")
func _checkpoint() -> bool:
 chapter=story_model.sanitize(chapter)
 campaign["cliff" if cliff_scene else "chapter2"]=chapter.duplicate(true)
 save["campaign"]=campaign
 Session.campaign_state=campaign.duplicate(true)
 save_failed=not store.save_data(save);Session.campaign_save_failed=save_failed
 return not save_failed
func _finish() -> void:
 if not _commit_completion():return
 get_tree().call_deferred("change_scene_to_file","res://scenes/ending.tscn" if cliff_scene else "res://scenes/journey.tscn")
func _commit_completion() -> bool:
 if completed or chapter["step"]!="complete":return false
 completed=true
 if not cliff_scene:
  if not chapter.get("record","").is_empty():campaign["bonds"]["eren"]=mini(3,int(campaign["bonds"].get("eren",0))+1)
 campaign["cliff" if cliff_scene else "chapter2"]=chapter.duplicate(true)
 campaign=Book.finish_interlude(campaign)
 _checkpoint()
 return true
func _pause(value: bool) -> void:
 paused=value;pause_panel.visible=value
 warning.text="Kayıt yazılamadı. İlerleme bu oturumda." if save_failed else "Mola · Sahne durdu. Seçimlerin bu cihazda saklanır."
 panel.visible=not value;pause_button.disabled=value;_focus()
func _leave() -> void:
 _checkpoint();get_tree().call_deferred("change_scene_to_file","res://scenes/title.tscn")
func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(pause_panel):_pause(true)
func _input(event: InputEvent) -> void:Controls.observe(event)
func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("drive_pause") or event.is_action_pressed("ui_cancel"):
  _pause(not paused);get_viewport().set_input_as_handled()
 elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_1,KEY_2]:
  _choose(event.keycode-KEY_1);get_viewport().set_input_as_handled()
func _process(delta: float) -> void:
 if not paused:
  pose_time+=delta;step_time+=delta
  if _ground_scene():ground_time+=delta
  if _cinematic():
   elapsed+=delta
   if motion:road_time+=delta*(100 if chapter["step"]=="race" else 22)
   if elapsed>=float(story_model.data()["nodes"][chapter["step"]]["duration"]):chapter=story_model.advance(chapter);_enter()
 _sync_cast();_sync_cliff_cast()
 queue_redraw()
 if QA.active():QA.publish("road_story",snapshot())
func _layout() -> void:
 if not is_instance_valid(panel):return
 var v:=get_viewport_rect().size;var p:=v.y>v.x
 if layout_ready and p!=last_portrait:_pause(true)
 last_portrait=p;layout_ready=true
 var reserved_height:=188.0 if p else 132.0
 var has_choices: bool=story_model.data()["nodes"][chapter["step"]].has("choices")
 var panel_width:=minf(v.x-16,340 if _cinematic() else 440)
 var cinema_body_height:=36.0
 if _cinematic():
  var probe:=TextFit.probe_for(body);probe.size.x=panel_width-20
  var node: Dictionary=story_model.data()["nodes"][chapter["step"]]
  cinema_body_height=ceilf(TextFit.height(probe,str(node.get("text",node.get("caption","")))))
  probe.free()
 var height:=38+cinema_body_height if _cinematic() else ((188.0 if has_choices else 140.0) if p else 132.0)
 # Same fixed layout throughout the chapter: no panel or actor jump per speech.
 panel.size=Vector2(panel_width,height);panel.position=Vector2((v.x-panel.size.x)/2,v.y-height-8)
 heading.position=Vector2(12,8);heading.size=Vector2(v.x-112,24)
 pause_button.position=Vector2(v.x-92,4);pause_button.size=Vector2(84,44)
 portrait.position=Vector2(8,6);portrait.size=Vector2(30,30)
 speaker.position=Vector2(46,6);speaker.size=Vector2(panel.size.x-56,20)
 if _cinematic():portrait.size=Vector2(24,24);speaker.position.x=40
 body.position=Vector2(10,30 if _cinematic() else 40);body.size=Vector2(panel.size.x-20,cinema_body_height if _cinematic() else 36)
 page_caption.position=Vector2(12,114 if p else 97);page_caption.size=Vector2(panel.size.x-24,16)
 next_button.position=Vector2(12,height-50);next_button.size=Vector2(panel.size.x-24,44)
 for i in choices.size():
  choices[i].position=Vector2(12+(0 if p else i*(panel.size.x-16)/2),height-102+i*50 if p else height-50)
  choices[i].size=Vector2(panel.size.x-24 if p else (panel.size.x-32)/2,44)
 stage_rect=Rect2(0,48,v.x,v.y-reserved_height-64)
 pause_panel.size=Vector2(minf(v.x-24,420),176);pause_panel.position=(v-pause_panel.size)/2
 warning.position=Vector2(12,10);warning.size=Vector2(pause_panel.size.x-24,54)
 resume_button.position=Vector2(12,70);resume_button.size=Vector2(pause_panel.size.x-24,44)
 leave_button.position=Vector2(12,122);leave_button.size=Vector2(pause_panel.size.x-24,44)
 _reflow(false);_sync_cast();_sync_cliff_cast();queue_redraw()
func actor_positions() -> Array[Vector2]:
 if _ground_scene():return Art.positions()
 var lead:=0.0
 if chapter.get("pace")=="race" and chapter["step"]=="race" and motion:lead=sin(clampf(elapsed/8.0,0,1)*PI)*20
 return [Vector2(270,190),Vector2(370,190-lead)]
func injury_frame() -> int:return Art.frame("emre",ground_time,step_time,chapter.get("step","aftermath"),motion)
func _draw_car(at: Vector2,companion: bool) -> void:
 VisualArt.vehicle_at(self,3 if companion else Vehicles.index(save.get("vehicle")),at,Color(.55,.55,.55) if companion and chapter["step"]=="trap" else Color.WHITE)
func _build_cast() -> void:
 cast_stage=Node2D.new();cast_stage.name="GroundedStoryCast";add_child(cast_stage)
 var positions:=Art.positions()
 for i in Art.IDS.size():
  var who: String=Art.IDS[i];var sprite:=Sprite2D.new();sprite.name=who
  sprite.position=positions[i];Art.configure(sprite,who,0);cast_stage.add_child(sprite);cast_sprites[who]=sprite
func _cast_projection() -> Transform2D:
 var v:=get_viewport_rect().size
 var zoom:=minf(v.x/480.0,maxf(40,stage_rect.size.y-8)/164.0)
 var floor_y:=v.y-(188.0 if v.y>v.x else 132.0)-24.0
 return Transform2D(0,Vector2.ONE*zoom,0,Vector2(v.x/2-320*zoom,floor_y-248*zoom))
func _sync_cast() -> void:
 if not is_instance_valid(cast_stage) or chapter.is_empty():return
 cast_stage.visible=_ground_scene()
 cast_stage.transform=_cast_projection()
 for who in Art.IDS:Art.configure(cast_sprites[who],who,Art.frame(who,ground_time,step_time,chapter["step"],motion))
func _cast_snapshot() -> Array:
 var out: Array=[]
 if not is_instance_valid(cast_stage) or not cast_stage.visible:return out
 for who in Art.IDS:
  var sprite: Sprite2D=cast_sprites[who];var at:=sprite.global_position
  var index:=Art.frame(who,ground_time,step_time,chapter["step"],motion)
  out.append({"id":who,"frame":index,"world":[sprite.position.x,sprite.position.y],"contact":[at.x,at.y],"anchor":[-sprite.offset.x,-sprite.offset.y]})
 return out
func _draw() -> void:
 if chapter.is_empty():return
 var v:=get_viewport_rect().size
 draw_rect(Rect2(Vector2.ZERO,v),UiSkin.color("background"))
 if cliff_scene:
  _draw_cliff()
 elif _ground_scene():
  var projection:=_cast_projection()
  var floor_y:=projection*Vector2(0,248)
  # Road support is authored at source y777. The background may crop in
  # portrait, but supports and every planted actor use the same visible plane.
  var bg_scale:=maxf(v.x/1536.0,floor_y.y/777.0)
  var bg_x:=v.x-1536*bg_scale if v.y>v.x else (v.x-1536*bg_scale)/2
  draw_texture_rect(Art.BACKGROUND,Rect2(Vector2(bg_x,floor_y.y-777*bg_scale),Vector2(1536,1024)*bg_scale),false)
  draw_set_transform_matrix(projection)
  draw_ellipse_shadow(Vector2(240,249),Vector2(48,5))
  draw_ellipse_shadow(Vector2(347,252),Vector2(100,6))
  draw_ellipse_shadow(Vector2(495,249),Vector2(31,4))
 else:
  var zoom:=minf(stage_rect.size.x/480.0,stage_rect.size.y/210.0)
  var origin:=stage_rect.get_center()-Vector2(320,176)*zoom
  draw_set_transform(origin,0,Vector2.ONE*zoom)
  var positions:=actor_positions()
  draw_rect(Rect2(90,-300,460,1100),Color("1c3835"))
  VisualArt.road(self,2,road_time,520)
  _draw_car(positions[0],false);_draw_car(positions[1],true)
  if chapter["step"]=="trap":
   if effects:
    VisualArt.explosion(self,positions[1],minf(elapsed,.59),90)


 draw_set_transform(Vector2.ZERO)
func draw_ellipse_shadow(at: Vector2,extent: Vector2) -> void:
 var polygon:=PackedVector2Array()
 for i in 20:polygon.append(at+Vector2(cos(i*TAU/20)*extent.x,sin(i*TAU/20)*extent.y))
 draw_colored_polygon(polygon,Color(0.02,0.025,0.04,0.26))
func snapshot() -> Dictionary:
 return {"view":[get_viewport_rect().size.x,get_viewport_rect().size.y],"chapter":chapter.duplicate(true),"elapsed":elapsed,"paused":paused,"page":page,"anchor":reading_offset,"pages":pages.size(),"text":body.text,"speaker":speaker.text,"body":QA.rect(body),"portrait":QA.rect(portrait),"speaker_rect":QA.rect(speaker),"panel":QA.rect(panel),"next":QA.rect(next_button),"next_visible":next_button.visible,"choices":choices.filter(func(b):return b.visible).map(func(b):return QA.rect(b)),"pause":QA.rect(pause_button),"resume":QA.rect(resume_button),"leave":QA.rect(leave_button),"fits":TextFit.fits(heading) and TextFit.fits(body) and TextFit.fits(speaker) and TextFit.fits(page_caption),"cast":_cast_snapshot(),"actors":actor_positions().map(func(pos):return [pos.x,pos.y]),"frame":injury_frame(),"interlude":2 if cliff_scene else 1,"cliff":_cliff_snapshot() if cliff_scene else {},"combat":false,"vehicle":save["vehicle"],"save_failed":save_failed}

func _cliff_projection() -> Transform2D:
 var zoom:=minf(stage_rect.size.x/(360.0 if last_portrait else 640.0),stage_rect.size.y/164.0)
 return Transform2D(0,Vector2.ONE*zoom,0,stage_rect.get_center()-Vector2(320,170)*zoom)
func _build_cliff_cast() -> void:
 cliff_cast=Node2D.new();cliff_cast.name="CliffCast";add_child(cliff_cast)
 cliff_aion=Sprite2D.new();VisualArt.standing(cliff_aion,"aion");cliff_cast.add_child(cliff_aion)
 cliff_kurt=Sprite2D.new();cliff_kurt.material=VisualArt.material();cliff_kurt.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;cliff_cast.add_child(cliff_kurt)
func _sync_cliff_cast() -> void:
 if not is_instance_valid(cliff_cast) or chapter.is_empty():return
 cliff_cast.visible=cliff_scene and CliffStory.poses(chapter["step"],elapsed,not motion)["actors"]
 if not cliff_cast.visible:return
 var pose:=CliffStory.poses(chapter["step"],elapsed,not motion)
 cliff_cast.transform=_cliff_projection()
 cliff_aion.position=pose["aion_foot"]
 cliff_kurt.position=pose["kurt_foot"]
 var rect:=VisualArt.region("kurt_scene",pose["frame"])
 var contact: Array=VisualArt.data()["kurt_scene_feet"][pose["frame"]]
 cliff_kurt.texture=VisualArt.texture("kurt_scene");cliff_kurt.region_enabled=true;cliff_kurt.region_filter_clip_enabled=true
 cliff_kurt.region_rect=rect;cliff_kurt.centered=false;cliff_kurt.offset=-Vector2(contact[0],contact[1]);cliff_kurt.scale=Vector2.ONE*(60.0/rect.size.y)
func _draw_cliff() -> void:
 var pose:=CliffStory.poses(chapter["step"],elapsed,not motion)
 draw_set_transform_matrix(_cliff_projection())
 draw_texture_rect(VisualArt.texture("cliff"),Rect2(0,0,640,360),false)
 if pose["wrecked"]:VisualArt.at(self,"cliff_cars",Vehicles.index(save.get("vehicle"))+1,pose["aion_car"],Vector2(48,74))
 else:VisualArt.vehicle_at(self,Vehicles.index(save.get("vehicle")),pose["aion_car"])
 draw_set_transform_matrix(_cliff_projection()*Transform2D(PI/2,pose["kurt_car"]))
 VisualArt.at(self,"cliff_cars",0,Vector2.ZERO,Vector2(48,74))
 draw_set_transform_matrix(_cliff_projection())
 if chapter["step"]=="impact" and effects and motion:VisualArt.at(self,"gadgets",7,pose["aion_car"]+Vector2(-22,0),Vector2(32,32),Color(1,1,1,clampf(1-elapsed/.6,0,1)))
 if pose["wrecked"] and effects:VisualArt.at(self,"weapons",3,pose["aion_car"]+Vector2(0,-22),Vector2(24,30),Color(1,1,1,.6))
 draw_set_transform(Vector2.ZERO)
func _cliff_snapshot() -> Dictionary:
 var pose:=CliffStory.poses(chapter["step"],elapsed,not motion)
 return {"aion_car":[pose["aion_car"].x,pose["aion_car"].y],"kurt_car":[pose["kurt_car"].x,pose["kurt_car"].y],"edge_y":pose["edge_y"],"wrecked":pose["wrecked"],"actors":pose["actors"],"frame":pose["frame"],"aion_foot":[pose["aion_foot"].x,pose["aion_foot"].y],"kurt_foot":[pose["kurt_foot"].x,pose["kurt_foot"].y]}
