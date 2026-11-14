extends Node
const QA := preload("res://scripts/game/qa_snapshot.gd")
const Journey := preload("res://scripts/core/journey.gd")
const Book := preload("res://scripts/core/story_book.gd")
const Session := preload("res://scripts/game/session.gd")
const Controls := preload("res://scripts/game/controls.gd")
const Store := preload("res://scripts/core/save_store.gd")
const UiSkin := preload("res://scripts/game/ui_skin.gd")
const Portrait := preload("res://scripts/game/cast_portrait.gd")
var panel: PanelContainer
var content: Control
var heading: Label
var tabs: Array[Button]=[]
var pages: Array[Control]=[]
var choices: Array[Button]=[]
var back: Button
var campaign: Dictionary
var store: RefCounted
var save: Dictionary
var save_error := false
var radio_portrait: Control
var radio_line: Label
var radio_next: Button
var radio_answers: Array[Button]=[]
var conversation: Array=[]
var line_index := 0
var page_index := 2
var journal_text: Label
var journal_next: Button
var journal_parts: Array[String]=[]
var journal_index := 0
var reply_text: Label
var reply_continue: Button
func _ready() -> void:
 Engine.time_scale=1.0
 store=Store.new()
 save=store.load_data()
 Controls.install(save["settings"]["bindings"],save["settings"]["pad_bindings"],save["settings"]["deadzone"])
 campaign=Book.sanitize(Session.campaign_state if not Session.campaign_state.is_empty() else save["campaign"])
 if Session.story_mode and campaign["phase"] in ["interlude","continued"]:
  get_tree().call_deferred("change_scene_to_file",Session.play_scene())
  return
 panel=PanelContainer.new()
 panel.theme=UiSkin.theme()
 var frame: StyleBoxFlat=UiSkin.panel(Color("9de1c3")).duplicate()
 frame.set_content_margin_all(0)
 panel.add_theme_stylebox_override("panel",frame)
 add_child(panel)
 # One bounded page at a time. No ScrollContainer or hidden offscreen choices.
 var surface:=Control.new()
 panel.add_child(surface)
 heading=Label.new()
 heading.text=Book.node(campaign)["title"] if Session.story_mode else Journey.new().data["chapter"]
 heading.add_theme_font_size_override("font_size",18)
 heading.theme_type_variation="AccentLabel"
 surface.add_child(heading)
 for i in 4:
  var button:=_button(surface,["Konuşma","Yanıt","Etap","Günlük"][i])
  button.pressed.connect(_show_page.bind(i,true))
  tabs.append(button)
 content=Control.new()
 surface.add_child(content)
 for i in 4:
  var page:=Control.new()
  content.add_child(page)
  pages.append(page)
 _build_radio()
 reply_text=_label(pages[1],str(Book.node(campaign).get("response_prompt","Yanıtını seç; hikâye aynı sırayla ilerler.")))
 for reply in Book.node(campaign).get("responses",[]) if Session.story_mode else []:
  var button:=_button(pages[1],str(reply["text"]))
  button.pressed.connect(_answer.bind(str(reply["id"])))
  button.disabled=campaign.get("radio",{}).has(Book.node_key(campaign))
  radio_answers.append(button)
 reply_continue=_button(pages[1],"Yola devam et · A / Enter")
 reply_continue.pressed.connect(_choose.bind("depart"))
 reply_continue.visible=campaign.get("radio",{}).has(Book.node_key(campaign))
 if reply_continue.visible:
  reply_text.text=str(Book.radio_reply(campaign).get("reply",""))
  for button in radio_answers:button.hide()
 var options: Array=Book.node(campaign)["choices"] if Session.story_mode else Journey.new().data["routes"].values()
 for i in options.size():
  var spec: Dictionary=options[i]
  var effect: String=str(spec["effect"])
  var button:=_button(pages[2],str(spec["name"])+"\n"+effect)
  button.pressed.connect(_choose.bind(str(spec["id"]) if Session.story_mode else ["steady","supplies"][i]))
  choices.append(button)
 var synopsis: String=Book.node(campaign)["text"] if Session.story_mode else Journey.new().data["premise"]
 journal_parts=_paginate(synopsis+"\n\nHer etap 400 m. Sonrasında ara sahne gelir. Bu sürüm iki etap ve iki ara sahnenin ardından Devam edecek ile biter. Kaza yaparsan aynı etaptan yeniden denersin.\nOklar/WASD veya sabit joystick: dört yön. Ateş öne, sınırsız mayın arkaya. Yalnız ateş ve mayın; yönü serbestçe seç.",190)
 journal_text=_label(pages[3],journal_parts[0])
 journal_next=_button(pages[3],"")
 journal_next.pressed.connect(func(): journal_index=(journal_index+1)%journal_parts.size();_show_journal())
 _show_journal()
 back=_button(surface,"Ana menü · Esc / B")
 back.pressed.connect(_back)
 get_viewport().size_changed.connect(_layout)
 _layout()
 # Start with real replies; A/Enter confirms and then continues on the same page.
 _show_page(1,true)
