extends Node2D
const QA := preload("res://scripts/game/qa_snapshot.gd")
## A short, keyboard/mouse/touch-friendly front door to the existing Godot game.

const UiSkin := preload("res://scripts/game/ui_skin.gd")
const GarageCast := preload("res://scripts/game/garage_cast.gd")
const Sheets := preload("res://scripts/game/sheets.gd")
const MomoFace := preload("res://scripts/game/companion_face.gd")
const SettingsPanel := preload("res://scripts/game/settings_panel.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Garage := preload("res://scripts/core/garage.gd")
const DataLoader := preload("res://scripts/core/data_loader.gd")
const Controls := preload("res://scripts/game/controls.gd")
const Book := preload("res://scripts/core/story_book.gd")
const Session := preload("res://scripts/game/session.gd")

var sheets := Sheets.new()
var ui_theme := UiSkin.theme()
var settings: Control
var help_panel: Panel
var start_button: Button
var face: Control
var cast: Control
var motion := true
var _t := 0.0
var menu_buttons: Array[Button] = []
var control_hint: Label
var footer: Label
var brand_label: Label
var universe_label: Label
var premise_label: Label
var quote_label: Label
var help_title: Label
var help_body: Label
var help_scroll: ScrollContainer
var help_start: Button
var help_back: Button
var base_rects: Dictionary = {}
var help_rects: Dictionary = {}
var campaign: Dictionary = {}

func _ready() -> void:
	add_to_group("appearance_views")
	Engine.time_scale = 1.0
	var store := SaveStore.new()
	var save: Dictionary = store.load_data()
	campaign=Book.sanitize(Session.campaign_state if not Session.campaign_state.is_empty() else save["campaign"])
	Controls.install(save["settings"]["bindings"], save["settings"]["pad_bindings"], save["settings"]["deadzone"])
	motion = bool(save["settings"]["motion"])
	var ui := CanvasLayer.new()
	add_child(ui)
	var brand := _label(ui, Rect2(24, 10, 592, 18), "FRAGARIA INTERACTIVE  /  FRAGARIA GAMES", 10)
	brand_label=brand
	brand.theme_type_variation="BrandLabel"
	universe_label = _label(ui, Rect2(24, 90, 304, 20), "A I O N I A", 14)
	universe_label.theme_type_variation="AccentLabel"
	premise_label = _label(ui, Rect2(24, 118, 310, 38), "Omega-3 ile yolun geleceğini seç.\n3 arcade etap · 13 farklı son.", 13)
	start_button = _button(ui, Rect2(24, 166, 304, 32), "Sürüşe başla · Space", _start)
	_button(ui, Rect2(24, 204, 148, 28), "Önce garaja uğra", _garage)
	_button(ui, Rect2(180, 204, 148, 28), "Sonlar · %d / 13" % campaign["unlocked"].size(), _endings)
	_button(ui, Rect2(24, 240, 148, 28), "Nasıl oynanır?", _show_help)
	_button(ui, Rect2(180, 240, 148, 28), "Ayarlar", _show_settings)
	control_hint = _label(ui, Rect2(24, 282, 308, 43), "Oklar / WASD Serbest sürüş\nE Turbo · Q Fren · Esc Mola", 11)
	footer = _label(ui, Rect2(24, 338, 592, 14), "v%s  ·  Rekor %d  ·  Kayıt bu cihazda  ·  Çevrimdışı tek oyuncu" % [str(ProjectSettings.get_setting("application/config/version")),int(save["best_score"])], 9)
	if store.last_error.begins_with("recovered_"):
		footer.text = "İlerleme kurtarma kopyasından geri alındı. Kayıt bu cihazda."
	elif store.last_error not in ["", "missing"]:
		footer.text = "Kayıt okunamadı veya daha yeni sürümden. Bu oturumda oynayabilirsin."
	face = MomoFace.new()
	face.position = Vector2(454, 103)
	face.scale = Vector2(2, 2)
	face.decorative_motion = motion
	ui.add_child(face)
	var line := _label(ui, Rect2(410, 208, 196, 52), "Bu yolun hafızasını\nbirlikte taşıyoruz.", 13)
	quote_label=line
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cast=GarageCast.new()
	ui.add_child(cast)
	_make_help(ui)
	settings = SettingsPanel.new()
	settings.z_index = 20
	settings.changed.connect(func(value: Dictionary):
		motion = bool(value["motion"])
		face.decorative_motion = motion)
	settings.closed.connect(func():
		settings.hide()
		_set_menu_enabled(true)
		start_button.grab_focus())
	settings.data_reset.connect(func():
		Session.next_run_modifiers = []
		get_tree().call_deferred("reload_current_scene"))
	ui.add_child(settings)
	_link_menu_focus()
	for child in ui.get_children():
		if child is Control and child!=settings: base_rects[child]=Rect2(child.position,child.size)
	for child in help_panel.get_children():
		if child is Control: help_rects[child]=Rect2(child.position,child.size)
	get_viewport().size_changed.connect(_layout)
	_layout()
	start_button.grab_focus()

func _link_menu_focus() -> void:
	# Explicit routes also work when buttons live directly under a CanvasLayer.
	var neighbors := [[3,1,0,0],[0,3,1,2],[0,4,1,2],[1,0,3,4],[2,0,3,4]]
	for i in menu_buttons.size():
		var button := menu_buttons[i]
		button.focus_neighbor_top = button.get_path_to(menu_buttons[neighbors[i][0]])
		button.focus_neighbor_bottom = button.get_path_to(menu_buttons[neighbors[i][1]])
		button.focus_neighbor_left = button.get_path_to(menu_buttons[neighbors[i][2]])
		button.focus_neighbor_right = button.get_path_to(menu_buttons[neighbors[i][3]])
		button.focus_next = button.get_path_to(menu_buttons[(i+1)%menu_buttons.size()])
		button.focus_previous = button.get_path_to(menu_buttons[posmod(i-1,menu_buttons.size())])

func _label(parent: Node, rect: Rect2, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.theme = ui_theme
	label.position = rect.position
	label.size = rect.size
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func _button(parent: Node, rect: Rect2, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.theme = ui_theme
	button.position = rect.position
	button.size = rect.size
	button.text = text
	UiSkin.style_button(button)
	button.pressed.connect(action)
	parent.add_child(button)
	if parent is CanvasLayer:
		menu_buttons.append(button)
	return button

func _make_help(parent: Node) -> void:
	help_panel = Panel.new()
	help_panel.position = Vector2(56, 34)
	help_panel.size = Vector2(528, 292)
	help_panel.add_theme_stylebox_override("panel", UiSkin.panel(Color("f4a8c5")))
	parent.add_child(help_panel)
	help_title = _label(help_panel, Rect2(18, 12, 492, 26), "BİR YOL, İKİ ARKADAŞ", 19)
	help_scroll=ScrollContainer.new()
	help_scroll.position=Vector2(18,48)
	help_scroll.size=Vector2(492,184)
	help_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	help_scroll.follow_focus=true
	help_panel.add_child(help_scroll)
	var body := _label(help_scroll, Rect2(0, 0, 492, 184), "1. YOLU AÇ\nPC: oklar / WASD. Mobil/tablet: sabit joystick ile dört yöne sür; sağdaki eylemleri kullan.\n\n2. Omega-3’İ KORU\nSpace / F veya fare sol ile öne ateş et; Fare sağ arkaya sınırsız mayın bırakır (X alternatif). E turbo, Q fren. Shift / C alan darbesi, R sıyrılma. Artı: onarım; şimşek: enerji; kalkan: koruma. Kesik çizgiden uzaklaş; ! işaretli noktaya engel düşecek.\n\n3. EVE DÖN\nÜç kez karar ver, her kararın ardından 400 m sür. 13 ayrı gelecekten birine ulaş. Başarısızlıkta önceki etaplar korunur. Mola menüsünde yol günlüğünü oku. Esc mola verir. T ile isteğe bağlı sohbet edebilirsin.", 12)
	help_body=body
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.custom_minimum_size=Vector2(220,0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_start = _button(help_panel, Rect2(18, 246, 236, 30), "Hazırım · Sürüşe başla", _start)
	help_back = _button(help_panel, Rect2(266, 246, 244, 30), "Geri · Esc", _hide_help)
	help_panel.hide()

func _show_help() -> void:
	_set_menu_enabled(false)
	help_panel.show()
	(help_panel.get_child(2) as Button).grab_focus()

func _hide_help() -> void:
	help_panel.hide()
	_set_menu_enabled(true)
	start_button.grab_focus()

func _show_settings() -> void:
	_set_menu_enabled(false)
	settings.open()

func _set_menu_enabled(value: bool) -> void:
	for button in menu_buttons:
		button.disabled = not value

func _start() -> void:
	var store := SaveStore.new()
	var save: Dictionary = store.load_data()
	var garage := Garage.new(DataLoader.load_json(DataLoader.GARAGE_PATH), DataLoader.load_json(DataLoader.BALANCE_PATH))
	save["upgrades"] = garage.apply_upgrade({}, "armor") if save["upgrades"].is_empty() else save["upgrades"]
	Session.story_mode=true
	Session.view_ending=""
	if campaign["stage"]==3: campaign=Book.defaults(campaign["unlocked"])
	save["campaign"]=campaign
	Session.campaign_state=campaign.duplicate(true)
	Session.campaign_save_failed=not store.save_data(save)
	Session.next_run_modifiers = []
	get_tree().call_deferred("change_scene_to_file", "res://scenes/journey.tscn")

func _endings() -> void:
	get_tree().call_deferred("change_scene_to_file","res://scenes/endings.tscn")

func _garage() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/garage.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings.visible:
			settings.close()
		elif help_panel.visible:
			_hide_help()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	Controls.observe(event)
	if help_panel.visible and (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up")):
		help_scroll.scroll_vertical+=36 if event.is_action_pressed("ui_down") else -36
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if QA.active():
		QA.publish("title",{"view":[get_viewport_rect().size.x,get_viewport_rect().size.y],"cast":cast.snapshot() if cast.visible else {},"play":QA.rect(start_button),"garage":QA.rect(menu_buttons[1]),"endings":QA.rect(menu_buttons[2]),"help":QA.rect(menu_buttons[3]),"settings":QA.rect(menu_buttons[4]),"settings_ui":QA.settings(settings),"settings_visible":settings.visible,"help_visible":help_panel.visible,"help_scroll":QA.rect(help_scroll),"help_content":QA.rect(help_body),"help_scroll_value":help_scroll.scroll_vertical})
	var caption: String="Etap %d / 3 · Devam et" % (int(campaign["stage"])+1) if campaign["stage"]>0 and campaign["stage"]<3 else ("Yeni hikâye" if campaign["stage"]==3 else "Hikâyeye başla")
	start_button.text = caption+(" · A" if Controls.last_device=="pad" else " · Space")
	control_hint.text = "Sol çubuk / D-pad Serbest sürüş\nRB Turbo · LT Fren · Start Mola" if Controls.last_device=="pad" else "Oklar / WASD Serbest sürüş\nE Turbo · Q Fren · Space Ateş"
	if DisplayServer.is_touchscreen_available():
		start_button.text=caption
		control_hint.text="Sabit joystick · Dört yön · Öne ateş / arkaya mayın\nÜç etap, üç karar. Yönünü sen seç."
	if motion:
		_t += delta
	queue_redraw()

func _draw() -> void:
	var view: Vector2=get_viewport_rect().size
	if view.y>view.x:
		draw_rect(Rect2(Vector2.ZERO,view),UiSkin.color("background"))
		draw_style_box(UiSkin.panel(Color("9de1c3")),Rect2(16,185,view.x-32,148))
		var logo := sheets.texture("assets/ui/logo.png")
		if logo: draw_texture_rect(logo,Rect2(16,38,view.x-32,(view.x-32)*logo.get_height()/float(logo.get_width())),false)
		return
	draw_set_transform((view-Vector2(640,360))/2)
	var background := sheets.texture("assets/ui/garage_bg.png")
	if background:
		draw_texture(background, Vector2.ZERO)
	draw_rect(Rect2(0, 0, 640, 360), Color(0.025, 0.045, 0.08, 0.42))
	draw_rect(Rect2(0, 0, 352, 360), UiSkin.color("surface"))
	draw_line(Vector2(352, 0), Vector2(352, 360), UiSkin.color("border"), 2)
	draw_style_box(UiSkin.panel(Color("9de1c3")), Rect2(394, 82, 220, 194))
	var logo := sheets.texture("assets/ui/logo.png")
	if logo:
		draw_texture(logo, Vector2(24, 34))


func _layout() -> void:
	var view: Vector2=get_viewport_rect().size
	var portrait := view.y>view.x
	var offset := (view-Vector2(640,360))/2 if not portrait else Vector2.ZERO
	for node in base_rects:
		node.position=base_rects[node].position+offset
		node.size=base_rects[node].size
	for node in help_rects:
		node.position=help_rects[node].position
		node.size=help_rects[node].size
	brand_label.add_theme_font_size_override("font_size",9 if portrait else 10)
	cast.visible=not portrait
	cast.position=offset+Vector2(398,260)
	cast.size=Vector2(216,74)
	cast._layout()
	face.scale=Vector2(2,2)
	if not portrait and DisplayServer.is_touchscreen_available():
		for i in menu_buttons.size():
			_set_rect(menu_buttons[i],Rect2(offset+Vector2(24 if i==0 or i%2==1 else 180,164 if i==0 else (214 if i<3 else 264)),Vector2(304 if i==0 else 148,44)))
		_set_rect(control_hint,Rect2(offset+Vector2(24,312),Vector2(304,28)))
		control_hint.add_theme_font_size_override("font_size",10)
		_set_rect(footer,Rect2(offset+Vector2(24,346),Vector2(592,14)))
		_set_rect(help_start,Rect2(18,238,236,44))
		_set_rect(help_back,Rect2(266,238,244,44))
	if portrait:
		_set_rect(brand_label,Rect2(16,12,view.x-32,18))
		_set_rect(universe_label,Rect2(16,105,view.x-32,20))
		_set_rect(premise_label,Rect2(16,138,view.x-32,40))
		face.position=Vector2(view.x/2-48,195)
		_set_rect(quote_label,Rect2(24,286,view.x-48,44))
		var y := maxf(352,view.y-258)
		_set_rect(menu_buttons[0],Rect2(16,y,view.x-32,48))
		_set_rect(menu_buttons[1],Rect2(16,y+56,(view.x-40)/2,44))
		_set_rect(menu_buttons[2],Rect2(24+(view.x-40)/2,y+56,(view.x-40)/2,44))
		_set_rect(menu_buttons[3],Rect2(16,y+108,(view.x-40)/2,44))
		_set_rect(menu_buttons[4],Rect2(24+(view.x-40)/2,y+108,(view.x-40)/2,44))
		_set_rect(control_hint,Rect2(16,y+164,view.x-32,42))
		_set_rect(footer,Rect2(16,view.y-30,view.x-32,22))
		footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		_set_rect(help_panel,Rect2(12,24,view.x-24,view.y-48))
		var width := view.x-60
		_set_rect(help_title,Rect2(18,12,width,26))
		_set_rect(help_scroll,Rect2(18,48,width,view.y-228))
		_set_rect(help_start,Rect2(18,view.y-168,width,44))
		_set_rect(help_back,Rect2(18,view.y-116,width,44))
	queue_redraw()

func _set_rect(node: Control,rect: Rect2) -> void:
	node.position=rect.position
	node.size=rect.size
