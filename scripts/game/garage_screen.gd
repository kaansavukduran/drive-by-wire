extends Node2D
## Garaj: MOMO selamlar (güven + hafıza), 3–4 seçenekli kısa diyalog, tek yükseltme
## seçimi, "Sefere çık". Klavye: 1–4 seçer, Enter devam/sefere çık. Fare/dokunma da çalışır.

const DataLoader := preload("res://scripts/core/data_loader.gd")
const Momo := preload("res://scripts/core/momo.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Garage := preload("res://scripts/core/garage.gd")
const Session := preload("res://scripts/game/session.gd")
const MomoFace := preload("res://scripts/game/momo_face.gd")
const FONT := preload("res://assets/fonts/Lexend.ttf")
const Sheets := preload("res://scripts/game/sheets.gd")
const UiSkin := preload("res://scripts/game/ui_skin.gd")

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
var stage := "dialogue"  # dialogue -> upgrade -> ready
var chosen_upgrade := ""
var theme := Theme.new()
var face: Control
var speech: Label
var info: Label
var title: Label
var buttons: VBoxContainer
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
	momo = Momo.new(balance, DataLoader.load_json(DataLoader.MOMO_LINES_PATH), float(save.get("trust", 50.0)))
	theme.default_font = FONT
	theme.default_font_size = 12
	var ui := CanvasLayer.new()
	add_child(ui)
	has_art = sheets.texture("assets/ui/garage_bg.png") != null
	title = _label(ui, Vector2(16, 10), Vector2(300, 24), 18)
	title.text = "" if has_art else "DRIVE-BY WIRE · GARAJ"
	title.add_theme_color_override("font_color", Color("e0b84a"))
	face = MomoFace.new()
	var term: Array = sheets.image("garage_bg").get("terminal_screen_rect", [40, 64, 48, 44])
	face.position = Vector2(float(term[0]), float(term[1])) if has_art else Vector2(40, 64)
	face.scale = Vector2.ONE if has_art else Vector2(2, 2)
	add_child(face)
	speech = _label(ui, Vector2(16, 62), Vector2(500, 70), 13)
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var bubble := StyleBoxFlat.new()
	bubble.bg_color = Color(0.93, 0.95, 1.0)
	bubble.set_corner_radius_all(0)
	bubble.border_color = Color("101018")
	bubble.set_border_width_all(2)
	bubble.set_content_margin_all(8)
	speech.add_theme_stylebox_override("normal", UiSkin.box("assets/ui/speech_bubble.png", 6, 8) if has_art else bubble)
	speech.add_theme_color_override("font_color", Color("1b1d2b"))
	speech.add_theme_constant_override("outline_size", 0)
	info = _label(ui, Vector2(16, 336), Vector2(608, 18), 10)
	info.modulate = Color(1, 1, 1, 0.8)
	buttons = VBoxContainer.new()
	buttons.position = Vector2(16, 140)
	buttons.size = Vector2(500, 150)
	buttons.add_theme_constant_override("separation", 6)
	ui.add_child(buttons)

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


func _label(parent: Node, pos: Vector2, size: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.theme = theme
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	l.add_theme_constant_override("outline_size", 4)
	parent.add_child(l)
	return l


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.theme = theme
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(500, 22)
	b.pressed.connect(action)
	UiSkin.style_button(b)
	buttons.add_child(b)
	return b


func _clear_buttons() -> void:
	for c in buttons.get_children():
		buttons.remove_child(c)
		c.queue_free()


func _say(text: String) -> void:
	speech.text = text
	face.talking = 1.5


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
	var head := Label.new()
	head.theme = theme
	head.text = "Bu sefer için bir yükseltme seç:"
	buttons.add_child(head)
	for i in range(offers.size()):
		var u: Dictionary = offers[i]
		_button("%d) %s · %s" % [i + 1, str(u.get("name", u.get("id", ""))), str(u.get("description", ""))], _pick_upgrade.bind(str(u.get("id", ""))))
	_update_info()


func _pick_upgrade(id: String) -> void:
	if stage != "upgrade":
		return
	chosen_upgrade = id
	save["upgrades"] = garage.apply_upgrade({}, id)  # the car is rebuilt every run; MOMO is what persists
	store.save_data(save)
	stage = "ready"
	_clear_buttons()
	var name := id
	for u in offers:
		if str(u.get("id", "")) == id:
			name = str(u.get("name", id))
	var go := _button("Enter) Sefere çık  ·  takılı: %s" % name, _start_run)
	go.grab_focus()
	_update_info()


func _start_run() -> void:
	store.save_data(save)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: int = event.keycode
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
	info.text = "Güven %d · MOMO %s · Sefer %d · En uzun %d m  ·  Rakam tuşu seçer, Enter sefere çıkar" % [
		int(momo.trust), Momo.mood_name_tr(momo.mood), int(mem.get("runs", 0)), int(mem.get("best_distance", 0))]
	face.mood = momo.mood


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if has_art:
		draw_texture(sheets.texture("assets/ui/garage_bg.png"), Vector2.ZERO)
		var logo := sheets.texture("assets/ui/logo.png")
		if logo:
			draw_texture(logo, Vector2(12, 8))
		var feet := float(sheets.image("garage_bg").get("character_feet_y", 330))
		sheets.draw_anim(self, "characters", "omer_idle", _t, Vector2(560, feet))
		sheets.draw_anim(self, "characters", "aion_idle", _t + 0.4, Vector2(450, feet))
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
