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
const DialogueSkip=preload("res://scripts/game/dialogue_skip.gd")
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
var skip_button: DialogueSkip
var caption_skipped:=false
var cliff_pose: Dictionary={}
var cliff_frame:=-1
var aion_exit_frame:=-1
var cast_frames: Dictionary={}
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
 skip_button=DialogueSkip.new();skip_button.theme=UiSkin.theme();UiSkin.style_button(skip_button);panel.add_child(skip_button)
 skip_button.skip_line.connect(_skip_line);skip_button.skip_remaining.connect(_skip_remaining)
 pause_button=_button(self,"Mola",func():_pause(true))
 pause_panel=Panel.new();pause_panel.theme=UiSkin.theme();pause_panel.add_theme_stylebox_override("panel",UiSkin.panel());pause_panel.z_index=20;add_child(pause_panel)
 warning=_label(pause_panel,"Mola · Sahne durdu. İlerlemen bu cihazda saklanır.",13)
 resume_button=_button(pause_panel,"Devam et · A",func():_pause(false))
 leave_button=_button(pause_panel,"Ana menüye dön",_leave)
 pause_panel.hide()
 get_viewport().size_changed.connect(_layout)
 Input.joy_connection_changed.connect(func(_id: int,connected: bool):
  if not connected:_pause(true))
 _present();_sync_audio()
 if chapter.get("skip_dialogue",false) and not _cinematic():_fast_forward_dialogue.call_deferred()
func _label(parent: Node,text: String,font_size: int) -> Label:
 var l:=Label.new();l.theme=UiSkin.theme();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",font_size);parent.add_child(l);return l
func _button(parent: Node,text: String,action: Callable) -> Button:
 var b:=Button.new();b.theme=UiSkin.theme();b.text=text;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.clip_text=true;UiSkin.style_button(b);b.pressed.connect(action);parent.add_child(b);return b
func _cinematic() -> bool:return float(story_model.data()["nodes"][chapter["step"]].get("duration",0))>0
func _ground_scene() -> bool:return not cliff_scene and chapter.get("step") in ["aftermath","eren","plea","reveal","promise","rescue","witness","keep_sealed","handoff","complete"]
func _present() -> void:
 var node: Dictionary=story_model.data()["nodes"][chapter["step"]]
 var cinema:=_cinematic()
 speaker.text=str(Portrait.NAMES[node.get("speaker","omega")])
 portrait.speaker=node.get("speaker","omega")
 panel.visible=not paused and not (cinema and (caption_skipped or chapter.get("skip_dialogue",false)))
 next_button.visible=not cinema
 skip_button.visible=panel.visible
 next_button.text=("Devam edecek" if cliff_scene else "2. etaba geç") if chapter["step"]=="complete" else "Devam"
 _layout();_focus();queue_redraw()
func _reflow(remember: bool=true) -> void:
 if remember:reading_offset=TextFit.offset_at(pages,page)
 var node: Dictionary=story_model.data()["nodes"][chapter["step"]]
 var prose: String=str(node.get("text",node.get("caption","")))
 pages=TextFit.pages(prose,body)
 page=TextFit.page_at(pages,reading_offset)
 body.text=pages[page]
 if cliff_scene and chapter["step"]=="brake" and elapsed<1.34:body.text="Tekerlekler zeminde. Biraz daha…"
 page_caption.text=""
 page_caption.hide()
 heading.text="Kayıt yazılamadı · oturumda korunuyor" if save_failed else ("Uçurumun kıyısı · 2. ara sahne" if cliff_scene else "Yan yana · 1. ara sahne")
 var who: String=str(Portrait.NAMES[node.get("speaker","omega")])
 speaker.text=who+((" · %d / %d" % [page+1,pages.size()]) if pages.size()>1 else "")
 _links()
func _links() -> void:
 var actions: Array[Button]=[]
 if panel.visible and next_button.visible:actions.append(next_button)
 if panel.visible and skip_button.visible:actions.append(skip_button)
 actions.append(pause_button)
 for i in actions.size():
  for direction in ["top","left"]:actions[i].set("focus_neighbor_"+direction,actions[i].get_path_to(actions[posmod(i-1,actions.size())]))
  for direction in ["bottom","right"]:actions[i].set("focus_neighbor_"+direction,actions[i].get_path_to(actions[(i+1)%actions.size()]))
 for direction in ["top","bottom","left","right"]:
  resume_button.set("focus_neighbor_"+direction,resume_button.get_path_to(leave_button));leave_button.set("focus_neighbor_"+direction,leave_button.get_path_to(resume_button))
