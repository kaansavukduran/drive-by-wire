extends Node2D
## Chapter 2: authored road scene + player-paced conversations. No combat spawner.
const Story=preload("res://scripts/core/road_story.gd")
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
const INJURED=preload("res://assets/sprites/emre_aftermath.png")
const CRASH=preload("res://assets/sprites/emre_trap.png")
const DRIVER=preload("res://assets/sprites/aion_roadster.png")
const EMRE_BODY=preload("res://assets/sprites/courier_body.png")
const AION_STANDING=preload("res://assets/characters/characters_standing.png")
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
var stage_rect:=Rect2()
var sounds: Node
var sheets:=Sheets.new()
var car_texture: Texture2D
var layout_ready:=false
var last_portrait:=false
func _ready() -> void:
 Engine.time_scale=1
 save=store.load_data();car_texture=Vehicles.texture_for(save.get("vehicle"))
 campaign=Book.sanitize(Session.campaign_state if not Session.campaign_state.is_empty() else save["campaign"])
 if int(campaign["stage"])!=1 or not campaign["active"]:
  get_tree().call_deferred("change_scene_to_file","res://scenes/journey.tscn");return
 chapter=Story.sanitize(campaign["chapter2"])
 motion=save["settings"]["motion"];effects=save["settings"]["effects"]
 Controls.install(save["settings"]["bindings"],save["settings"]["pad_bindings"],save["settings"]["deadzone"])
 sounds=Sounds.new();sounds.enabled=save["settings"]["sound"];sounds.volume=save["settings"]["volume"];add_child(sounds)
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
func _cinematic() -> bool:return chapter.get("step") in ["race","trap"]
func _ground_scene() -> bool:return Story.STEPS.find(chapter.get("step","arrival"))>=5
func _present() -> void:
 var node: Dictionary=Story.data()["nodes"][chapter["step"]]
 var cinema:=_cinematic()
 speaker.text=str(Portrait.NAMES[node.get("speaker","omega")])
 portrait.speaker=node.get("speaker","omega")
 next_button.visible=not cinema
 for i in choices.size():
  choices[i].visible=not cinema and node.has("choices")
  if choices[i].visible:choices[i].text=str(node["choices"][i]["label"])
 next_button.visible=not cinema and not node.has("choices")
 next_button.text="Son yol ayrımına geç · A" if chapter["step"]=="complete" else "Devam · A / Enter"
 _layout();_focus();queue_redraw()
func _reflow() -> void:
 var node: Dictionary=Story.data()["nodes"][chapter["step"]]
 pages=TextFit.pages(str(node.get("text",node.get("caption",""))),body)
 page=clampi(page,0,pages.size()-1)
 body.text=pages[page]
 page_caption.text=""
 page_caption.hide()
 heading.text="Kayıt yazılamadı · oturumda korunuyor" if save_failed else "Yan yana · İkinci bölüm"
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
 if Story.data()["nodes"][chapter["step"]].has("choices"):return
 chapter=Story.advance(chapter);_enter()
func _choose(index: int) -> void:
 if paused or index<0 or index>=choices.size() or not choices[index].visible:return
 var options: Array=Story.data()["nodes"][chapter["step"]].get("choices",[])
 if options.size()!=2:return
 chapter=Story.choose(chapter,str(options[index]["id"]));_enter()
func _enter() -> void:
 elapsed=0;page=0
 _checkpoint();_present()
 if chapter["step"]=="trap":sounds.cue("kill")
func _checkpoint() -> bool:
 campaign["chapter2"]=chapter.duplicate(true)
 save["campaign"]=campaign
 Session.campaign_state=campaign.duplicate(true)
 save_failed=not store.save_data(save);Session.campaign_save_failed=save_failed
 return not save_failed
func _finish() -> void:
 if not _commit_completion():return
 get_tree().call_deferred("change_scene_to_file","res://scenes/journey.tscn")