func _button(parent: Node,text: String) -> Button:
 var button:=Button.new()
 button.text=text
 button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 button.add_theme_font_size_override("font_size",12)
 UiSkin.style_button(button)
 parent.add_child(button)
 return button
func _label(parent: Node,text: String) -> Label:
 var label:=Label.new()
 label.text=text
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.clip_text=true
 label.add_theme_font_size_override("font_size",13)
 parent.add_child(label)
 return label
func _paginate(text: String,limit: int) -> Array[String]:
 var out: Array[String]=[]
 var part: String=""
 for word in text.split(" "):
  if part.length()+word.length()+1>limit and not part.is_empty():
   out.append(part)
   part=""
  part+=(" " if not part.is_empty() else "")+word
 if not part.is_empty(): out.append(part)
 return out
func _build_radio() -> void:
 for entry in Book.node(campaign).get("conversation",[]) if Session.story_mode else []:
  for part in _paginate(str(entry["line"]),150):
   conversation.append({"speaker":entry["speaker"],"line":part})
 radio_portrait=Portrait.new()
 pages[0].add_child(radio_portrait)
 radio_line=_label(pages[0],"")
 radio_next=_button(pages[0],"")
 radio_next.pressed.connect(func():
  if line_index+1<conversation.size(): line_index+=1;_show_line()
  else: _show_page(1,true))
 _show_line()
func _show_line() -> void:
 if conversation.is_empty():
  radio_line.text="Omega-3 · Rota seç; yolda konuşuruz."
  radio_next.text="Yanıtlara geç"
  return
 var line: Dictionary=conversation[line_index]
 radio_portrait.speaker=line["speaker"]
 radio_line.text=str(Portrait.NAMES.get(line["speaker"],line["speaker"]))+"\n"+str(line["line"])
 radio_next.text=("Yanıtlara geç" if line_index==conversation.size()-1 else "Sonraki replik")+" · %d/%d" % [line_index+1,conversation.size()]
func _show_journal() -> void:
 journal_text.text=journal_parts[journal_index]
 journal_next.text="Sonraki sayfa · %d/%d" % [journal_index+1,journal_parts.size()]
func _show_page(index: int,focus: bool=false) -> void:
 page_index=index
 for i in pages.size():
  pages[i].visible=i==index
  tabs[i].text=(["Konuşma","Yanıt","Etap","Günlük"][i])+ (" •" if i==index else "")
 if focus:
  if index==0: radio_next.grab_focus()
  elif index==1:
   if reply_continue.visible:reply_continue.grab_focus()
   elif not radio_answers.is_empty():radio_answers[0].grab_focus()
  elif index==2: choices[0].grab_focus()
  else: tabs[index].grab_focus()
 _focus_paths()
func _focus_paths() -> void:
 if not is_instance_valid(back): return
 var active: Array[Button]=[]
 if page_index==0: active.append(radio_next)
 elif page_index==1:
  for b in radio_answers:
   if b.visible and not b.disabled: active.append(b)
  if reply_continue.visible:active.append(reply_continue)
 elif page_index==2: active.assign(choices)
 else: active.append(journal_next)
 for i in tabs.size():
  tabs[i].focus_neighbor_left=tabs[i].get_path_to(tabs[(i+3)%4])
  tabs[i].focus_neighbor_right=tabs[i].get_path_to(tabs[(i+1)%4])
  tabs[i].focus_neighbor_bottom=tabs[i].get_path_to(active[0] if not active.is_empty() else back)
  tabs[i].focus_neighbor_top=tabs[i].get_path_to(back)
 for i in active.size():
  active[i].focus_neighbor_top=active[i].get_path_to(active[i-1] if i>0 else tabs[page_index])
  active[i].focus_neighbor_bottom=active[i].get_path_to(active[i+1] if i+1<active.size() else back)
  active[i].focus_neighbor_left=active[i].get_path_to(active[maxi(0,i-1)])
  active[i].focus_neighbor_right=active[i].get_path_to(active[mini(active.size()-1,i+1)])
 back.focus_neighbor_bottom=back.get_path_to(tabs[page_index])
 back.focus_neighbor_top=back.get_path_to(active[-1] if not active.is_empty() else tabs[page_index])
func _fit(control: Control,rect: Rect2) -> void:
 control.position=rect.position
 control.size=rect.size
