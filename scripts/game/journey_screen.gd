extends Node
const QA := preload("res://scripts/game/qa_snapshot.gd")
const Journey := preload("res://scripts/core/journey.gd")
const Session := preload("res://scripts/game/session.gd")
const Controls := preload("res://scripts/game/controls.gd")
const Store := preload("res://scripts/core/save_store.gd")
const UiSkin := preload("res://scripts/game/ui_skin.gd")
var panel: PanelContainer
var routes: GridContainer
var choices: Array[Button] = []
var back: Button
var instructions: Label
func _ready() -> void:
	Engine.time_scale=1.0
	var settings: Dictionary=Store.new().load_data()["settings"]
	Controls.install(settings["bindings"],settings["pad_bindings"],settings["deadzone"])
	var story := Journey.new()
	panel=PanelContainer.new()
	panel.theme=UiSkin.theme()
	panel.add_theme_stylebox_override("panel",UiSkin.panel(Color("9de1c3")))
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	panel.add_child(column)
	var title := _label(column,story.data["chapter"],18)
	title.modulate=Color("9de1c3")
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	column.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",10)
	scroll.add_child(body)
	_label(body,story.data["premise"],13)
	_label(body,story.data["question"],13).modulate=Color("f4a8c5")
	routes=GridContainer.new()
	routes.add_theme_constant_override("h_separation",10)
	routes.add_theme_constant_override("v_separation",10)
	body.add_child(routes)
	for route in story.data["routes"]:
		var spec: Dictionary=story.data["routes"][route]
		var button := Button.new()
		button.text=str(spec["name"])+"\n"+str(spec["effect"])
		button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y=88
		UiSkin.style_button(button)
		button.pressed.connect(_choose.bind(str(route)))
		routes.add_child(button)
		choices.append(button)
	instructions=_label(body,"",11)
	back=Button.new()
	back.text="Ana menü · Esc / B"
	back.custom_minimum_size.y=30
	UiSkin.style_button(back)
	back.pressed.connect(_back)
	column.add_child(back)
	get_viewport().size_changed.connect(_layout)
	_layout()
	choices[0].grab_focus()
func _label(parent: Node,text: String,font_size: int) -> Label:
	var label := Label.new()
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	parent.add_child(label)
	return label
func _layout() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var portrait: bool = view.y>view.x
	panel.position=Vector2(12,16) if portrait else Vector2(24,16)
	panel.size=view-panel.position*2
	routes.columns=1 if portrait else 2
	back.custom_minimum_size.y=44 if portrait else 30
	for i in choices.size():
		choices[i].focus_neighbor_bottom=choices[i].get_path_to(choices[1] if i==0 and portrait else back)
		choices[i].focus_neighbor_top=choices[i].get_path_to(back if i==0 or not portrait else choices[0])
		choices[i].focus_neighbor_left=choices[i].get_path_to(choices[0])
		choices[i].focus_neighbor_right=choices[i].get_path_to(choices[1])
	back.focus_neighbor_top=back.get_path_to(choices[1])
	back.focus_neighbor_bottom=back.get_path_to(choices[0])
func _input(event: InputEvent) -> void:
	Controls.observe(event)
	if event.is_action_pressed("ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()
func _process(_delta: float) -> void:
	var view: Vector2=get_viewport().get_visible_rect().size
	var target := view-(Vector2(24,32) if view.y>view.x else Vector2(48,32))
	if not panel.size.is_equal_approx(target): panel.size=target
	if QA.active():
		QA.publish("briefing",{"view":[get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y],"panel":QA.rect(panel),"steady":QA.rect(choices[0]),"supplies":QA.rect(choices[1]),"back":QA.rect(back)})
	instructions.text="Mobil/tablet: yolda sağa/sola kaydır. Eylem düğmelerini kullan.\nPC: oklar / WASD; fare sol ateş, sağ sıyrıl. Kumanda: analog / D-pad, A / RT ateş."
	if DisplayServer.is_touchscreen_available():
		instructions.text="Yolda sağa/sola kaydır. Ateş ve turbo basılı tutulabilir. Mola menüsünde yol günlüğünü oku."
func _choose(route: String) -> void:
	Session.next_route=route
	get_tree().call_deferred("change_scene_to_file","res://scenes/main.tscn")
func _back() -> void:
	get_tree().call_deferred("change_scene_to_file","res://scenes/title.tscn")
