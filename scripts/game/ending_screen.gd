extends Node
const Book := preload("res://scripts/core/story_book.gd")
const Session := preload("res://scripts/game/session.gd")
const Store := preload("res://scripts/core/save_store.gd")
const UiSkin := preload("res://scripts/game/ui_skin.gd")
const Controls := preload("res://scripts/game/controls.gd")
const QA := preload("res://scripts/game/qa_snapshot.gd")
const Portrait := preload("res://scripts/game/cast_portrait.gd")
@export var gallery := false
var panel: PanelContainer
var body: VBoxContainer
var back: Button
var primary: Button
var campaign: Dictionary
var heading: Label
var status: Label
var ending_buttons: Array[Button] = []
func _ready() -> void:
 Engine.time_scale=1.0
 var save: Dictionary=Store.new().load_data()
 campaign=Book.sanitize(Session.campaign_state if not Session.campaign_state.is_empty() else save["campaign"])
 Controls.install(save["settings"]["bindings"],save["settings"]["pad_bindings"],save["settings"]["deadzone"])
 panel=PanelContainer.new()
 panel.theme=UiSkin.theme()
 panel.add_theme_stylebox_override("panel",UiSkin.panel(Color("9de1c3")))
 add_child(panel)
 var column:=VBoxContainer.new()
 column.add_theme_constant_override("separation",8)
 panel.add_child(column)
 heading=_label(column,"SONLAR · %d / 13" % campaign["unlocked"].size() if gallery else "ÜÇÜNCÜ NABIZ · SON",18)
 heading.theme_type_variation="BrandLabel"
 var scroll:=ScrollContainer.new()
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus=true
 column.add_child(scroll)
 body=VBoxContainer.new()
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",10)
 scroll.add_child(body)
 if gallery:
  _label(body,"Her son üç kararın bir sonucudur. Etapta kaza yapmak bir son açmaz. Açtığın sonları burada yeniden okuyabilirsin.",13)
  for item in Book.data()["endings"]:
   var unlocked: bool=item["id"] in campaign["unlocked"]
   var b:=_button(body,str(item["id"]).trim_prefix("e")+" · "+(str(item["title"]) if unlocked else "Henüz açılmadı"),func():
    Session.view_ending=str(item["id"])
    get_tree().call_deferred("change_scene_to_file","res://scenes/ending.tscn"))
   b.disabled=not unlocked
   ending_buttons.append(b)
 else:
  var item: Dictionary=Book.ending(campaign)
  if Session.view_ending!="":
   for candidate in Book.data()["endings"]:
    if candidate["id"]==Session.view_ending and candidate["id"] in campaign["unlocked"]: item=candidate
  if item.is_empty():
   _label(body,"Henüz bir hikâye sonuna ulaşmadın. Üç etabı tamamlayınca seçtiğin yolun sonucunu burada okuyabilirsin.",14)
  else:
   _label(body,str(item["id"]).trim_prefix("e")+" / 13 · "+str(item["title"]),20).theme_type_variation="AccentLabel"
   var cast:=HBoxContainer.new()
   cast.alignment=BoxContainer.ALIGNMENT_CENTER
   cast.add_theme_constant_override("separation",6)
   body.add_child(cast)
   for who in Portrait.IDS:
    var portrait:=Portrait.new()
    portrait.speaker=who
    cast.add_child(portrait)
    portrait.custom_minimum_size=Vector2(48,48)
   _label(body,"Kararların: "+" → ".join(Book.path_labels({"choices":item["path"]})),12).theme_type_variation="MutedLabel"
   _label(body,str(item["text"]),14)
   if item==Book.ending(campaign) and not campaign.get("bonds",{}).is_empty():
    var closest: String=""
    var best:=0
    for who in campaign["bonds"]:
     if int(campaign["bonds"][who])>best:
      closest=who;best=int(campaign["bonds"][who])
    _label(body,str(Portrait.NAMES.get(closest,"Omega-3"))+": “O yolda bana verdiğin cevabı unutmadım.”",13).theme_type_variation="AccentLabel"
   if item==Book.ending(campaign):
    _label(body,"Üç etap · Puan %d · Yol hedefi %d/3 · Yeniden deneme %d" % [campaign["score"],campaign["goals_completed"],campaign["failures"]],12)
   _label(body,"Bu son yalnızca bu hikâyenin kapanışı. Farklı kararlar başka gelecekler açar. Omega-3 ve bu bölümün hikâyesi AIONIA için oyun taslağıdır.",11).theme_type_variation="MutedLabel"
 status=_label(column,"İlerleme bu cihazda." if not Session.campaign_save_failed else "Kayıt yazılamadı. İlerleme bu oturumda korunuyor; sayfayı kapatmadan yeniden dene.",11)
 primary=_button(column,"Yeni hikâye · Sonları koru" if campaign["stage"]==3 else "Hikâyeye devam et",_continue)
 if not gallery: _button(column,"13 sonun kitabı",func(): get_tree().call_deferred("change_scene_to_file","res://scenes/endings.tscn"))
 back=_button(column,"Ana menü · Esc / B",_back)
 get_viewport().size_changed.connect(_layout)
 _layout()
 primary.grab_focus()
func _label(parent: Node,text: String,size: int) -> Label:
 var label:=Label.new()
 label.text=text
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",size)
 parent.add_child(label)
 return label
func _button(parent: Node,text: String,action: Callable) -> Button:
 var button:=Button.new()
 button.text=text
 button.custom_minimum_size.y=44
 UiSkin.style_button(button)
 button.pressed.connect(action)
 parent.add_child(button)
 return button
func _layout() -> void:
 var view: Vector2=get_viewport().get_visible_rect().size
 var target: Vector2=Vector2(minf(view.x-24,600),view.y-32)
 panel.position=(view-target)/2
 panel.size=target
func _process(_delta: float) -> void:
 var view: Vector2=get_viewport().get_visible_rect().size
 var target: Vector2=Vector2(minf(view.x-24,600),view.y-32)
 if not panel.size.is_equal_approx(target): _layout()
 if QA.active(): QA.publish("endings" if gallery else "ending",{"view":[view.x,view.y],"panel":QA.rect(panel),"title":heading.text,"primary":QA.rect(primary),"back":QA.rect(back),"unlocked":campaign["unlocked"],"entries":ending_buttons.map(func(b): return {"rect":QA.rect(b),"disabled":b.disabled})})
func _continue() -> void:
 Session.story_mode=true
 Session.view_ending=""
 if campaign["stage"]==3: campaign=Book.defaults(campaign["unlocked"])
 Session.campaign_state=campaign.duplicate(true)
 var store:=Store.new()
 var save: Dictionary=store.load_data()
 save["campaign"]=campaign
 Session.campaign_save_failed=not store.save_data(save)
 get_tree().call_deferred("change_scene_to_file","res://scenes/journey.tscn")
func _back() -> void:
 Session.view_ending=""
 get_tree().call_deferred("change_scene_to_file","res://scenes/title.tscn")
func _input(event: InputEvent) -> void:
 Controls.observe(event)
 if event.is_action_pressed("ui_cancel"):
  _back()
  get_viewport().set_input_as_handled()