func _layout() -> void:
 if not is_instance_valid(back): return
 var view: Vector2=get_viewport().get_visible_rect().size
 var extent_panel:=Vector2(minf(560,view.x-16),minf(400,view.y-16))
 panel.position=(view-extent_panel)/2
 panel.size=extent_panel
 var width:=panel.size.x-32
 heading.position=Vector2(16,8)
 heading.size=Vector2(width,28)
 heading.add_theme_font_size_override("font_size",14 if width<420 else 18)
 var tab_width: float=(width-18)/4
 for i in tabs.size(): _fit(tabs[i],Rect2(16+i*(tab_width+6),42,tab_width,44))
 _fit(content,Rect2(16,94,width,panel.size.y-156))
 for page in pages: page.size=content.size
 var extent: Vector2=content.size
 _fit(radio_portrait,Rect2(0,0,64,64))
 _fit(radio_line,Rect2(76,0,extent.x-76,extent.y-52))
 _fit(radio_next,Rect2(0,extent.y-44,extent.x,44))
 var answer_space:=radio_answers.size()*50.0
 _fit(reply_text,Rect2(0,0,extent.x,extent.y-answer_space-4 if not reply_continue.visible else extent.y-56))
 for i in radio_answers.size(): _fit(radio_answers[i],Rect2(0,extent.y-answer_space+i*50,extent.x,44))
 _fit(reply_continue,Rect2(0,extent.y-44,extent.x,44))
 var row_h: float=minf(56,(extent.y-6*(choices.size()-1))/choices.size())
 for i in choices.size(): _fit(choices[i],Rect2(0,i*(row_h+6),extent.x,row_h))
 _fit(journal_text,Rect2(0,0,extent.x,extent.y-52))
 _fit(journal_next,Rect2(0,extent.y-44,extent.x,44))
 _fit(back,Rect2(16,panel.size.y-54,width,44))
 _focus_paths()
func _input(event: InputEvent) -> void:
 Controls.observe(event)
 if event is InputEventKey and event.pressed and not event.echo and page_index==1 and not reply_continue.visible and event.keycode in [KEY_1,KEY_2,KEY_3]:
  _answer(str(Book.node(campaign)["responses"][event.keycode-KEY_1]["id"]));get_viewport().set_input_as_handled();return
 if event.is_action_pressed("ui_cancel"):
  _back()
  get_viewport().set_input_as_handled()
func _process(_delta: float) -> void:
 if not is_instance_valid(back): return
 if QA.active():
  var view: Vector2=get_viewport().get_visible_rect().size
  var visible_controls: Array=[]
  for child in pages[page_index].get_children():
   if child is Control: visible_controls.append(QA.rect(child))
  QA.publish("briefing",{"view":[view.x,view.y],"panel":QA.rect(panel),"reading":QA.rect(content),"tabs":tabs.map(func(b): return QA.rect(b)),"page":page_index,"visible_controls":visible_controls,"scrollbars":panel.find_children("*","ScrollContainer",true,false).size(),"steady":QA.rect(choices[0]),"supplies":QA.rect(choices[-1]),"choices":choices.map(func(b): return QA.rect(b)),"radio_next":QA.rect(radio_next),"radio_answers":radio_answers.map(func(b): return QA.rect(b)),"reply_continue":QA.rect(reply_continue),"reply_ready":reply_continue.visible,"reply_text":reply_text.text,"radio_selected":campaign.get("radio",{}).get(Book.node_key(campaign),""),"speaker":radio_portrait.speaker,"line_index":line_index,"line_count":conversation.size(),"stage":campaign["stage"],"back":QA.rect(back)})
func _answer(id: String) -> void:
 campaign=Book.answer(campaign,id)
 save["campaign"]=campaign
 save_error=not store.save_data(save)
 Session.campaign_state=campaign.duplicate(true)
 reply_text.text=str(Book.radio_reply(campaign).get("reply",""))+ ("\nKayıt yazılamadı; oturum içinde korunuyor." if save_error else "\nYanıt kaydedildi.")
 for b in radio_answers:b.hide();b.disabled=true
 reply_continue.show();_layout();reply_continue.grab_focus()
 _focus_paths()
func _choose(route: String) -> void:
 if Session.story_mode:
  campaign=Book.choose(campaign,route)
  Session.campaign_state=campaign.duplicate(true)
  save["campaign"]=campaign
  save_error=not store.save_data(save)
  Session.campaign_save_failed=save_error
 else: Session.next_route=route
 get_tree().call_deferred("change_scene_to_file",Session.play_scene())
func _back() -> void:
 get_tree().call_deferred("change_scene_to_file","res://scenes/title.tscn")