func _focus() -> void:
 if paused:resume_button.grab_focus()
 elif panel.visible and next_button.visible:next_button.grab_focus()
 elif panel.visible and skip_button.visible:skip_button.grab_focus()
 else:pause_button.grab_focus()
func _next() -> void:
 if paused or _cinematic():return
 if page+1<pages.size():page+=1;_reflow();_focus();return
 _advance_dialogue()
func _advance_dialogue() -> void:
 if chapter["step"]=="complete":_finish();return
 chapter=story_model.advance(chapter)
 _enter()
func _skip_line() -> void:
 if paused or completed:return
 if _cinematic():
  caption_skipped=true
  _present()
 else:_advance_dialogue()
func _skip_remaining() -> void:
 if paused or completed:return
 chapter["skip_dialogue"]=true
 if _cinematic():
  _checkpoint()
  _present()
 else:_fast_forward_dialogue()
func _fast_forward_dialogue() -> void:
 while not _cinematic() and chapter["step"]!="complete":
  chapter=story_model.advance(chapter)
 if chapter["step"]=="complete":_finish()
 else:_enter()
func _enter() -> void:
 elapsed=0;page=0;reading_offset=0;step_time=0;caption_skipped=false
 if chapter.get("skip_dialogue",false) and not _cinematic():
  _fast_forward_dialogue()
  return
 if chapter["step"]=="aftermath":ground_time=0
 _checkpoint();_present();_sync_audio()
 if chapter["step"]=="trap":sounds.cue("mine_boom" if sounds.streams.has("mine_boom") else "kill")
 if cliff_scene and chapter["step"]=="impact":sounds.cue("hit")
func _sync_audio() -> void:
 if not is_instance_valid(sounds):return
 if cliff_scene:sounds.set_bed("cliff" if chapter.get("step") in ["approach","impact","brake","exit"] else "aftermath")
 else:sounds.set_bed("aftermath" if _ground_scene() else "road")
func _checkpoint() -> bool:
 chapter=story_model.sanitize(chapter)
 campaign["cliff" if cliff_scene else "chapter2"]=chapter.duplicate(true)
 save["campaign"]=campaign
 Session.campaign_state=campaign.duplicate(true)
 save_failed=not store.save_data(save);Session.campaign_save_failed=save_failed
 return not save_failed
func _finish() -> void:
 if not _commit_completion():return
 if is_instance_valid(sounds):sounds.stop_all()
 get_tree().call_deferred("change_scene_to_file","res://scenes/ending.tscn" if cliff_scene else "res://scenes/journey.tscn")
func _commit_completion() -> bool:
 if completed or chapter["step"]!="complete":return false
 completed=true
 campaign["cliff" if cliff_scene else "chapter2"]=chapter.duplicate(true)
 campaign=Book.finish_interlude(campaign)
 _checkpoint()
 return true
func _pause(value: bool) -> void:
 paused=value;pause_panel.visible=value
 if is_instance_valid(sounds):sounds.set_paused(value)
 warning.text="Kayıt yazılamadı. İlerleme bu oturumda." if save_failed else "Mola · Sahne durdu. İlerlemen bu cihazda saklanır."
 panel.visible=not value and not (_cinematic() and (caption_skipped or chapter.get("skip_dialogue",false)))
 pause_button.disabled=value;_links();_focus()
func _leave() -> void:
 if is_instance_valid(sounds):sounds.stop_all()
 _checkpoint();get_tree().call_deferred("change_scene_to_file","res://scenes/title.tscn")
func _exit_tree() -> void:
 if is_instance_valid(sounds):sounds.stop_all()
func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(pause_panel):_pause(true)
func _input(event: InputEvent) -> void:Controls.observe(event)
func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("drive_pause") or event.is_action_pressed("ui_cancel"):
  _pause(not paused);get_viewport().set_input_as_handled()
func _process(delta: float) -> void:
 if not paused and not completed:
  step_time+=delta
  if _ground_scene():ground_time+=delta
  if _cinematic():
   elapsed+=delta
   if motion:road_time+=delta*(100 if chapter["step"]=="race" else 22)
   if elapsed>=float(story_model.data()["nodes"][chapter["step"]]["duration"]):
    chapter=story_model.advance(chapter)
    _enter()
   else:
    _sync_cliff_pose()
    if cliff_scene and chapter["step"]=="brake" and cliff_pose["settled"] and body.text!=pages[page]:body.text=pages[page]
    queue_redraw()
  _sync_cast()
 if QA.active():QA.publish("road_story",snapshot())
