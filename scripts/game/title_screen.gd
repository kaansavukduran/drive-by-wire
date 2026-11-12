extends Node2D
## A short, keyboard/mouse/touch-friendly front door to the existing Godot game.

const UiSkin := preload("res://scripts/game/ui_skin.gd")
const Sheets := preload("res://scripts/game/sheets.gd")
const MomoFace := preload("res://scripts/game/momo_face.gd")
const SettingsPanel := preload("res://scripts/game/settings_panel.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Garage := preload("res://scripts/core/garage.gd")
const DataLoader := preload("res://scripts/core/data_loader.gd")
const Session := preload("res://scripts/game/session.gd")

var sheets := Sheets.new()
var ui_theme := UiSkin.theme()
var settings: Control
var help_panel: Panel
var start_button: Button
var face: Control
var motion := true
var _t := 0.0
var menu_buttons: Array[Button] = []

func _ready() -> void:
	Engine.time_scale = 1.0
	var store := SaveStore.new()
	var save: Dictionary = store.load_data()
	motion = bool(save["settings"]["motion"])
	var ui := CanvasLayer.new()
	add_child(ui)
	var brand := _label(ui, Rect2(24, 10, 592, 18), "FRAGARIA INTERACTIVE  /  FRAGARIA GAMES", 10)
	brand.modulate = Color("f4a8c5")
	_label(ui, Rect2(24, 90, 304, 20), "A I O N I A", 14).modulate = Color("9de1c3")
	_label(ui, Rect2(24, 118, 310, 38), "MOMO'yla 1.200 metreyi aş.\nHızını seç. Yol arkadaşını koru.", 13)
	start_button = _button(ui, Rect2(24, 166, 304, 32), "Sürüşe başla · Space", _start)
	_button(ui, Rect2(24, 204, 304, 28), "Önce garaja uğra", _garage)
	_button(ui, Rect2(24, 240, 148, 28), "Nasıl oynanır?", _show_help)
	_button(ui, Rect2(180, 240, 148, 28), "Ayarlar", _show_settings)
	_label(ui, Rect2(24, 282, 308, 43), "← → Şerit  ·  Space Ateş\n↑ Turbo  ·  ↓ Fren  ·  Esc Mola", 11)
	_label(ui, Rect2(24, 338, 592, 14), "v0.3.0  ·  Rekor %d  ·  Kayıt bu cihazda  ·  Çevrimdışı tek oyuncu" % int(save["best_score"]), 9)
	face = MomoFace.new()
	face.position = Vector2(454, 103)
	face.scale = Vector2(2, 2)
	face.set_process(motion)
	ui.add_child(face)
	var line := _label(ui, Rect2(410, 208, 196, 64), "Direksiyon sende.\nBirlikte eve döneceğiz.", 13)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_make_help(ui)
	settings = SettingsPanel.new()
	settings.z_index = 20
	settings.changed.connect(func(value: Dictionary):
		motion = bool(value["motion"])
		face.set_process(motion))
	settings.closed.connect(func():
		settings.hide()
		_set_menu_enabled(true)
		start_button.grab_focus())
	ui.add_child(settings)
	start_button.grab_focus()

func _label(parent: Node, rect: Rect2, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.theme = ui_theme
	label.position = rect.position
	label.size = rect.size
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("fff2df"))
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
	_label(help_panel, Rect2(18, 12, 492, 26), "BİR YOL, İKİ ARKADAŞ", 19)
	var body := _label(help_panel, Rect2(18, 48, 492, 184), "1. YOLU AÇ\nSol / sağ oklarla şerit değiştir. Yukarı ok turbo, aşağı ok fren.\n\n2. MOMO'YU KORU\nSpace / F basılıyken en yakın tehdide ateş et. X mayın, Shift sıyrılma, C destek. Artı: onarım; şimşek: enerji; kalkan: koruma.\n\n3. EVE DÖN\n1.200 metreye ulaş. Görevleri ve seri puanını büyüt. Esc mola verir. T ile isteğe bağlı sohbet edebilirsin.", 12)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(help_panel, Rect2(18, 246, 236, 30), "Hazırım · Sürüşe başla", _start)
	_button(help_panel, Rect2(266, 246, 244, 30), "Geri · Esc", _hide_help)
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
	save["upgrades"] = garage.apply_upgrade({}, "armor")
	store.save_data(save)
	Session.next_run_modifiers = []
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main.tscn")

func _garage() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/garage.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings.visible:
			settings.closed.emit()
		elif help_panel.visible:
			_hide_help()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if motion:
		_t += delta
	queue_redraw()

func _draw() -> void:
	var background := sheets.texture("assets/ui/garage_bg.png")
	if background:
		draw_texture(background, Vector2.ZERO)
	draw_rect(Rect2(0, 0, 640, 360), Color(0.025, 0.045, 0.08, 0.42))
	draw_rect(Rect2(0, 0, 352, 360), Color("111d2bf2"))
	draw_line(Vector2(352, 0), Vector2(352, 360), Color("415774"), 2)
	draw_style_box(UiSkin.panel(Color("9de1c3")), Rect2(394, 82, 220, 194))
	var logo := sheets.texture("assets/ui/logo.png")
	if logo:
		draw_texture(logo, Vector2(24, 34))
	sheets.draw_anim(self, "characters", "aion_idle", _t, Vector2(428, 329))
	sheets.draw_anim(self, "characters", "omer_idle", _t, Vector2(574, 329), Color.WHITE, true)