func _commit_completion() -> bool:
 if completed or chapter["step"]!="complete":return false
 completed=true
 var ally: String="kurt" if chapter["vow"]=="avenge" else "emre"
 campaign["bonds"][ally]=mini(3,int(campaign["bonds"].get(ally,0))+1)
 campaign=Book.complete(campaign,true,500,true)
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
  pose_time+=delta
  if _cinematic():
   elapsed+=delta
   if motion:road_time+=delta*(100 if chapter["step"]=="race" else 22)
   if elapsed>=float(Story.data()["nodes"][chapter["step"]]["duration"]):chapter=Story.advance(chapter);_enter()
 queue_redraw()
 if QA.active():QA.publish("road_story",snapshot())
func _layout() -> void:
 if not is_instance_valid(panel):return
 var v:=get_viewport_rect().size;var p:=v.y>v.x
 if layout_ready and p!=last_portrait:_pause(true)
 last_portrait=p;layout_ready=true
 var reserved_height:=232.0 if p else 154.0
 var has_choices: bool=Story.data()["nodes"][chapter["step"]].has("choices")
 var height:=104.0 if _cinematic() else ((216.0 if has_choices else 160.0) if p else 154.0)
 # Same fixed layout throughout the chapter: no panel or actor jump per speech.
 panel.position=Vector2(8,v.y-height-8);panel.size=Vector2(v.x-16,height)
 heading.position=Vector2(12,8);heading.size=Vector2(v.x-112,24)
 pause_button.position=Vector2(v.x-92,4);pause_button.size=Vector2(84,44)
 portrait.position=Vector2(10,8);portrait.size=Vector2(36,36)
 speaker.position=Vector2(54,8);speaker.size=Vector2(panel.size.x-64,20)
 body.position=Vector2(12,48);body.size=Vector2(panel.size.x-24,48 if p else 46)
 page_caption.position=Vector2(12,114 if p else 97);page_caption.size=Vector2(panel.size.x-24,16)
 next_button.position=Vector2(12,height-56);next_button.size=Vector2(panel.size.x-24,44)
 for i in choices.size():
  choices[i].position=Vector2(12+(0 if p else i*(panel.size.x-16)/2),height-108+i*52 if p else height-56)
  choices[i].size=Vector2(panel.size.x-24 if p else (panel.size.x-32)/2,44)
 stage_rect=Rect2(0,48,v.x,v.y-reserved_height-64)
 pause_panel.size=Vector2(minf(v.x-24,420),176);pause_panel.position=(v-pause_panel.size)/2
 warning.position=Vector2(12,10);warning.size=Vector2(pause_panel.size.x-24,54)
 resume_button.position=Vector2(12,70);resume_button.size=Vector2(pause_panel.size.x-24,44)
 leave_button.position=Vector2(12,122);leave_button.size=Vector2(pause_panel.size.x-24,44)
 _reflow();queue_redraw()
func actor_positions() -> Array[Vector2]:
 if _ground_scene():return [Vector2(256,248),Vector2(352,248)]
 var lead:=0.0
 if chapter.get("pace")=="race" and chapter["step"]=="race" and motion:lead=sin(clampf(elapsed/8.0,0,1)*PI)*20
 return [Vector2(270,190),Vector2(370,190-lead)]
func injury_frame() -> int:return int(pose_time*5)%6 if motion else 0
func _draw_car(at: Vector2,companion: bool) -> void:
 var frame:=int(pose_time*10)%4 if motion else 0
 var texture: Texture2D=EMRE_BODY if companion else car_texture
 if companion and chapter["step"]=="trap":
  texture=CRASH;frame=mini(7,int(elapsed*4))
 draw_texture_rect_region(texture,Rect2(at-Vector2(24,36.25),Vector2(48,80)),Rect2((frame%4)*64,(frame/4)*96,64,96))
 if companion:
  # Back of Emre's head, ears point forward. Deliberately authored, not an upside-down face.
  draw_rect(Rect2(at+Vector2(-9,-8),Vector2(18,17)),Color("b98a70"))
  draw_rect(Rect2(at+Vector2(-7,-21),Vector2(5,17)),Color("ebc1a0"));draw_rect(Rect2(at+Vector2(3,-21),Vector2(5,17)),Color("ebc1a0"))
  draw_rect(Rect2(at+Vector2(-5,-18),Vector2(1,11)),Color("dc9c97"));draw_rect(Rect2(at+Vector2(5,-18),Vector2(1,11)),Color("dc9c97"))
  draw_rect(Rect2(at+Vector2(-8,9),Vector2(16,3)),Color("9dbee0"))
 elif Vehicles.sanitize(save.get("vehicle"))!="roadster":
  draw_texture_rect_region(DRIVER,Rect2(at+Vector2(-12,-11.25),Vector2(24,25)),Rect2(16,30,32,30))
