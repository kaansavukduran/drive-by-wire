extends Node
## Chapter overview and honest end-of-current-content marker, not an ending gallery.
const Book=preload("res://scripts/core/story_book.gd")
const Session=preload("res://scripts/game/session.gd")
const Store=preload("res://scripts/core/save_store.gd")
const UiSkin=preload("res://scripts/game/ui_skin.gd")
const Controls=preload("res://scripts/game/controls.gd")
const QA=preload("res://scripts/game/qa_snapshot.gd")
const Reader=preload("res://scripts/game/text_reader.gd")
@export var gallery:=false
var panel: Panel
var reader: Control
var heading: Label
var status: Label
var primary: Button
var gallery_button: Button
var back: Button
var campaign: Dictionary
var ending_buttons: Array[Button]=[] # Kept empty: no invented/unlockable endings.
func _ready() -> void:
 Engine.time_scale=1
 var save: Dictionary=Store.new().load_data()
 campaign=Book.sanitize(Session.campaign_state if not Session.campaign_state.is_empty() else save["campaign"])
 Controls.install(save["settings"]["bindings"],save["settings"]["pad_bindings"],save["settings"]["deadzone"])
 panel=Panel.new();panel.theme=UiSkin.theme();panel.add_theme_stylebox_override("panel",UiSkin.panel());add_child(panel)
 heading=_label("BÖLÜMLER" if gallery else "DEVAM EDECEK",18)
 heading.theme_type_variation="BrandLabel"
 reader=Reader.new();panel.add_child(reader)
 if gallery:
  reader.set_text("13 etaplık lineer hikâye\n\nBu sürümde iki etap ve iki ara sahne oynanabilir.\n\n1. etap: Son geçiş → Emre ve Eren ile Yan yana.\n2. etap: Kırık hat → Kurt ile Uçurumun kıyısı.\n\n3–13. etaplar henüz hazırlanmadı. Sohbet yanıtları değişir; bölüm sırası ve bu sürümün bitişi değişmez.\n\nTamamlanan etap: %d / 13. Eski sürümdeki son kayıtları arşivde korunur." % int(campaign["stage"]))
 else:
  var reached: bool=campaign["phase"]=="continued"
  heading.text="DEVAM EDECEK" if reached else "HİKÂYE DEVAM EDİYOR"
  reader.set_text("Kurt: “Merak etme, sana yeni bir araba getireceğim.”\n\nAion anahtarı cebine koydu. Bu kez yolun sonuna tek başına gelmemişti.\n\n2. etap ve 2. ara sahne tamamlandı. Hikâye burada şimdilik duruyor.\n3–13. etaplar gelecek bölümlerdir; bu sürümde oynanamaz." if reached else "Bu sürüm iki etap ve iki ara sahne içeriyor. Hikâyeye kaldığın yerden devam edebilirsin.")
 status=_label("Kayıt bu cihazda." if not Session.campaign_save_failed else "Kayıt yazılamadı; ilerleme bu oturumda.",10)
 primary=_button("Hikâyeye dön" if gallery else "İlk etaptan yeniden oyna",_continue if gallery else _restart)
 gallery_button=_button("Bölümler" if not gallery else "Devam edecek" if campaign["phase"]=="continued" else "İlk etaptan oyna",func():
  if not gallery:get_tree().call_deferred("change_scene_to_file","res://scenes/endings.tscn")
  elif campaign["phase"]=="continued":get_tree().call_deferred("change_scene_to_file","res://scenes/ending.tscn")
  else:_restart())
 back=_button("Ana menü · Esc / B",_back)
 get_viewport().size_changed.connect(_layout);_layout();primary.grab_focus()
func _label(text: String,font_size: int) -> Label:
 var l:=Label.new();l.clip_text=true;l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",font_size);panel.add_child(l);return l
func _button(text: String,action: Callable) -> Button:
 var b:=Button.new();b.text=text;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;UiSkin.style_button(b);b.pressed.connect(action);panel.add_child(b);return b
func _layout() -> void:
 var view:=get_viewport().get_visible_rect().size
 var size:=Vector2(minf(view.x-16,540),minf(view.y-16,400));panel.position=(view-size)/2;panel.size=size
 heading.position=Vector2(12,8);heading.size=Vector2(size.x-24,28)
 reader.position=Vector2(12,42);reader.size=Vector2(size.x-24,size.y-178);reader.reflow()
 status.position=Vector2(12,size.y-130);status.size=Vector2(size.x-24,20)
 primary.position=Vector2(12,size.y-104);primary.size=Vector2(size.x-24,44)
 gallery_button.position=Vector2(12,size.y-52);gallery_button.size=Vector2((size.x-32)/2,44)
 back.position=Vector2(size.x/2+4,size.y-52);back.size=Vector2((size.x-32)/2,44)
 var actions: Array=[primary,gallery_button,back]
 for i in actions.size():
  for direction in ["bottom","right"]:actions[i].set("focus_neighbor_"+direction,actions[i].get_path_to(actions[(i+1)%actions.size()]))
  for direction in ["top","left"]:actions[i].set("focus_neighbor_"+direction,actions[i].get_path_to(actions[posmod(i-1,actions.size())]))
func _continue() -> void:
 Session.story_mode=true;Session.campaign_state=campaign.duplicate(true)
 get_tree().call_deferred("change_scene_to_file",Session.play_scene() if campaign["phase"] in ["interlude","continued"] else "res://scenes/journey.tscn")
func _restart() -> void:
 var old: Dictionary=campaign
 campaign=Book.defaults(old["unlocked"]);campaign["legacy"]=old["legacy"].duplicate(true)
 var store:=Store.new();var save: Dictionary=store.load_data();save["campaign"]=campaign
 Session.campaign_save_failed=not store.save_data(save);Session.story_mode=true;Session.campaign_state=campaign.duplicate(true)
 get_tree().call_deferred("change_scene_to_file","res://scenes/journey.tscn")
func _back() -> void:get_tree().call_deferred("change_scene_to_file","res://scenes/title.tscn")
func _input(event: InputEvent) -> void:
 Controls.observe(event)
 if event.is_action_pressed("ui_cancel"):_back();get_viewport().set_input_as_handled()
func _process(_delta: float) -> void:
 if QA.active():QA.publish("endings" if gallery else "ending",{"view":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y],"panel":QA.rect(panel),"title":heading.text,"primary":QA.rect(primary),"back":QA.rect(back),"overview":QA.rect(gallery_button),"unlocked":campaign["unlocked"],"entries":[],"reader":reader.snapshot(),"stage":campaign["stage"],"phase":campaign["phase"],"scrollbars":0})
