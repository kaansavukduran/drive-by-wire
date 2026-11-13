extends Node
const Book=preload("res://scripts/core/story_book.gd")
const Session=preload("res://scripts/game/session.gd")
const Store=preload("res://scripts/core/save_store.gd")
const UiSkin=preload("res://scripts/game/ui_skin.gd")
const Controls=preload("res://scripts/game/controls.gd")
const QA=preload("res://scripts/game/qa_snapshot.gd")
const Portrait=preload("res://scripts/game/cast_portrait.gd")
const Reader=preload("res://scripts/game/text_reader.gd")
@export var gallery:=false
var panel: Panel
var body: Control
var back: Button
var primary: Button
var gallery_button: Button
var campaign: Dictionary
var heading: Label
var status: Label
var ending_buttons: Array[Button]=[]
var reader: Control
var cast: Array[Control]=[]
var gallery_page:=0
var gallery_previous: Button
var gallery_next: Button
var gallery_counter: Label
func _ready() -> void:
 Engine.time_scale=1
 var save: Dictionary=Store.new().load_data()
 campaign=Book.sanitize(Session.campaign_state if not Session.campaign_state.is_empty() else save["campaign"])
 Controls.install(save["settings"]["bindings"],save["settings"]["pad_bindings"],save["settings"]["deadzone"])
 panel=Panel.new();panel.theme=UiSkin.theme();panel.add_theme_stylebox_override("panel",UiSkin.panel(Color("9de1c3")));add_child(panel)
 heading=_label("SONLAR · %d / 13" % campaign["unlocked"].size() if gallery else "ÜÇÜNCÜ NABIZ · SON",16)
 heading.theme_type_variation="BrandLabel"
 body=Control.new();panel.add_child(body)
 if gallery:
  for item in Book.data()["endings"]:
   var unlocked: bool=item["id"] in campaign["unlocked"]
   var button:=_button(str(item["id"]).trim_prefix("e")+" · "+(str(item["title"]) if unlocked else "Henüz açılmadı"),func():
    Session.view_ending=str(item["id"]);get_tree().call_deferred("change_scene_to_file","res://scenes/ending.tscn"))
   button.disabled=not unlocked;ending_buttons.append(button)
  var selected: Dictionary=Book.ending(campaign)
  var wanted: String=str(selected.get("id",campaign["unlocked"][-1] if not campaign["unlocked"].is_empty() else "e01"))
  for i in Book.data()["endings"].size():
   if Book.data()["endings"][i]["id"]==wanted: gallery_page=i/4
  gallery_previous=_button("Önceki · ←",func(): _gallery_turn(-1))
  gallery_next=_button("Sonraki · →",func(): _gallery_turn(1))
  gallery_counter=_label("",11);gallery_counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 else:
  reader=Reader.new();panel.add_child(reader)
  var item: Dictionary=Book.ending(campaign)
  for candidate in Book.data()["endings"]:
   if candidate["id"]==Session.view_ending and candidate["id"] in campaign["unlocked"]: item=candidate
  var prose: Array[String]=[]
  if item.is_empty(): prose.append("Henüz bir hikâye sonuna ulaşmadın. Üç etabı tamamlayınca seçtiğin yolun sonucunu okuyabilirsin.")
  else:
   for who in Portrait.IDS:
    var portrait:=Portrait.new();portrait.speaker=who;panel.add_child(portrait);portrait.custom_minimum_size=Vector2.ZERO;cast.append(portrait)
   prose.append(str(item["id"]).trim_prefix("e")+" / 13 · "+str(item["title"]))
   prose.append("Kararların: "+" → ".join(Book.path_labels({"choices":item["path"]})))
   prose.append(str(item["text"]))
   if item==Book.ending(campaign):
    var closest: String="";var best:=0
    for who in campaign.get("bonds",{}):
     if int(campaign["bonds"][who])>best: closest=who;best=int(campaign["bonds"][who])
    if closest!="": prose.append(str(Portrait.NAMES.get(closest,"Omega-3"))+": “O yolda bana verdiğin cevabı unutmadım.”")
    prose.append("Üç etap · Puan %d · Yol hedefi %d/3 · Yeniden deneme %d" % [campaign["score"],campaign["goals_completed"],campaign["failures"]])
   prose.append("Sonlar kitabında diğer yolları keşfedebilirsin. Yeni hikâye açarsan kazandığın sonlar korunur.")
  reader.set_text("\n\n".join(prose))
 status=_label("İlerleme bu cihazda." if not Session.campaign_save_failed else "Kayıt yazılamadı; ilerleme bu oturumda.",10)
 primary=_button("Yeni hikâye · Sonları koru" if campaign["stage"]==3 else "Hikâyeye devam et",_continue)
 if not gallery: gallery_button=_button("13 sonun kitabı",func():get_tree().call_deferred("change_scene_to_file","res://scenes/endings.tscn"))
 back=_button("Ana menü · Esc / B",_back)
 get_viewport().size_changed.connect(_layout);_layout();primary.grab_focus()