func _draw() -> void:
 if chapter.is_empty():return
 var v:=get_viewport_rect().size
 draw_rect(Rect2(Vector2.ZERO,v),UiSkin.color("background"))
 var zoom:=minf(stage_rect.size.x/480.0,stage_rect.size.y/210.0)
 var origin:=stage_rect.get_center()-Vector2(320,176)*zoom
 draw_set_transform(origin,0,Vector2.ONE*zoom)
 var positions:=actor_positions()
 if _ground_scene():
  draw_rect(Rect2(90,88,460,190),Color("1b2d32"))
  draw_rect(Rect2(90,242,460,44),Color("30454b"))
  draw_line(Vector2(90,248),Vector2(550,248),Color("53716c"),2)
  # Wreck rests on the road, separate from the fixed character slots.
  draw_rect(Rect2(448,201,46,47),Color("243640"));draw_rect(Rect2(455,207,32,27),Color("785443"))
  draw_line(Vector2(451,204),Vector2(490,239),Color("ab7d5a"),3)
  for i in 4:draw_rect(Rect2(458+i*9,191-i%2*11,7,17),Color("455052"))
  # Aion's established standing sprite, fixed sole pivot (36,61).
  _draw_aion(positions[0])
  draw_texture_rect_region(INJURED,Rect2(positions[1]-Vector2(64,72),Vector2(128,80)),Rect2(injury_frame()*128,0,128,80))
  draw_rect(Rect2(positions[0]+Vector2(-26,-3),Vector2(49,4)),Color(0,0,0,0.16))
 else:
  draw_rect(Rect2(90,-300,460,1100),Color("1c3835"))
  for i in range(-2,4):draw_texture(ROAD,Vector2(192,i*256+fmod(road_time,256)))
  for i in 10:
   var y:=fmod(i*63+road_time*.7,640)-140
   for x in [148,473]:
    draw_rect(Rect2(x,y+17,5,25),Color("564c3f"));draw_rect(Rect2(x-10,y,26,27),Color("34574c"));draw_rect(Rect2(x-6,y-5,18,14),Color("477161"))
  _draw_car(positions[0],false);_draw_car(positions[1],true)
  if chapter["step"]=="trap":
   if effects:
    sheets.draw_frame(self,"explosion",sheets.frame_at("explosion","explode",minf(elapsed,0.8),0),positions[1])


 draw_set_transform(Vector2.ZERO)
func _draw_aion(at: Vector2) -> void:
 var texture: Texture2D=AION_STANDING
 draw_texture_rect_region(texture,Rect2(at-Vector2(36,61),Vector2(72,64)),Rect2(0,0,72,64))
func snapshot() -> Dictionary:
 return {"view":[get_viewport_rect().size.x,get_viewport_rect().size.y],"chapter":chapter.duplicate(true),"elapsed":elapsed,"paused":paused,"page":page,"pages":pages.size(),"text":body.text,"speaker":speaker.text,"body":QA.rect(body),"portrait":QA.rect(portrait),"speaker_rect":QA.rect(speaker),"panel":QA.rect(panel),"next":QA.rect(next_button),"next_visible":next_button.visible,"choices":choices.filter(func(b):return b.visible).map(func(b):return QA.rect(b)),"pause":QA.rect(pause_button),"resume":QA.rect(resume_button),"leave":QA.rect(leave_button),"fits":TextFit.fits(heading) and TextFit.fits(body) and TextFit.fits(speaker) and TextFit.fits(page_caption),"actors":actor_positions().map(func(pos):return [pos.x,pos.y]),"frame":injury_frame(),"combat":false,"vehicle":save["vehicle"],"save_failed":save_failed}
