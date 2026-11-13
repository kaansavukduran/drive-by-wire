extends Node2D
const TextFit := preload("res://scripts/game/text_fit.gd")
const QA := preload("res://scripts/game/qa_snapshot.gd")
## Garaj: Omega-3 selamlar (güven + hafıza), 3–4 seçenekli kısa diyalog, tek yükseltme
## seçimi, "Sefere çık". Klavye: 1–4 seçer, Enter devam/sefere çık. Fare/dokunma da çalışır.

const DataLoader := preload("res://scripts/core/data_loader.gd")
const Momo := preload("res://scripts/core/momo.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Garage := preload("res://scripts/core/garage.gd")
const Book := preload("res://scripts/core/story_book.gd")
const Session := preload("res://scripts/game/session.gd")
const MomoFace := preload("res://scripts/game/companion_face.gd")
const FONT_FALLBACK := preload("res://assets/fonts/Lexend.ttf")
const FONT_TERM := preload("res://assets/fonts/VT323.ttf")
const GarageCast := preload("res://scripts/game/garage_cast.gd")
const Sheets := preload("res://scripts/game/sheets.gd")
const UiSkin := preload("res://scripts/game/ui_skin.gd")
const Controls := preload("res://scripts/game/controls.gd")
const FONT_SYMBOLS := preload("res://assets/fonts/ControlSymbols.ttf")

const W := 640.0
const H := 360.0

var rng := RandomNumberGenerator.new()
var balance: Dictionary
var garage: RefCounted
var momo: RefCounted
var store: RefCounted
var save: Dictionary
var dialogue: Dictionary = {}
var offers: Array = []
var app_version: String=str(ProjectSettings.get_setting("application/config/version"))
var stage := "dialogue"  # dialogue -> upgrade -> ready
var chosen_upgrade := ""
var theme := UiSkin.theme()
var face: Control
var speech: Label
var info: Label
var title: Label
var brand_label: Label
var brief_label: Label
var face_base_position := Vector2.ZERO
var quick_button: Button
var buttons: GridContainer
var cast: Control
var speech_next: Button
var speech_pages: Array[String]=[]
var speech_page := 0
var speech_full := ""
var _t := 0.0
var sheets := Sheets.new()
var has_art := false


func _ready() -> void:
	rng.randomize()
	Engine.time_scale = 1.0
	balance = DataLoader.load_json(DataLoader.BALANCE_PATH)
	garage = Garage.new(DataLoader.load_json(DataLoader.GARAGE_PATH), balance)
	store = SaveStore.new()
	save = store.load_data()
	Controls.install(save["settings"]["bindings"],save["settings"]["pad_bindings"],save["settings"]["deadzone"])
	momo = Momo.new(balance, DataLoader.load_json(DataLoader.MOMO_LINES_PATH), float(save.get("trust", 50.0)))
	var ui := CanvasLayer.new()
	add_child(ui)
	has_art = sheets.texture("assets/ui/garage_bg.png") != null
	title = _label(ui, Vector2(16, 10), Vector2(300, 24), 18)
	title.text = "" if has_art else "DRIVE-BY WIRE · GARAJ"

	face = MomoFace.new()
	face.decorative_motion = bool(save.get("settings", {}).get("motion", true))
	var term: Array = sheets.image("garage_bg").get("terminal_screen_rect", [40, 64, 48, 44])
	face.position = Vector2(float(term[0]), float(term[1])) if has_art else Vector2(40, 64)
	face.scale = Vector2.ONE if has_art else Vector2(2, 2)
	face_base_position=face.position
	add_child(face)
	speech = _label(ui, Vector2(16, 62), Vector2(500, 70), 13)
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.clip_text=true
	var bubble := StyleBoxFlat.new()
	bubble.bg_color = Color(0.93, 0.95, 1.0)
	bubble.set_corner_radius_all(0)
	bubble.border_color = Color("101018")
	bubble.set_border_width_all(2)
	bubble.set_content_margin_all(8)
	speech.add_theme_stylebox_override("normal", UiSkin.panel())
	speech.add_theme_constant_override("outline_size", 0)
	info = _label(ui, Vector2(16, 336), Vector2(608, 18), 10)
	info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	info.modulate = Color(1, 1, 1, 0.8)
	buttons = GridContainer.new()
	buttons.columns=2
	buttons.add_theme_constant_override("h_separation",6)
	buttons.add_theme_constant_override("v_separation",6)
	buttons.position = Vector2(16, 140)
	buttons.size = Vector2(500, 150)
	buttons.add_theme_constant_override("separation", 6)
	ui.add_child(buttons)
	var brand := _label(ui, Vector2(326, 10), Vector2(298, 17), 10)
	brand_label=brand
	brand.text = "FRAGARIA GAMES · AIONIA"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var brief := _label(ui, Vector2(16, 290), Vector2(410, 40), 11)
	brief_label=brief
	brief.text = "← → Sür · ↑ Turbo · ↓ Fren · Space Ateş\nÜç etabı aş. Omega-3 ile geleceğini seç."
	var quick := Button.new()
	quick_button = quick
	quick.theme = theme
	quick.position = Vector2(326, 32)
	quick.size = Vector2(298, 24)
	quick.text = "Hızlı sürüş · Space"
	quick.pressed.connect(_quick_start)
	UiSkin.style_button(quick)
	ui.add_child(quick)
	quick.grab_focus()
	cast=GarageCast.new()
	ui.add_child(cast)
	speech_next=Button.new()
	speech_next.theme=theme
	speech_next.add_theme_font_size_override("font_size",11)
	speech_next.pressed.connect(func(): speech_page=(speech_page+1)%speech_pages.size();_show_speech_page())
	speech_next.tooltip_text="Konuşmanın sonraki sayfasını oku"
	UiSkin.style_button(speech_next)
	ui.add_child(speech_next)

	var greet: Dictionary = garage.greeting(momo, save.get("memory", {}), rng)
	var opening := str(greet.get("text", "Hoş geldin."))
	dialogue = garage.pick_dialogue(momo.trust, save.get("memory", {}), rng)
	if dialogue.is_empty():
		_say(opening)
		_show_upgrades()
	else:
		_say(opening + "\n" + str(dialogue.get("prompt", "")))
		var options: Array = dialogue.get("options", [])
		for i in range(options.size()):
			var opt: Dictionary = options[i]
			_button("%d) %s" % [i + 1, str(opt.get("text", ""))], _choose.bind(str(opt.get("id", ""))))
	_update_info()
	_link_focus()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _label(parent: Node, pos: Vector2, size: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.theme = theme
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l)
	return l


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.theme = theme
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(0, 56)
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	UiSkin.style_button(b)
	buttons.add_child(b)
	return b


func _clear_buttons() -> void:
	for c in buttons.get_children():
		c.hide()
		c.queue_free()


func _say(text: String) -> void:
	speech_full=text
	speech_page=0
	_paginate_speech()
	face.talking = 1.5

func _paginate_speech() -> void:
	speech_pages=TextFit.pages(speech_full,speech)
	speech_page=mini(speech_page,speech_pages.size()-1)
	_show_speech_page()

func _show_speech_page() -> void:
	speech.text=speech_pages[speech_page]
	speech_next.visible=speech_pages.size()>1
	speech_next.text="İleri\n%d/%d" % [speech_page+1,speech_pages.size()]
	_link_focus()


func _choose(option_id: String) -> void:
	if stage != "dialogue":
		return
	var res: Dictionary = garage.apply_choice(dialogue, option_id, momo, save.get("memory", {}))
	if not bool(res.get("ok", false)):
		return
	save["memory"] = res.get("memory", save.get("memory", {}))
	save["trust"] = momo.trust
	Session.next_run_modifiers = res.get("next_run_modifiers", [])
	var d := float(res.get("trust_delta", 0.0))
	_say(str(res.get("reply", "")) + ("" if is_zero_approx(d) else "   (güven %s%d)" % ["+" if d > 0 else "", int(round(d))]))
	store.save_data(save)
	_show_upgrades()


func _show_upgrades() -> void:
	stage = "upgrade"
	_clear_buttons()
	offers = garage.offer_upgrades({}, rng)
	for i in range(offers.size()):
		var u: Dictionary = offers[i]
		_button("%d) %s · %s" % [i + 1, str(u.get("name", u.get("id", ""))), str(u.get("description", ""))], _pick_upgrade.bind(str(u.get("id", ""))))
	_update_info()
	_layout()
	_focus_options()
	_link_focus()


func _link_focus() -> void:
	# A fixed column needs a predictable controller route, independent of geometry.
	var order: Array[Button] = [quick_button]
	for child in buttons.get_children():
		if child is Button and child.visible and not child.is_queued_for_deletion():
			order.append(child)
	if is_instance_valid(speech_next) and speech_next.visible: order.append(speech_next)
	for i in order.size():
		var previous := order[posmod(i - 1,order.size())]
		var next := order[(i + 1) % order.size()]
		order[i].focus_neighbor_top = order[i].get_path_to(previous)
		order[i].focus_neighbor_bottom = order[i].get_path_to(next)
		order[i].focus_previous = order[i].get_path_to(previous)
		order[i].focus_next = order[i].get_path_to(next)


func _focus_options() -> void:
	for child in buttons.get_children():
		if child is Button and not child.is_queued_for_deletion():
			child.call_deferred("grab_focus")
			return


func _pick_upgrade(id: String) -> void:
	if stage != "upgrade":
		return
	chosen_upgrade = id
	save["upgrades"] = garage.apply_upgrade({}, id)  # the car is rebuilt every run; Omega-3 is what persists
	store.save_data(save)
	stage = "ready"
	_clear_buttons()
	var name := id
	for u in offers:
		if str(u.get("id", "")) == id:
			name = str(u.get("name", id))
	var go := _button("Enter) Sefere çık  ·  takılı: %s" % name, _start_run)
	_layout()
	go.grab_focus()
	_link_focus()
	_update_info()


func _start_run() -> void:
	var campaign: Dictionary=Book.sanitize(Session.campaign_state if not Session.campaign_state.is_empty() else save["campaign"])
	if campaign["stage"]==3: campaign=Book.defaults(campaign["unlocked"])
	save["campaign"]=campaign
	Session.campaign_state=campaign.duplicate(true)
	Session.campaign_save_failed=not store.save_data(save)
	Session.story_mode=true
	get_tree().call_deferred("change_scene_to_file", "res://scenes/journey.tscn")


func _quick_start() -> void:
	# A quick run always rebuilds the car with the same friendly starter armour.
	save["upgrades"] = garage.apply_upgrade({}, "armor") if save["upgrades"].is_empty() else save["upgrades"]
	Session.next_run_modifiers = []
	_start_run()


func _input(event: InputEvent) -> void:
	Controls.observe(event)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().call_deferred("change_scene_to_file", "res://scenes/title.tscn")
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: int = event.keycode
	if k == KEY_SPACE:
		_quick_start()
		return
	if stage == "ready" and k in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		_start_run()
		return
	var n := -1
	if k >= KEY_1 and k <= KEY_9:
		n = k - KEY_1
	elif k >= KEY_KP_1 and k <= KEY_KP_9:
		n = k - KEY_KP_1
	if n < 0:
		return
	if stage == "dialogue":
		var options: Array = dialogue.get("options", [])
		if n < options.size():
			_choose(str(options[n].get("id", "")))
	elif stage == "upgrade" and n < offers.size():
		_pick_upgrade(str(offers[n].get("id", "")))


func _update_info() -> void:
	var mem: Dictionary = save.get("memory", {})
	info.text = "v%s · Güven %d · Sefer %d · Rekor %d · En uzun %d m" % [
		app_version,int(momo.trust), int(mem.get("runs", 0)), int(save.get("best_score", 0)), int(mem.get("best_distance", 0))]
	var view: Vector2=get_viewport_rect().size
	if view.y>view.x:
		info.text="v%s · Güven %d · Rekor %d\nİlerleme bu cihazda." % [app_version,int(momo.trust),int(save.get("best_score",0))]
	elif DisplayServer.is_touchscreen_available():
		info.text="FRAGARIA · v%s · Rekor %d · Kayıt bu cihazda" % [app_version,int(save.get("best_score",0))]
	face.mood = momo.mood


func _process(delta: float) -> void:
	if QA.active():
		QA.publish("garage",{"view":[get_viewport_rect().size.x,get_viewport_rect().size.y],"speech":QA.rect(speech),"speech_next":QA.rect(speech_next),"speech_pages":speech_pages.size(),"speech_page":speech_page,"cast":cast.snapshot(),"brief":QA.rect(brief_label),"brief_visible":brief_label.visible,"footer":QA.rect(info),"stage":stage,"quick":QA.rect(quick_button),"buttons":buttons.get_children().filter(func(child): return child is Button and not child.is_queued_for_deletion()).map(func(button): return QA.rect(button))})
	if bool(save.get("settings", {}).get("motion", true)):
		_t += delta
	if Controls.last_device == "pad":
		info.text = "D-pad / sol çubuk: seçim · A: onay · B: ana menü"
	else:
		_update_info()
	queue_redraw()


func _draw() -> void:
	var view: Vector2=get_viewport_rect().size
	if view.y>view.x:
		draw_rect(Rect2(Vector2.ZERO,view),UiSkin.color("background"))
		return
	draw_set_transform((view-Vector2(640,360))/2)
	if has_art:
		draw_texture(sheets.texture("assets/ui/garage_bg.png"), Vector2.ZERO)
		# Runtime terminal surface covers the historical baked MOMO label.
		draw_rect(Rect2(530,171,50,46),Color("101a23"))
		for surface in [Rect2(318,6,312,24),Rect2(8,330,624,25),Rect2(8,306,420,24)]:
			draw_rect(surface,UiSkin.color("surface"))
		var logo := sheets.texture("assets/ui/logo.png")
		if logo:
			draw_texture(logo, Vector2(12, 8))
		return
	# Placeholder pixel garage until the garage background sheet lands in assets/.
	draw_rect(Rect2(0, 0, W, H), Color("1b1d2b"))
	draw_rect(Rect2(0, 250, W, 110), Color("2a2c3a"))
	for x in range(0, int(W), 32):
		draw_rect(Rect2(x, 250, 1, 110), Color("23253a"))
	draw_rect(Rect2(0, 248, W, 2), Color("e0b84a"))
	# shutter door with the dystopian glow outside
	draw_rect(Rect2(430, 40, 190, 208), Color("101018"))
	draw_rect(Rect2(434, 44, 182, 204), Color("3d2f4f"))
	for y in range(48, 160, 8):
		draw_rect(Rect2(434, y, 182, 5), Color("4a3a5e"))
	draw_rect(Rect2(434, 160, 182, 88), Color("ff5a8a").darkened(0.6))
	for i in range(6):
		var bx := 440 + i * 30
		var bh := 20 + (i * 37) % 50
		draw_rect(Rect2(bx, 248 - bh, 22, bh), Color("150f22"))
		draw_rect(Rect2(bx + 4, 248 - bh + 6, 3, 3), Color("ffd84a") if int(_t * 2 + i) % 3 else Color("7fe7ff"))
	# lamp
	draw_rect(Rect2(300, 0, 2, 30), Color("4a4f63"))
	draw_rect(Rect2(290, 30, 22, 6), Color("e0b84a"))
	var glow := Color(1.0, 0.85, 0.4, 0.06)
	for r in [60.0, 45.0, 30.0]:
		draw_circle(Vector2(301, 40), r, glow)
	# tools wall
	draw_rect(Rect2(16, 160, 110, 70), Color("2f3140"))
	for i in range(5):
		draw_rect(Rect2(24 + i * 20, 168, 4, 30 + (i % 2) * 10), Color("9aa0aa"))
		draw_rect(Rect2(22 + i * 20, 166, 8, 4), Color("c0392b") if i % 2 else Color("d4a017"))


func _layout() -> void:
	var view: Vector2=get_viewport_rect().size
	var portrait := view.y>view.x
	var touch_landscape := not portrait and DisplayServer.is_touchscreen_available()
	var offset := (view-Vector2(640,360))/2 if not portrait else Vector2.ZERO
	quick_button.position=Vector2(16,16) if portrait else offset+Vector2(326,8 if touch_landscape else 32)
	quick_button.size=Vector2(view.x-32,44) if portrait else Vector2(298,44 if touch_landscape else 28)
	brand_label.visible=not touch_landscape
	brand_label.position=Vector2(16,64) if portrait else offset+Vector2(326,10)
	brand_label.size=Vector2(view.x-32,18) if portrait else Vector2(298,17)
	speech.position=Vector2(16,90) if portrait else offset+Vector2(16,62)
	speech.size=Vector2(view.x-100,100) if portrait else Vector2(548,70)
	speech_next.position=Vector2(view.x-76,90) if portrait else offset+Vector2(572,62)
	speech_next.size=Vector2(60,100 if portrait else 70)
	buttons.columns=1 if portrait else 2
	buttons.position=Vector2(16,204) if portrait else offset+Vector2(16,140)
	buttons.size=Vector2(view.x-32,242) if portrait else Vector2(608,118)
	for button in buttons.get_children():
		if button is Button: button.custom_minimum_size.y=56
	brief_label.visible=not touch_landscape
	brief_label.position=Vector2(16,view.y-190) if portrait else offset+Vector2(16,308)
	brief_label.size=Vector2(view.x-32,28) if portrait else Vector2(380,20)
	brief_label.text="Bu etap için bir yükseltme seç." if stage=="upgrade" else "3 etap · 13 son. Sabit joystick / oklar ile sür."
	info.position=Vector2(16,view.y-80) if portrait else offset+Vector2(16,336)
	info.size=Vector2(view.x-32,40) if portrait else Vector2(608,18)
	info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	cast.position=Vector2(16,view.y-156) if portrait else offset+Vector2(408,260)
	cast.size=Vector2(view.x-32,74) if portrait else Vector2(216,74)
	cast._layout()
	_paginate_speech()
	face.position=face_base_position+offset
	face.visible=not portrait
	queue_redraw()