func _layout() -> void:
 if not is_instance_valid(panel):return
 var v:=get_viewport_rect().size;var p:=v.y>v.x
 if layout_ready and p!=last_portrait:_pause(true)
 last_portrait=p;layout_ready=true
 var reserved_height:=188.0 if p else 132.0
 var panel_width:=minf(v.x-16,340 if _cinematic() else 440)
 var cinema_body_height:=36.0
 if _cinematic():
  var probe:=TextFit.probe_for(body);probe.size.x=panel_width-20
  var node: Dictionary=story_model.data()["nodes"][chapter["step"]]
  cinema_body_height=ceilf(TextFit.height(probe,str(node.get("text",node.get("caption","")))))
  probe.free()
 var height:=62+cinema_body_height if _cinematic() else (140.0 if p else 132.0)
 # Same fixed layout throughout the chapter: no panel or actor jump per speech.
 panel.size=Vector2(panel_width,height);panel.position=Vector2((v.x-panel.size.x)/2,v.y-height-8)
 heading.position=Vector2(12,8);heading.size=Vector2(v.x-112,24)
 pause_button.position=Vector2(v.x-92,4);pause_button.size=Vector2(84,44)
 portrait.position=Vector2(8,6);portrait.size=Vector2(30,30)
 speaker.position=Vector2(46,6);speaker.size=Vector2(panel.size.x-56,20)
 if _cinematic():
  portrait.size=Vector2(24,24);speaker.position.x=40;speaker.size.x=panel.size.x-146
 body.position=Vector2(10,52 if _cinematic() else 40);body.size=Vector2(panel.size.x-20,cinema_body_height if _cinematic() else 36)
 page_caption.position=Vector2(12,114 if p else 97);page_caption.size=Vector2(panel.size.x-24,16)
 next_button.position=Vector2(12,height-50);next_button.size=Vector2(panel.size.x-120,44)
 skip_button.position=Vector2(panel.size.x-100,4 if _cinematic() else height-50)
 skip_button.size=Vector2(88,44)
 stage_rect=Rect2(0,48,v.x,v.y-reserved_height-64)
 pause_panel.size=Vector2(minf(v.x-24,420),176);pause_panel.position=(v-pause_panel.size)/2
 warning.position=Vector2(12,10);warning.size=Vector2(pause_panel.size.x-24,54)
 resume_button.position=Vector2(12,70);resume_button.size=Vector2(pause_panel.size.x-24,44)
 leave_button.position=Vector2(12,122);leave_button.size=Vector2(pause_panel.size.x-24,44)
 _reflow(false);_sync_cast();_sync_cliff_pose();queue_redraw()
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
 for who in Art.IDS:
  var frame:=Art.frame(who,ground_time,step_time,chapter["step"],motion)
  if cast_frames.get(who,0)!=frame:
   Art.set_frame(cast_sprites[who],who,frame)
   cast_frames[who]=frame
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
 return {"view":[get_viewport_rect().size.x,get_viewport_rect().size.y],"chapter":chapter.duplicate(true),"elapsed":elapsed,"paused":paused,"page":page,"anchor":reading_offset,"pages":pages.size(),"text":body.text,"speaker":speaker.text,"body":QA.rect(body),"portrait":QA.rect(portrait),"speaker_rect":QA.rect(speaker),"panel":QA.rect(panel),"next":QA.rect(next_button),"next_visible":next_button.visible,"skip":QA.rect(skip_button),"skip_visible":skip_button.is_visible_in_tree(),"skip_menu":skip_button.get_popup().visible,"skip_popup":skip_button.popup_bounds(),"caption_visible":panel.is_visible_in_tree(),"pause":QA.rect(pause_button),"resume":QA.rect(resume_button),"leave":QA.rect(leave_button),"fits":TextFit.fits(heading) and TextFit.fits(body) and TextFit.fits(speaker) and TextFit.fits(page_caption),"cast":_cast_snapshot(),"actors":actor_positions().map(func(pos):return [pos.x,pos.y]),"frame":injury_frame(),"interlude":2 if cliff_scene else 1,"cliff":_cliff_snapshot() if cliff_scene else {},"combat":false,"music":sounds.music_snapshot(),"vehicle":save["vehicle"],"save_failed":save_failed}

func _cliff_projection() -> Transform2D:
 var zoom:=minf(stage_rect.size.x/(360.0 if last_portrait else 640.0),stage_rect.size.y/164.0)
 return Transform2D(0,Vector2.ONE*zoom,0,stage_rect.get_center()-Vector2(320,170)*zoom)
