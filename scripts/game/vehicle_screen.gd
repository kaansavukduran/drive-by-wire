extends Node2D
const Vehicles=preload("res://scripts/core/vehicles.gd")
const Store=preload("res://scripts/core/save_store.gd")
const UiSkin=preload("res://scripts/game/ui_skin.gd")
const Controls=preload("res://scripts/game/controls.gd")
const TextFit=preload("res://scripts/game/text_fit.gd")
const QA=preload("res://scripts/game/qa_snapshot.gd")
var store:=Store.new()
var save: Dictionary
var buttons: Array[Button]=[]
var back: Button
var title: Label
var description: Label
var status: Label
var panel: Panel
var preview: Sprite2D
var selected:="roadster"
func _ready() -> void:
 save=store.load_data();selected=save["vehicle"]
 Controls.install(save["settings"]["bindings"],save["settings"]["pad_bindings"],save["settings"]["deadzone"])
 panel=Panel.new();panel.theme=UiSkin.theme();panel.add_theme_stylebox_override("panel",UiSkin.panel());add_child(panel)
 title=_label("Arabanı seç",20);description=_label("",13);status=_label("",11)
 for id in Vehicles.IDS:
  var b:=Button.new();b.text=Vehicles.ITEMS[id]["name"];UiSkin.style_button(b)
  b.pressed.connect(func():_select(id));panel.add_child(b);buttons.append(b)
 back=Button.new();back.text="Ana menü · Esc / B";UiSkin.style_button(back);back.pressed.connect(_back);panel.add_child(back)
 preview=Sprite2D.new();preview.centered=false;preview.offset=Vector2(-32,-43.5);preview.region_enabled=true;preview.region_rect=Rect2(0,0,64,96);panel.add_child(preview)
 _refresh();get_viewport().size_changed.connect(_layout);_layout();buttons[Vehicles.IDS.find(selected)].grab_focus()
func _label(text: String,font_size: int) -> Label:
 var l:=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",font_size);panel.add_child(l);return l
func _select(id: String) -> void:
 selected=Vehicles.sanitize(id);save["vehicle"]=selected
 var saved:=store.save_data(save)
 _refresh();status.text="Seçildi · Bu cihazda kaydedildi." if saved else "Kayıt yazılamadı. Yeniden seçerek dene."
func _refresh() -> void:
 for child in preview.get_children():child.free()
 Vehicles.configure(preview,selected,1.5)
 description.text=Vehicles.ITEMS[selected]["description"]+"\nSürüş ve silah dengesi tüm araçlarda aynı."
 for i in buttons.size():buttons[i].text=("✓ " if Vehicles.IDS[i]==selected else "")+Vehicles.ITEMS[Vehicles.IDS[i]]["name"]
 status.text="Seçili: "+Vehicles.ITEMS[selected]["name"]
func _layout() -> void:
 var v:=get_viewport_rect().size;var p:=v.y>v.x
 panel.position=Vector2(12,12) if p else (v-Vector2(600,336))/2;panel.size=v-Vector2(24,24) if p else Vector2(600,336)
 var w:=panel.size.x;var bottom:=panel.size.y
 title.position=Vector2(12,10);title.size=Vector2(w-24,30)
 preview.position=Vector2(w/2,112) if p else Vector2(140,157);Vehicles.configure(preview,selected,1.5)
 description.position=Vector2(12,208) if p else Vector2(268,55);description.size=Vector2(w-24,70) if p else Vector2(312,88)
 for i in buttons.size():
  buttons[i].position=Vector2(12,300+i*52) if p else Vector2(268,132+i*48);buttons[i].size=Vector2(w-24,44) if p else Vector2(312,44)
 status.position=Vector2(12,bottom-82);status.size=Vector2(w-24 if p else 230,28)
 back.position=Vector2(12,bottom-52);back.size=Vector2(w-24,44)
 var actions: Array=buttons+[back]
 for i in actions.size():
  for direction in ["top","left"]: actions[i].set("focus_neighbor_"+direction,actions[i].get_path_to(actions[posmod(i-1,actions.size())]))
  for direction in ["bottom","right"]:actions[i].set("focus_neighbor_"+direction,actions[i].get_path_to(actions[(i+1)%actions.size()]))
func _input(event: InputEvent) -> void:Controls.observe(event)
func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):_back();get_viewport().set_input_as_handled()
func _back() -> void:get_tree().call_deferred("change_scene_to_file","res://scenes/title.tscn")
func _process(_delta: float) -> void:
 if QA.active():QA.publish("vehicles",{"view":[get_viewport_rect().size.x,get_viewport_rect().size.y],"selected":selected,"buttons":buttons.map(func(b):return QA.rect(b)),"back":QA.rect(back),"fits":TextFit.fits(description) and TextFit.fits(status),"status":status.text})