func _label(text: String,font_size: int) -> Label:
 var label:=Label.new();label.text=text;label.clip_text=true;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",font_size);panel.add_child(label);return label
func _button(text: String,action: Callable) -> Button:
 var button:=Button.new();button.text=text;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.clip_text=true;UiSkin.style_button(button);button.pressed.connect(action);panel.add_child(button);return button
func _place(control: Control,rect: Rect2) -> void:
 control.position=rect.position;control.size=rect.size
func _layout() -> void:
 var view:=get_viewport().get_visible_rect().size
 var extent:=Vector2(minf(view.x-20,600),view.y-20)
 _place(panel,Rect2((view-extent)/2,extent));var w:=extent.x
 _place(heading,Rect2(12,8,w-24,25))
 var footer:=extent.y-110
 _place(status,Rect2(12,footer-22,w-24,18))
 if gallery:
  _place(body,Rect2(12,40,w-24,footer-68))
  for i in ending_buttons.size():
   ending_buttons[i].visible=i/4==gallery_page
   _place(ending_buttons[i],Rect2(12+(i%2)*(w-20)/2,46+((i%4)/2)*52,(w-28)/2,48))
  _place(gallery_previous,Rect2(12,footer-72,(w-100)/2,44))
  _place(gallery_next,Rect2(w-(w-100)/2-12,footer-72,(w-100)/2,44))
  _place(gallery_counter,Rect2(w/2-32,footer-72,64,44))
  gallery_counter.text="%d / 4" % (gallery_page+1);gallery_previous.disabled=gallery_page==0;gallery_next.disabled=gallery_page==3
 else:
  var cast_height:=32 if extent.y<400 else 44
  for i in cast.size(): _place(cast[i],Rect2(w/2-(cast.size()*(cast_height+6)-6)/2+i*(cast_height+6),36,cast_height,cast_height))
  var top:=42+cast_height
  _place(reader,Rect2(12,top,w-24,maxf(70,footer-top-30)));reader.reflow()
 _place(primary,Rect2(12,footer,w-24,44))
 if gallery: _place(back,Rect2(12,footer+52,w-24,44))
 else:
  _place(gallery_button,Rect2(12,footer+52,(w-32)/2,44));_place(back,Rect2(w/2+4,footer+52,(w-32)/2,44))
 var actions: Array=[primary,gallery_button,back]
 if gallery:
  actions=ending_buttons.filter(func(b):return b.visible and not b.disabled)
  actions.append_array([primary,back])
 for i in actions.size():
  actions[i].focus_neighbor_bottom=actions[i].get_path_to(actions[(i+1)%actions.size()]);actions[i].focus_neighbor_top=actions[i].get_path_to(actions[posmod(i-1,actions.size())])
func _gallery_turn(step: int) -> void:
 gallery_page=clampi(gallery_page+step,0,3);_layout()
 var focus:=get_viewport().gui_get_focus_owner()
 if focus in ending_buttons and not focus.visible: primary.grab_focus()
func _process(_delta: float) -> void:
 if QA.active(): QA.publish("endings" if gallery else "ending",{"view":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y],"panel":QA.rect(panel),"title":heading.text,"primary":QA.rect(primary),"back":QA.rect(back),"unlocked":campaign["unlocked"],"entries":ending_buttons.map(func(b):return {"rect":QA.rect(b),"disabled":b.disabled,"visible":b.visible}),"reader":reader.snapshot() if is_instance_valid(reader) else {},"gallery_page":gallery_page,"gallery_previous":QA.rect(gallery_previous) if gallery else [],"gallery_next":QA.rect(gallery_next) if gallery else [],"scrollbars":0})
func _continue() -> void:
 Session.story_mode=true;Session.view_ending=""
 if campaign["stage"]==3: campaign=Book.defaults(campaign["unlocked"])
 Session.campaign_state=campaign.duplicate(true)
 var store:=Store.new();var save: Dictionary=store.load_data();save["campaign"]=campaign
 Session.campaign_save_failed=not store.save_data(save);get_tree().call_deferred("change_scene_to_file","res://scenes/journey.tscn")
func _back() -> void:
 Session.view_ending="";get_tree().call_deferred("change_scene_to_file","res://scenes/title.tscn")
func _input(event: InputEvent) -> void:
 Controls.observe(event)
 if event.is_action_pressed("ui_cancel"): _back();get_viewport().set_input_as_handled()
 elif gallery and (event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right")):
  _gallery_turn(-1 if event.is_action_pressed("ui_left") else 1);get_viewport().set_input_as_handled()