func _build_cliff_cast() -> void:
 if not cliff_scene:return
 cliff_cast=Node2D.new();cliff_cast.name="CliffCast";add_child(cliff_cast)
 cliff_aion=Sprite2D.new();cliff_cast.add_child(cliff_aion)
 cliff_aion.texture=VisualArt.texture("aion_cliff")
 cliff_aion.region_enabled=true;cliff_aion.region_filter_clip_enabled=true
 cliff_aion.centered=false;cliff_aion.offset=Vector2(-48,-82);cliff_aion.scale=Vector2.ONE*.62
 cliff_aion.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 cliff_kurt=Sprite2D.new();cliff_kurt.material=VisualArt.material();cliff_kurt.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;cliff_cast.add_child(cliff_kurt)
 cliff_kurt.texture=VisualArt.texture("kurt_scene")
 cliff_kurt.region_enabled=true;cliff_kurt.region_filter_clip_enabled=true
 cliff_kurt.centered=false
func _sync_cliff_pose() -> void:
 if not cliff_scene:return
 cliff_pose=CliffStory.poses(chapter["step"],elapsed,not motion)
 cliff_cast.visible=cliff_pose["actors"]
 if not cliff_cast.visible:return
 cliff_cast.transform=_cliff_projection()
 cliff_aion.position=cliff_pose["aion_foot"]
 cliff_aion.visible=cliff_pose["aion_visible"]
 if cliff_pose["aion_frame"]!=aion_exit_frame:
  aion_exit_frame=cliff_pose["aion_frame"]
  cliff_aion.region_rect=VisualArt.region("aion_cliff",aion_exit_frame)
 cliff_kurt.position=cliff_pose["kurt_foot"]
 var frame: int=cliff_pose["frame"]
 if cliff_frame!=frame:
  cliff_frame=frame
  var rect:=VisualArt.region("kurt_scene",frame)
  var contact: Array=VisualArt.data()["kurt_scene_feet"][frame]
  cliff_kurt.region_rect=rect;cliff_kurt.offset=-Vector2(contact[0],contact[1]);cliff_kurt.scale=Vector2.ONE*(60.0/rect.size.y)
func _draw_cliff() -> void:
 var pose:=cliff_pose
 draw_set_transform_matrix(_cliff_projection())
 draw_texture_rect(VisualArt.texture("cliff"),Rect2(0,0,640,360),false)
 if pose["wrecked"]:VisualArt.at(self,"cliff_cars",Vehicles.index(save.get("vehicle"))+1,pose["aion_car"],Vector2(48,74))
 else:VisualArt.vehicle_at(self,Vehicles.index(save.get("vehicle")),pose["aion_car"])
 draw_set_transform_matrix(_cliff_projection()*Transform2D(PI/2,pose["kurt_car"]))
 VisualArt.at(self,"cliff_cars",0,Vector2.ZERO,Vector2(48,74))
 draw_set_transform_matrix(_cliff_projection())
 if chapter["step"]=="impact" and effects and motion:VisualArt.at(self,"gadgets",7,pose["aion_car"]+Vector2(-22,0),Vector2(32,32),Color(1,1,1,clampf(1-elapsed/.6,0,1)))
 if pose["wrecked"] and not pose["aion_visible"]:
  VisualArt.portrait(self,"aion",Rect2(pose["aion_car"]-Vector2(7,10),Vector2(14,14)))
 if pose["door"]>0.0:
  var hinge: Vector2=pose["aion_car"]+Vector2(12,-9)
  var tip:=hinge+Vector2(2+pose["door"]*13,17-pose["door"]*6)
  draw_line(hinge,tip,Color("150f16"),6)
  draw_line(hinge,tip,Color("e0ab61"),3)
 if pose["wrecked"] and effects:VisualArt.at(self,"weapons",3,pose["aion_car"]+Vector2(0,-22),Vector2(24,30),Color(1,1,1,.6))
 draw_set_transform(Vector2.ZERO)
func _cliff_snapshot() -> Dictionary:
 var pose:=cliff_pose
 return {"aion_car":[pose["aion_car"].x,pose["aion_car"].y],"kurt_car":[pose["kurt_car"].x,pose["kurt_car"].y],"edge_y":pose["edge_y"],"wrecked":pose["wrecked"],"actors":pose["actors"],"frame":pose["frame"],"aion_visible":pose["aion_visible"],"aion_foot":[pose["aion_foot"].x,pose["aion_foot"].y],"kurt_foot":[pose["kurt_foot"].x,pose["kurt_foot"].y]}
