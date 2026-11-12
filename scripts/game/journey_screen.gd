extends Node
const QA := preload("res://scripts/game/qa_snapshot.gd")
const Journey := preload("res://scripts/core/journey.gd")
const Book := preload("res://scripts/core/story_book.gd")
const Session := preload("res://scripts/game/session.gd")
const Controls := preload("res://scripts/game/controls.gd")
const Store := preload("res://scripts/core/save_store.gd")
const UiSkin := preload("res://scripts/game/ui_skin.gd")
var panel: PanelContainer
var routes: GridContainer
var choices: Array[Button] = []
var back: Button
var instructions: Label
var campaign: Dictionary
var store: RefCounted
var save: Dictionary
var save_error := false
func _ready() -> void:
 Engine.time_scale=1.0
 store=Store.new()
 save=store.load_data()
 Controls.install(save["settings"]["bindings"],save["settings"]["pad_bindings"],save["settings"]["deadzone"])
 campaign=Book.sanitize(Session.campaign_state if not Session.campaign_state.is_empty() else save["campaign"])
 if Session.story_mode and campaign["stage"]==3:
  get_tree().call_deferred("change_scene_to_file","res://scenes/ending.tscn")
  return
 panel=PanelContainer.new()
 panel.theme=UiSkin.theme()
 panel.add_theme_stylebox_override("panel",UiSkin.panel(Color("9de1c3")))
 add_child(panel)
 var column:=VBoxContainer.new()
 column.add_theme_constant_override("separation",8)
 panel.add_child(column)
 var title: String=Book.node(campaign)["title"] if Session.story_mode else Journey.new().data["chapter"]
 _label(column,title,18).theme_type_variation="AccentLabel"
 var scroll:=ScrollContainer.new()
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus=true
 column.add_child(scroll)
 var body:=VBoxContainer.new()
 body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 body.add_theme_constant_override("separation",10)
 scroll.add_child(body)
 _label(body,str(Book.node(campaign)["text"]) if Session.story_mode else str(Journey.new().data["premise"]),13)
 _label(body,"İLİN · Bu karar sonraki ayrımları ve sürüş koşullarını değiştirir. Her etap 400 m; başarısızlıkta bu ayrıma dönersin." if Session.story_mode else "Bu yolculukta neye öncelik verelim?",12).theme_type_variation="BrandLabel"
 if Session.story_mode and campaign["active"]: _label(body,"Kayıtlı etap: %s. Aynı kararı seçerek etabın başından devam et veya bu ayrımı değiştir." % Book.current(campaign)["name"],12)
 routes=GridContainer.new()
 routes.add_theme_constant_override("h_separation",10)
 routes.add_theme_constant_override("v_separation",10)
 body.add_child(routes)
 var options: Array=Book.node(campaign)["choices"] if Session.story_mode else Journey.new().data["routes"].values()
 for i in options.size():
  var spec: Dictionary=options[i]
  var button:=Button.new()
  button.text=str(spec["name"])+"\n"+str(spec["effect"])
  button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button.custom_minimum_size.y=88
  UiSkin.style_button(button)
  button.pressed.connect(_choose.bind(str(spec["id"]) if Session.story_mode else ["steady","supplies"][i]))
  routes.add_child(button)
  choices.append(button)
 instructions=_label(body,"Mobil/tablet: yolda sağa/sola kaydır; eylem düğmelerini kullan.\nPC: oklar / WASD. Kumanda: analog / D-pad. Kesik çizgi: yaklaşan atış; !: düşecek engel. Mola menüsünde yol günlüğü var.",11)
 back=Button.new()
 back.text="Ana menü · Esc / B"
 UiSkin.style_button(back)
 back.pressed.connect(_back)
 column.add_child(back)
 get_viewport().size_changed.connect(_layout)
 _layout()
 choices[0].grab_focus()
func _label(parent: Node,text: String,font_size: int) -> Label:
 var label:=Label.new()
 label.text=text
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",font_size)
 parent.add_child(label)
 return label
func _layout() -> void:
 if not is_instance_valid(panel): return
 var view: Vector2=get_viewport().get_visible_rect().size
 var portrait: bool=view.y>view.x
 panel.position=Vector2(12,16) if portrait else Vector2(24,16)
 panel.size=view-panel.position*2
 routes.columns=1 if portrait else mini(choices.size(),3)
 back.custom_minimum_size.y=44 if portrait or DisplayServer.is_touchscreen_available() else 30
 for i in choices.size():
  var b: Button=choices[i]
  b.focus_neighbor_bottom=b.get_path_to(choices[i+1] if portrait and i+1<choices.size() else back)
  b.focus_neighbor_top=b.get_path_to(choices[i-1] if portrait and i>0 else back)
  b.focus_neighbor_left=b.get_path_to(choices[maxi(0,i-1)])
  b.focus_neighbor_right=b.get_path_to(choices[mini(choices.size()-1,i+1)])
 back.focus_neighbor_top=back.get_path_to(choices[-1])
 back.focus_neighbor_bottom=back.get_path_to(choices[0])
func _input(event: InputEvent) -> void:
 Controls.observe(event)
 if event.is_action_pressed("ui_cancel"):
  _back()
  get_viewport().set_input_as_handled()
func _process(_delta: float) -> void:
 if not is_instance_valid(panel): return
 var view: Vector2=get_viewport().get_visible_rect().size
 var target: Vector2=view-(Vector2(24,32) if view.y>view.x else Vector2(48,32))
 if not panel.size.is_equal_approx(target): panel.size=target
 if QA.active():
  QA.publish("briefing",{"view":[view.x,view.y],"panel":QA.rect(panel),"steady":QA.rect(choices[0]),"supplies":QA.rect(choices[1]),"choices":choices.map(func(b): return QA.rect(b)),"stage":campaign["stage"],"back":QA.rect(back)})
func _choose(route: String) -> void:
 if Session.story_mode:
  campaign=Book.choose(campaign,route)
  Session.campaign_state=campaign.duplicate(true)
  save["campaign"]=campaign
  save_error=not store.save_data(save)
  Session.campaign_save_failed=save_error
 else: Session.next_route=route
 get_tree().call_deferred("change_scene_to_file","res://scenes/main.tscn")
func _back() -> void:
 get_tree().call_deferred("change_scene_to_file","res://scenes/title.tscn")
