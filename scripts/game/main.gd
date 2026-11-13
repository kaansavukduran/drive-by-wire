extends Node2D
const TextFit := preload("res://scripts/game/text_fit.gd")
const QA := preload("res://scripts/game/qa_snapshot.gd")
## Sefer sahnesi: doğrudan ok tuşlu sürüş, üç şeritli yol, isteğe bağlı sohbet,
## üç düşman tipi, kapsüller, turbo, görevler, puan serisi ve Omega-3 ilişkisi
## ve sefer sonu ekranı. Oyun kuralları scripts/core/ altında, sayılar data/balance.json'da.

const DataLoader := preload("res://scripts/core/data_loader.gd")
const CommandParser := preload("res://scripts/core/command_parser.gd")
const Momo := preload("res://scripts/core/momo.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Garage := preload("res://scripts/core/garage.gd")
const Session := preload("res://scripts/game/session.gd")
const MomoFace := preload("res://scripts/game/companion_face.gd")
const Sheets := preload("res://scripts/game/sheets.gd")
const UiSkin := preload("res://scripts/game/ui_skin.gd")
const Controls := preload("res://scripts/game/controls.gd")
const Arcade := preload("res://scripts/core/arcade.gd")
const Sounds := preload("res://scripts/game/sounds.gd")
const SettingsPanel := preload("res://scripts/game/settings_panel.gd")
const Book := preload("res://scripts/core/story_book.gd")
const Journey := preload("res://scripts/core/journey.gd")
const Joystick := preload("res://scripts/game/touch_joystick.gd")
const WarningView := preload("res://scripts/game/enemy_warning_view.gd")
const TouchControl := preload("res://scripts/game/touch_control.gd")
const Cast := preload("res://scripts/game/cast_portrait.gd")
const FONT_SYMBOLS := preload("res://assets/fonts/ControlSymbols.ttf")
const CAR_SHEET := preload("res://assets/sprites/aion_roadster.png")
const FONT_FALLBACK := preload("res://assets/fonts/Lexend.ttf")
const FONT_TERM := preload("res://assets/fonts/VT323.ttf")

const W := 640.0
const H := 360.0
const FW := 64
const FH := 96
const PLAYER_Y := 290.0
const PLAYER_HALF := Vector2(11, 26)
# Match the live enemy band: shots can hit pursuers, then leave bounded memory.
const COMBAT_BOUNDS := Rect2(-64,-120,W+128,H+240)
# sheet rows: animation -> [row, frames, fps, loop]
const ANIMS := {
	"drive": [0, 4, 12.0, true], "shift_left": [2, 3, 14.0, false], "shift_right": [3, 3, 14.0, false],
	"boost": [4, 4, 14.0, false], "brake": [5, 2, 8.0, false], "fire": [6, 4, 16.0, false],
	"hit": [7, 3, 14.0, false], "damaged": [8, 4, 10.0, true], "critical": [9, 4, 10.0, true],
	"destroyed": [10, 10, 12.0, false],
}
const ENEMY_HALF := {"rammer": Vector2(11, 22), "pickup": Vector2(12, 24), "truck": Vector2(14, 40)}
const TYPE_NAMES := {"rammer": "çarpan araba", "pickup": "kamyonet", "truck": "kamyon"}

var balance: Dictionary
var run_cfg: Dictionary
var parser: RefCounted
var momo: RefCounted
var store: RefCounted
var save: Dictionary
var rng := RandomNumberGenerator.new()
# Cosmetic choices and companion replies never advance traffic randomness.
var visual_rng := RandomNumberGenerator.new()
var companion_rng := RandomNumberGenerator.new()

var lane_count := 3
var lane_width := 64.0
var lane := 1
var prev_lane := 1
var lane_changed_at := -10.0
var car_x := 0.0
var car_y := PLAYER_Y
var drive_velocity := Vector2.ZERO
var lane_target := NAN
var last_drive := Vector2.UP
var speed := 220.0
var target_speed := 220.0
var hp := 100.0
var max_hp := 100.0
var invulnerable := 0.0
var dodge_left := 0.0
var dodge_cooldown := 0.0
var ram_left := 0.0
var scroll := 0.0
var distance := 0.0
var game_time := 0.0
var slow_scale := 0.1
var pending: Array = []      # {t, command}
var bullets: Array = []      # {pos, vel}
var enemy_bullets: Array = []  # {pos, vel, dmg, near}
var mines: Array = []        # {pos, arm, life}
var obstacles: Array = []    # {pos, kind, hp, dmg, near, passed}
var enemies: Array = []      # {type, pos, lane, hp, max_hp, cd, state, t, near, passed, flash}
var effects: Array = []      # {pos, t, kind}
var mines_left := 3 # Legacy supply/upgrade level; never consumed.
var mine_cooldown := 0.0
var mine_drops := 0
var fire_cooldown := 0.0
var spawn_timer := 2.0
var kills := 0
var shake := 0.0
var shake_power := 0.0
var over := false
var end_result: Dictionary = {}

var anim := "drive"
var anim_t := 0.0
var car: Sprite2D
var box: LineEdit
var bubble: Label
var hud: Label
var hint: Label
var end_panel: Label
var bubble_left := 0.0
var radio_text := ""
var radio_is_story := false
var radio_speaker := "omega"
var radio_pages: Array[String]=[]
var radio_page := 0
var radio_page_caption: Label
var face: Control
var radio_portrait: Control
var sheets := Sheets.new()
var road_scroll := 0.0
var decals: Array = []  # {pos, frame}
var props: Array = []   # {pos, anim, side}
var arcade: RefCounted
var pickups: Array = []
var pickup_timer := 2.5
var energy := 100.0
var shield_left := 0.0
var comfort_cooldown := 0.0
var boosting := false
var paused := false
var touch_held: Dictionary = {}
var pause_panel: PanelContainer
var mission: Label
var score_label: Label
var status_label: Label
var toast: Label
var toast_left := 0.0
var hp_bar: ProgressBar
var energy_bar: ProgressBar
var route_bar: ProgressBar
var ui_theme: Theme
var effects_enabled := true
var touch_controls: Array[Control] = []
var touch_enabled := false
var sounds: Node
var settings_panel: Control
var motion_enabled := true
var energy_caption: Label
var distance_caption: Label
var metrics_clock := 0.0
var pad_lane_latch := 0
var hud_clock := 0.0
var qa_clock := 0.0
var web_help_callback: JavaScriptObject
var abandon_dialog: ConfirmationDialog
var pending_exit: Callable
var journey: RefCounted
var comfort_count := 0
var joystick: Control
var road_touch_rect := Rect2()
var mouse_fire := false
var mouse_mine := false
var world_origin := Vector2.ZERO
var ui_layer: CanvasLayer
var ui_panels: Array[Panel] = []
var base_rects: Dictionary = {}
var brand_label: Label
var momo_title: Label
var pause_button: Button
var touch_hint: Label
var story_caption: Label
var touch_by_action: Dictionary = {}
var journal_panel: PanelContainer
var journal_text: Label
var journal_scroll: ScrollContainer
var result_buttons: Array[Button] = []
var layout_initialized := false
var was_portrait := false
var campaign: Dictionary = {}


func _ready() -> void:
	rng.randomize()
	visual_rng.randomize()
	companion_rng.randomize()
	var base_balance := DataLoader.load_json(DataLoader.BALANCE_PATH)
	store = SaveStore.new()
	save = store.load_data()
	journey = Journey.new(Session.next_route)
	if Session.story_mode:
		campaign=Book.sanitize(Session.campaign_state if not Session.campaign_state.is_empty() else save["campaign"])
		if not campaign["active"]:
			get_tree().call_deferred("change_scene_to_file","res://scenes/journey.tscn")
			return
		journey.configure_book(campaign)
	Controls.install(save["settings"]["bindings"], save["settings"]["pad_bindings"], save["settings"]["deadzone"])
	var garage := Garage.new(DataLoader.load_json(DataLoader.GARAGE_PATH), base_balance)
	balance = garage.effective_balance(base_balance, save.get("upgrades", {}), Session.next_run_modifiers)
	Session.next_run_modifiers = []
	run_cfg = balance.get("run", {}).duplicate(true)
	if Session.story_mode:
		run_cfg["arcade"]["finish_distance"]=Book.data()["leg_distance"]
		var spec: Dictionary=Book.current(campaign)
		run_cfg["arcade"]["pickup_interval"]=spec["pickup_interval"]
		run_cfg["spawn"]["interval_start"]*=float(spec["spawn_scale"])
		run_cfg["spawn"]["distance_unlocks"]={"pickup":60 if campaign["stage"]==0 else 0,"truck":180 if campaign["stage"]==0 else (100 if campaign["stage"]==1 else 0)}
	arcade = Arcade.new(run_cfg.get("arcade", {}))
	energy = _cfg("arcade.boost_capacity", 100)
	pickup_timer = _cfg("arcade.pickup_initial", 2.5)
	effects_enabled = bool(save.get("settings", {}).get("effects", true))
	sounds = Sounds.new()
	sounds.enabled = bool(save.get("settings", {}).get("sound", true))
	sounds.volume = float(save["settings"]["volume"])
	motion_enabled = bool(save["settings"]["motion"])
	add_child(sounds)
	Input.joy_connection_changed.connect(func(_device: int, connected: bool):
		if not connected:
			Controls.last_device = "keyboard"
			_set_paused(true))
	parser = CommandParser.new(DataLoader.load_json(DataLoader.INTENTS_PATH), balance)
	momo = Momo.new(balance, DataLoader.load_json(DataLoader.MOMO_LINES_PATH), float(save.get("trust", 50.0)))
	momo.start_run()
	lane_count = int(run_cfg.get("lane_count", 3))
	lane_width = float(run_cfg.get("lane_width", 64))
	speed = _cfg("player.base_speed", 220)
	target_speed = speed
	max_hp = _cfg("player.max_hp", 100)
	max_hp += float(journey.spec()["max_hp"])
	hp = max_hp
	mines_left = int(_cfg("mine.count", 3)) + int(journey.spec()["mines"])
	if Session.story_mode:
		var aid: Dictionary=Book.radio_reply(campaign)
		if aid.get("perk")=="mine": mines_left+=1
		elif aid.get("perk")=="shield": shield_left=7.0
	spawn_timer = _cfg("spawn.initial_delay", 2.0)
	slow_scale = float(DataLoader.dig(balance, "time.command_box_time_scale", 0.1))
	lane = lane_count / 2
	prev_lane = lane
	car_x = _lane_x(lane)
	_build_ui()
	face.decorative_motion = motion_enabled
	_say("Kayıt yazılamadı; bu oturumda devam edebilirsin." if Session.story_mode and Session.campaign_save_failed else str(journey.spec()["opening"]))
	bubble_left = 7.0
	for child in ui_layer.get_children():
		if child is Control and child != settings_panel:
			base_rects[child] = Rect2(child.position,child.size)
	get_viewport().size_changed.connect(_layout)
	_layout()
	if OS.has_feature("web"):
		web_help_callback = JavaScriptBridge.create_callback(_on_web_help)
		JavaScriptBridge.get_interface("window").addEventListener("hashchange", web_help_callback)
		_on_web_help([])


func _on_web_help(_args: Array) -> void:
	if JavaScriptBridge.eval("location.hash === '#accessible-help'"):
		_set_paused(true)


func _exit_tree() -> void:
	if OS.has_feature("web") and web_help_callback != null:
		JavaScriptBridge.get_interface("window").removeEventListener("hashchange", web_help_callback)


func _cfg(path: String, fallback: float) -> float:
	return float(DataLoader.dig(run_cfg, path, fallback))


func _build_ui() -> void:
	car = Sprite2D.new()
	car.texture = CAR_SHEET
	car.region_enabled = true
	car.centered=false
	car.offset=-Vector2(32,43.5)
	car.scale=Vector2(48.0/FW,80.0/FH)
	car.position = Vector2(car_x, car_y)
	add_child(car)
	var warning_view := WarningView.new()
	warning_view.name="EnemyWarnings"
	warning_view.z_index=1
	add_child(warning_view)
	var ui := CanvasLayer.new()
	ui_layer = ui
	add_child(ui)
	var theme := UiSkin.theme()
	ui_theme = theme
	_panel(ui, Rect2(8, 8, 176, 166))
	_panel(ui, Rect2(456, 8, 176, 166))
	_panel(ui, Rect2(8, 186, 176, 110))
	var brand := _label(ui, theme, Vector2(18, 14), Vector2(156, 16))
	brand_label = brand
	brand.text = "FRAGARIA INTERACTIVE"
	brand.add_theme_font_size_override("font_size", 9)
	brand.theme_type_variation="BrandLabel"
	score_label = _label(ui, theme, Vector2(18, 32), Vector2(158, 30))
	score_label.add_theme_font_size_override("font_size", 20)
	hud = _label(ui, theme, Vector2(18, 75), Vector2(155, 64))
	hp_bar = _bar(ui, Rect2(18, 65, 154, 6), Color("7cddb5"))
	energy_bar = _bar(ui, Rect2(18, 162, 154, 5), Color("79d4ff"))
	energy_caption = _label(ui, theme, Vector2(18, 140), Vector2(154, 16))
	energy_caption.add_theme_font_size_override("font_size", 9)
	distance_caption = _label(ui, theme, Vector2.ZERO, Vector2(90, 12))
	distance_caption.add_theme_font_size_override("font_size", 9)
	distance_caption.visible = false
	face = MomoFace.new()
	face.position = Vector2(466, 18)
	ui.add_child(face)
	radio_portrait=Cast.new()
	ui.add_child(radio_portrait)
	radio_portrait.custom_minimum_size=Vector2(44,44)
	radio_portrait.size=Vector2(44,44)
	radio_portrait.position=face.position
	radio_portrait.visible=false
	momo_title = _label(ui, theme, Vector2(523, 20), Vector2(98, 38))
	momo_title.text = "Omega-3\nYol arkadaşın"
	momo_title.add_theme_font_size_override("font_size", 10)
	bubble = _label(ui, theme, Vector2(466, 68), Vector2(156, 52))
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	radio_page_caption = _label(ui, theme, Vector2(466, 122), Vector2(156, 12))
	radio_page_caption.add_theme_font_size_override("font_size",8)
	radio_page_caption.theme_type_variation="MutedLabel"
	status_label = _label(ui, theme, Vector2(466, 136), Vector2(156, 36))
	status_label.add_theme_font_size_override("font_size", 10)
	mission = _label(ui, theme, Vector2(18, 195), Vector2(156, 96))
	mission.add_theme_font_size_override("font_size", 11)
	mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_bar = _bar(ui, Rect2(224, 8, 192, 4), Color("ffce70"))
	hint = _label(ui, theme, Vector2(456, 184), Vector2(176, 104))
	hint.text = Controls.run_hint()
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_stylebox_override("normal", UiSkin.caption())
	toast = _label(ui, theme, Vector2(202, 58), Vector2(236, 60))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.add_theme_font_size_override("font_size", 12)
	toast.theme_type_variation="WarningLabel"
	toast.add_theme_stylebox_override("normal",UiSkin.caption())
	pause_button = _control_button(ui, Rect2(466, 292, 156, 42), "Mola · Esc", func(): _set_paused(true))
	pause_button.focus_mode = Control.FOCUS_NONE
	_build_pause(ui)
	_build_touch(ui)
	_build_journal(ui)
	story_caption = _label(ui,theme,Vector2(202,16),Vector2(236,36))
	story_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	story_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	story_caption.add_theme_font_size_override("font_size",9)
	story_caption.theme_type_variation="AccentLabel"
	story_caption.add_theme_stylebox_override("normal",UiSkin.caption())
	toast.position.y=58
	end_panel = _label(ui, theme, Vector2(W / 2 - 190, 44), Vector2(380, 250))
	end_panel.z_index=40
	end_panel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_panel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_panel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_panel.add_theme_font_size_override("font_size", 12)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.06, 0.07, 0.11, 0.92)
	bg.border_color = Color("e0b84a")
	bg.set_border_width_all(2)
	bg.set_content_margin_all(12)
	end_panel.add_theme_stylebox_override("normal", UiSkin.box("assets/ui/panel.png", 6, 12) if ResourceLoader.exists("res://assets/ui/panel.png") else bg)
	end_panel.visible = false
	box = LineEdit.new()
	box.theme = theme
	box.position = Vector2(W / 2 - 160, H - 48)
	box.size = Vector2(320, 24)
	box.add_theme_font_size_override("font_size", 16)
	box.placeholder_text = "Omega-3’e yaz · Enter gönderir · Esc vazgeçer"
	box.visible = false
	box.add_theme_stylebox_override("normal", UiSkin.box("assets/ui/command_box.png", 6))
	box.add_theme_stylebox_override("focus", UiSkin.box("assets/ui/command_box.png", 6))
	box.text_submitted.connect(_on_submit)
	ui.add_child(box)


func _label(parent: Node, theme: Theme, pos: Vector2, size: Vector2) -> Label:
	var l := Label.new()
	l.theme = theme
	l.clip_text=true
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.position = pos
	l.size = size
	parent.add_child(l)
	return l


func _panel_style() -> StyleBoxFlat:
	return UiSkin.panel()

func _panel(parent: Node, rect: Rect2) -> void:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style())
	parent.add_child(panel)
	ui_panels.append(panel)


func _bar(parent: Node, rect: Rect2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = rect.position
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("28354a")
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	parent.add_child(bar)
	bar.size = rect.size
	return bar


func _control_button(parent: Node, rect: Rect2, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.theme = ui_theme
	button.position = rect.position
	button.size = rect.size
	button.text = text
	UiSkin.style_button(button)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _build_pause(parent: Node) -> void:
	pause_panel = PanelContainer.new()
	pause_panel.z_index=20
	pause_panel.position = Vector2(200, 20)
	pause_panel.size = Vector2(240, 320)
	pause_panel.theme = ui_theme
	pause_panel.add_theme_stylebox_override("panel", _panel_style())
	parent.add_child(pause_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	pause_panel.add_child(column)
	var title := Label.new()
	title.text = "MOLA · Yol seni bekler"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var items := [
		["Devam et · Esc", func(): _set_paused(false)],
		["Ayarlar", func():
			pause_panel.hide()
			settings_panel.open()],
		["Yeniden sür", func(): _confirm_abandon(_restart_run)], ["Garaja dön", func(): _confirm_abandon(_to_garage)], ["Ana menü", func(): _confirm_abandon(_to_title)],
		["Yol günlüğü", _open_journal],
	]
	for item in items:
		var button := Button.new()
		button.text = item[0]
		button.custom_minimum_size.y = 36
		UiSkin.style_button(button)
		button.pressed.connect(item[1])
		column.add_child(button)
	var touch_toggle := CheckButton.new()
	touch_toggle.text = "Dokunmatik kontroller"
	touch_toggle.button_pressed = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	touch_toggle.toggled.connect(func(value: bool):
		touch_enabled = value
		_sync_touch())
	column.add_child(touch_toggle)
	pause_panel.hide()
	settings_panel = SettingsPanel.new()
	settings_panel.z_index=30
	settings_panel.changed.connect(_apply_settings)
	settings_panel.closed.connect(func():
		settings_panel.hide()
		pause_panel.show()
		(column.get_child(1) as Button).grab_focus())
	settings_panel.data_reset.connect(func():
		Session.next_run_modifiers = []
		_to_title())
	parent.add_child(settings_panel)
	abandon_dialog = ConfirmationDialog.new()
	UiSkin.prepare_confirmation(abandon_dialog)
	abandon_dialog.title = "Bu sürüşten ayrıl?"
	abandon_dialog.dialog_text = "Bu sürüşün tamamlanmamış puanı kaybolacak. Önceki rekor ve kayıtlar korunur."
	abandon_dialog.ok_button_text = "Sürüşten ayrıl"
	abandon_dialog.cancel_button_text = "Sürüşe dön"
	abandon_dialog.confirmed.connect(func(): pending_exit.call())
	abandon_dialog.canceled.connect(func():
		pause_panel.show()
		(column.get_child(1) as Button).grab_focus())
	add_child(abandon_dialog)


func _confirm_abandon(callback: Callable) -> void:
	pending_exit = callback
	pause_panel.hide()
	abandon_dialog.popup_centered(Vector2i(400, 150))
	abandon_dialog.get_cancel_button().grab_focus()


func _apply_settings(value: Dictionary) -> void:
	save["settings"] = value.duplicate()
	effects_enabled = bool(value["effects"])
	motion_enabled = bool(value["motion"])
	sounds.enabled = bool(value["sound"])
	sounds.volume = float(value["volume"])
	if not effects_enabled:
		shake = 0.0
	face.decorative_motion = motion_enabled
	face.set_process(not paused)
	if not radio_text.is_empty(): _reflow_radio()


func _to_title() -> void:
	Engine.time_scale = 1.0
	get_tree().call_deferred("change_scene_to_file", "res://scenes/title.tscn")


func _build_touch(parent: Node) -> void:
	touch_enabled = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	var specs := [
		[Rect2(8, 316, 80, 42), "TURBO", "drive_boost"], [Rect2(96, 316, 80, 42), "FREN", "drive_brake"],
		[Rect2(456, 220, 80, 42), "SIYRIL", "drive_dodge"], [Rect2(544, 220, 80, 42), "DESTEK", "drive_comfort"],
		[Rect2(456, 316, 80, 42), "ATEŞ", "drive_fire"], [Rect2(544, 316, 80, 42), "MAYIN", "drive_mine"],
	]
	for spec in specs:
		var action: String = spec[2]
		var button := TouchControl.new()
		parent.add_child(button)
		var down := func():
			if not paused and not over and not box.visible:
				touch_held[action] = true
				_direct_action(action)
		button.setup(spec[0], spec[1], ui_theme, down, func(): touch_held.erase(action))
		button.visible = touch_enabled
		touch_controls.append(button)
		touch_by_action[action]=button
	joystick=Joystick.new()
	parent.add_child(joystick)
	touch_hint = _label(parent,ui_theme,Vector2(8,278),Vector2(176,30))
	touch_hint.text="SÜRÜŞ · 4 YÖN"
	touch_hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	touch_hint.add_theme_font_size_override("font_size",10)
	touch_hint.visible=touch_enabled


func _notice(text: String) -> void:
	toast.text = text
	toast_left = 2.0


func _lane_x(index: int) -> float:
	return W / 2 + (index - (lane_count - 1) / 2.0) * lane_width


func _lane_of(x: float) -> int:
	return clampi(roundi((x - W / 2) / lane_width + (lane_count - 1) / 2.0), 0, lane_count - 1)


# ---------------------------------------------------------------------------
# Direct driving never passes through Omega-3's probabilistic interpretation.
# Typing is an optional conversation mode, opened explicitly with T.
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	Controls.observe(event)
	if is_instance_valid(journal_panel) and journal_panel.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("drive_pause"):
			_close_journal()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			journal_scroll.scroll_vertical += 36 if event.is_action_pressed("ui_down") else -36
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(abandon_dialog) and abandon_dialog.visible:
		return
	if is_instance_valid(settings_panel) and settings_panel.visible:
		if settings_panel.capture_action != "":
			return
		if event.is_action_pressed("drive_pause"):
			settings_panel.close()
			get_viewport().set_input_as_handled()
		return
	if box.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_box()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("drive_pause") and not over:
		_set_paused(not paused)
		get_viewport().set_input_as_handled()
		return
	if paused and event.is_action_pressed("ui_cancel"):
		_set_paused(false)
		get_viewport().set_input_as_handled()
		return
	if over:
		# Recover focus after pointer/focus loss; native GUI handles A/Enter exactly once.
		if event is InputEventJoypadButton or event is InputEventJoypadMotion or event is InputEventKey:
			if not result_buttons.is_empty() and not get_viewport().gui_get_focus_owner() in result_buttons:
				result_buttons[0].grab_focus()
		return
	if paused:
		return
	if event is InputEventMouseButton and event.device != -1:
		if not event.pressed:
			if event.button_index==MOUSE_BUTTON_LEFT: mouse_fire=false
			elif event.button_index==MOUSE_BUTTON_RIGHT: mouse_mine=false
		elif event.pressed and road_touch_rect.has_point(event.position):
			if event.button_index==MOUSE_BUTTON_LEFT:
				mouse_fire=true
				_fire({})
			elif event.button_index==MOUSE_BUTTON_RIGHT:
				mouse_mine=true
				_direct_action("drive_mine")
			get_viewport().set_input_as_handled()
		return
	for action in Controls.KEYS:
		if event.is_action_pressed(action):
			_direct_action(action)
			get_viewport().set_input_as_handled()
			return


func _unhandled_input(event: InputEvent) -> void:
	if over and event.is_action_pressed("ui_cancel"):
		_to_garage()
		get_viewport().set_input_as_handled()
		return
	if over and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			_restart_run()
		elif event.keycode == KEY_G:
			_to_garage()


func _direct_action(action: String) -> void:
	if over or paused or box.visible:
		return
	match action:
		"drive_left", "drive_right", "drive_up", "drive_down": pass
		"drive_fire": _fire({})
		"drive_mine": _execute({"intent": "drop_mine"})
		"drive_dodge": _execute({"intent": "dodge"})
		"drive_chat": _open_box("")
		"drive_comfort":
			if comfort_cooldown <= 0.0:
				comfort_count += 1
				comfort_cooldown = _cfg("arcade.comfort_cooldown", 8)
				_event("comfort")
				energy = minf(_cfg("arcade.boost_capacity", 100), energy + _cfg("arcade.energy_amount", 30))
				_notice("OMEGA-3 · ALAN DARBESİ\nYakın mermiler temizlendi · +enerji")
				effects.append({"pos":Vector2(car_x,car_y),"t":0.0,"kind":"pulse","still":true})
				sounds.cue("pulse")
				for projectile in enemy_bullets:
					if projectile["pos"].distance_to(Vector2(car_x,car_y))<90: projectile["dead"]=true
				enemy_bullets=enemy_bullets.filter(func(b): return not b.get("dead",false))


func _held(action: String) -> bool:
	return Input.is_action_pressed(action) or bool(touch_held.get(action, false)) or (action=="drive_fire" and mouse_fire) or (action=="drive_mine" and mouse_mine)


func _set_paused(value: bool) -> void:
	if over:
		return
	_close_box()
	if value and paused:
		return
	paused = value
	pad_lane_latch = 0
	for device in Input.get_connected_joypads():
		Input.stop_joy_vibration(device)
	for action in Controls.KEYS:
		Input.action_release(action)
	face.set_process(not value)
	face.queue_redraw()
	_clear_pointers()
	boosting = false
	drive_velocity=Vector2.ZERO
	pause_panel.visible = value
	_sync_touch()
	if value:
		(pause_panel.get_child(0).get_child(1) as Button).grab_focus()
	else:
		var focus := get_viewport().gui_get_focus_owner()
		if focus:
			focus.release_focus()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(pause_panel) and not over:
		_set_paused(true)


func _restart_run() -> void:
	Engine.time_scale = 1.0
	Session.next_route = journey.route
	get_tree().call_deferred("change_scene_to_file","res://scenes/ending.tscn" if Session.story_mode and campaign.get("stage",0)==3 else "res://scenes/journey.tscn")


func _open_box(first: String) -> void:
	if paused or over:
		return
	_clear_pointers()
	box.visible = true
	box.text = first
	box.grab_focus()
	box.caret_column = first.length()
	Engine.time_scale = slow_scale


func _close_box() -> void:
	box.visible = false
	box.release_focus()
	Engine.time_scale = 1.0


func _on_submit(text: String) -> void:
	_close_box()
	if over:
		return
	for command in parser.parse(text):
		var res: Dictionary = momo.interpret(command, companion_rng, game_time)
		if str(res.get("line", "")) != "":
			_say(str(res["line"]))
		if str(command.get("intent", "")) == "unknown":
			face.confused = 1.5
		var action := str(res.get("action", "none"))
		if action == "execute" or action == "delay":
			var wait := float(res.get("delay", 0.0)) if action == "delay" else 0.0
			# Mood speed: >1 means Omega-3 reacts faster (escapes when scared, everything when excited).
			wait += 0.08 / maxf(float(res.get("speed", 1.0)), 0.25)
			pending.append({"t": wait, "command": command})
			for extra in res.get("extra", []):
				pending.append({"t": wait + 0.3, "command": extra})


func _say(line: String,story: bool=false) -> void:
	if line == "": return
	radio_is_story=story
	var parts:=line.split(": ",true,1)
	var who: String=parts[0].to_lower() if parts.size()>1 else "omega"
	who={"omega-3":"omega","baykuş ömer":"omer","baykus omer":"omer","tavşan emre":"emre","tavsan emre":"emre"}.get(who,who)
	radio_speaker=who if Cast.NAMES.has(who) else "omega"
	radio_text=parts[1] if parts.size()>1 and Cast.NAMES.has(who) else line
	var full_line: String=str(Cast.NAMES.get(radio_speaker,"Omega-3"))+": "+radio_text
	if journey!=null and not line in journey.log_lines and not full_line in journey.log_lines: journey.log_lines.append(full_line)
	if is_instance_valid(radio_portrait):
		radio_portrait.speaker=radio_speaker
		radio_portrait.visible=radio_speaker in Cast.IDS
		face.visible=not radio_portrait.visible
	radio_page=0
	_reflow_radio()
	if face: face.talking=1.2

func _reflow_radio() -> void:
	radio_pages=TextFit.pages(radio_text,bubble)
	radio_page=mini(radio_page,radio_pages.size()-1)
	_show_radio_page()

func _show_radio_page() -> void:
	bubble.text=radio_pages[radio_page] if not radio_pages.is_empty() else ""
	momo_title.text=str(Cast.NAMES.get(radio_speaker,"Omega-3"))+"\n"+("Yol arkadaşın" if radio_speaker=="omega" else "Telsiz bağlantısı")
	radio_page_caption.text="%d / %d · Tam metin günlükte" % [radio_page+1,radio_pages.size()] if radio_pages.size()>1 else ""
	bubble_left=maxf(3.5,bubble.text.length()*0.055)

func _advance_radio(delta: float) -> void:
	bubble_left-=delta
	if bubble_left>0: return
	if radio_page+1<radio_pages.size():
		radio_page+=1
		_show_radio_page()
	else:
		bubble.text=""
		radio_page_caption.text=""
		radio_is_story=false
		radio_text=""
		radio_pages.clear()
		radio_page=0


func _event(ev: Variant) -> void:
	var res: Dictionary = momo.apply_event(ev, companion_rng)
	if str(res.get("line", "")) != "" and not (radio_is_story and bubble_left>0):
		_say(str(res["line"]))


func _play(name: String) -> void:
	if anim == "destroyed":
		return
	if anim == "hit" and name not in ["hit", "destroyed"]:
		return
	if anim.begins_with("shift_") and name == "fire":
		return
	anim = name
	anim_t = 0.0


# ---------------------------------------------------------------------------
# Executing commands
# ---------------------------------------------------------------------------

func _change_lane(to: int) -> void:
	to = clampi(to, 0, lane_count - 1)
	if to == lane:
		return
	prev_lane = lane
	lane_changed_at = game_time
	_play("shift_left" if to < lane else "shift_right")
	lane = to
	lane_target = _lane_x(to)


func _execute(command: Dictionary) -> void:
	var step := _cfg("player.speed_step", 40)
	match str(command.get("intent", "")):
		"lane_left":
			_change_lane(lane - 1)
		"lane_right":
			_change_lane(lane + 1)
		"dodge":
			if dodge_cooldown <= 0.0:
				var to := lane - 1 if lane > 0 else lane + 1
				if lane > 0 and lane < lane_count - 1 and _lane_threat(lane - 1) > _lane_threat(lane + 1):
					to = lane + 1
				_change_lane(to)
				dodge_left = _cfg("player.dodge_seconds", 0.45)
				dodge_cooldown = _cfg("player.dodge_cooldown", 1.5)
		"speed_up":
			target_speed = minf(target_speed + step, _cfg("player.max_speed", 340))
			_play("boost")
		"slow_down":
			target_speed = maxf(target_speed - step, _cfg("player.min_speed", 140))
			_play("brake")
		"ram":
			var target := _find_target(command.get("target", {}))
			if not target.is_empty():
				_change_lane(int(target["lane"]))
			target_speed = minf(target_speed + step, _cfg("player.max_speed", 340))
			ram_left = 1.2
			_play("boost")
		"fire":
			_fire(command.get("target", {}))
		"drop_mine":
			if mine_cooldown <= 0.0:
				mine_cooldown = _mine_reload()
				mine_drops += 1
				sounds.cue("mine")
				mines.append({"pos": Vector2(car_x, car_y + 30), "arm": _cfg("mine.arm_seconds", 0.12), "life": _cfg("mine.lifetime", 8.0)})

func _mine_reload() -> float:
	# Existing saved upgrades and route support now improve reload instead of ammo.
	return maxf(0.3,_cfg("mine.cooldown",0.7)-0.05*maxi(0,mines_left-3))


## Score for how dangerous a lane is right now (for dodge).
func _lane_threat(index: int) -> float:
	var t := 0.0
	for e in enemies:
		if int(e["lane"]) == index:
			t += 1.0
	for o in obstacles:
		if _lane_of(o["pos"].x) == index and o["pos"].y < car_y:
			t += 1.0
	return t


func _find_target(target: Variant) -> Dictionary:
	var want: Dictionary = target if target is Dictionary else {}
	var kind := str(want.get("type", ""))
	var position := str(want.get("position", ""))
	var side := str(want.get("side", ""))
	var best: Dictionary = {}
	var best_score := INF
	for e in enemies:
		if kind != "" and str(e["type"]) != kind:
			continue
		var p: Vector2 = e["pos"]
		if position in ["front", "ahead", "öndeki", "ondeki"] and p.y > car_y:
			continue
		if position in ["behind", "back", "arkadaki"] and p.y < car_y:
			continue
		if side == "left" and p.x >= car_x - 4:
			continue
		if side == "right" and p.x <= car_x + 4:
			continue
		var score := p.distance_to(Vector2(car_x, car_y))
		if score < best_score:
			best_score = score
			best = e
	return best


func _fire(target: Variant) -> void:
	if fire_cooldown > 0.0:
		return
	fire_cooldown = _cfg("weapon.cooldown", 0.45)
	sounds.cue("fire")
	var origin := Vector2(car_x, car_y - 30)
	var dir := Vector2.UP
	var want: Dictionary = (target if target is Dictionary else {}).duplicate()
	want["position"]="front"
	var aim := _find_target(want)
	if not aim.is_empty() and aim["pos"].y<car_y-35 and absf(aim["pos"].x-car_x)<90:
		dir = (aim["pos"] - origin).normalized()
	elif not want.is_empty() and str(want.get("type", "")) != "":
		_say("Orada %s yok ki." % TYPE_NAMES.get(str(want["type"]), "öyle bir şey"))
	bullets.append({"pos": origin, "vel": dir * _cfg("weapon.bullet_speed", 420)})
	effects.append({"pos":origin,"offset":origin-Vector2(car_x,car_y),"t":0.0,"kind":"muzzle","still":true})
	_play("fire")


# ---------------------------------------------------------------------------
# Simulation
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	qa_clock+=delta
	if qa_clock>=0.2 and QA.active():
		qa_clock=0
		var targets := {}
		for action in touch_by_action: targets[action]=QA.rect(touch_by_action[action])
		QA.publish("run",{"view":[get_viewport_rect().size.x,get_viewport_rect().size.y],"chapter":campaign.get("stage",-1),"hp":hp,"kills":kills,"collected":arcade.collected,"finish":_cfg("arcade.finish_distance",1200),"warnings":_enemy_warnings().map(func(w): return {"kind":w["kind"],"lane":w["lane"],"progress":w["progress"],"origin":[w["origin"].x,w["origin"].y],"target":[w["target"].x,w["target"].y]}),"traffic":enemies.map(func(e): return {"type":e["type"],"x":e["pos"].x,"y":e["pos"].y,"lane":e["lane"]}),"hazards":obstacles.map(func(o): return {"x":o["pos"].x,"y":o["pos"].y}),"shield":shield_left,"bonds":campaign.get("bonds",{}),"pickup_targets":pickups.map(func(p): return {"lane":_lane_of(p["pos"].x),"y":p["pos"].y}),"radio_ui":_radio_snapshot(),"result_focus":result_buttons.find(get_viewport().gui_get_focus_owner()),"support":comfort_cooldown,"pulse_count":comfort_count,"mine_held":_held("drive_mine"),"result":result_buttons.map(func(b): return QA.rect(b)),"ending_text":end_panel.text if over else "","lane":lane,"player":[car_x,car_y],"sprite":[car.position.x,car.position.y],"hitbox":[_player_rect().position.x,_player_rect().position.y,_player_rect().size.x,_player_rect().size.y],"joystick":QA.rect(joystick),"stick":[joystick.value.x,joystick.value.y],"paused":paused,"over":over,"fire":_held("drive_fire"),"boost":boosting,"distance":distance,"speed":speed,"energy":energy,"road":[road_touch_rect.position.x,road_touch_rect.position.y,road_touch_rect.size.x,road_touch_rect.size.y],"actions":targets,"pause":QA.rect(pause_button),"journal":journal_panel.visible,"touch":touch_enabled,"portrait_hud":({"health":QA.rect(hud),"meters":QA.rect(distance_caption),"hp_bar":QA.rect(hp_bar),"energy_bar":QA.rect(energy_bar),"energy":QA.rect(energy_caption)} if was_portrait else {}),"route":journey.route,"mines":-1,"mine_cooldown":mine_cooldown,"mine_reload":_mine_reload(),"mine_drops":mine_drops,"active_mines":mines.map(func(m): return [m["pos"].x,m["pos"].y]),"dodge":dodge_cooldown,"settings":settings_panel.visible,"settings_ui":QA.settings(settings_panel),"settings_rect":QA.rect(settings_panel),"settings_back":QA.rect(settings_panel.back),"pause_menu":pause_panel.get_child(0).get_children().filter(func(child): return child is Button).map(func(child): return QA.rect(child)),"journal_rect":QA.rect(journal_panel),"journal_back":QA.rect(journal_panel.get_child(0).get_child(2))})
	metrics_clock += delta
	if OS.has_feature("web") and metrics_clock > 5.0:
		metrics_clock = 0.0
		# Local QA snapshot only. No network, analytics, player data or telemetry.
		JavaScriptBridge.eval("document.documentElement.dataset.gameFps='%d';document.documentElement.dataset.godotMemoryBytes='%d';" % [Engine.get_frames_per_second(), OS.get_static_memory_usage()])
	if not paused:
		_animate(delta)
		_advance_radio(delta / maxf(Engine.time_scale, 0.01))
		toast_left -= delta
	toast.visible = toast_left > 0.0 and not paused and not over
	hud_clock += delta
	if hud_clock >= 0.1:
		hud_clock = 0.0
		_update_hud()
	queue_redraw()


func _update_hud() -> void:
	pause_button.visible=not over
	score_label.text = "%06d" % arcade.score
	hud.text = "CAN %d / %d\n%d m / %d m\nHız %d · Mayın sınırsız" % [maxi(0, ceili(hp)), int(max_hp), int(distance), int(_cfg("arcade.finish_distance", 1200)), int(speed)]
	hp_bar.value = hp / max_hp * 100.0
	energy_bar.value = energy / _cfg("arcade.boost_capacity", 100) * 100.0
	energy_caption.text = "TURBO · ENERJİ %d%%" % int(energy_bar.value)
	route_bar.value = distance / _cfg("arcade.finish_distance", 1200) * 100.0
	var progress: Vector2 = arcade.contract_progress(distance, kills)
	mission.text = "GÖREV %02d\n%s\n%d / %d\nSeri %d · En iyi %d" % [arcade.contract + 1, arcade.contract_title(), mini(int(progress.x), int(progress.y)), int(progress.y), arcade.chain, arcade.best_chain]
	status_label.text = "Güven %d · %s\n%s" % [int(momo.trust), Momo.mood_name_tr(momo.mood), ("KALKAN %.1f sn" % shield_left) if shield_left > 0 else (("Destek %.0f sn" % comfort_cooldown) if comfort_cooldown > 0 else "%s · Destek hazır" % Controls.binding_name("drive_comfort",Controls.last_device=="pad"))]
	if touch_by_action.has("drive_mine"):
		touch_by_action["drive_mine"].visual.text=("MAYIN %.1f" % mine_cooldown) if mine_cooldown>0 else "MAYIN · ∞"
	face.mood = momo.mood
	face.queue_redraw()
	hint.text = Controls.run_hint()
	hint.visible = not box.visible and not over and not was_portrait and not touch_enabled
	story_caption.visible=not paused and not over
	story_caption.text = ("ETAP %d / 3" % (mini(3,int(campaign.get("stage",0))+1)) if Session.story_mode else "EVE GİDEN YOL") + "\n" + journey.goal_text(comfort_count,arcade.collected)
	if was_portrait:
		energy_caption.text="ENERJİ %d%%" % int(energy_bar.value)
		hud.text="CAN %d / %d" % [maxi(0,ceili(hp)),int(max_hp)]
		distance_caption.text="%d / %d m" % [int(distance),int(_cfg("arcade.finish_distance",1200))]



func _physics_process(delta: float) -> void:
	if paused or over:
		return
	if not box.visible and (_held("drive_fire") or bool(save["settings"]["auto_fire"])):
		_fire({})
	_simulate(delta)


func _move_player(delta: float) -> void:
	var axis := Vector2(Input.get_action_strength("drive_right")-Input.get_action_strength("drive_left"),Input.get_action_strength("drive_down")-Input.get_action_strength("drive_up"))
	if is_instance_valid(joystick) and joystick.enabled and joystick.value.length()>0.0:
		axis=joystick.value
	axis=axis.limit_length(1.0) if not box.visible else Vector2.ZERO
	if axis.length()>0.01:
		lane_target=NAN
		last_drive=axis.normalized()
	var desired := axis*155.0
	drive_velocity=drive_velocity.move_toward(desired,2400.0*delta)
	if not is_nan(lane_target) and axis.length()<0.01:
		car_x=move_toward(car_x,lane_target,256.0*delta)
		drive_velocity.x=0.0
		if is_equal_approx(car_x,lane_target): lane_target=NAN
	var proposed := Vector2(car_x,car_y)+drive_velocity*delta
	var bounded := proposed.clamp(Vector2(235,86),Vector2(405,318))
	if bounded.x!=proposed.x: drive_velocity.x=0.0
	if bounded.y!=proposed.y: drive_velocity.y=0.0
	car_x=bounded.x
	car_y=bounded.y
	var nearest := _lane_of(car_x)
	if nearest!=lane:
		prev_lane=lane
		lane_changed_at=game_time
		lane=nearest


func _simulate(delta: float) -> void:
	if paused or over:
		return
	arcade.tick(delta)
	shield_left = maxf(0.0, shield_left - delta)
	comfort_cooldown = maxf(0.0, comfort_cooldown - delta)
	var normal_speed := _cfg("player.base_speed", 220)
	boosting = not box.visible and _held("drive_boost") and energy > 0.0 and not _held("drive_brake")
	if not box.visible and _held("drive_brake"):
		target_speed = _cfg("player.min_speed", 140)
	elif boosting:
		target_speed = _cfg("player.max_speed", 340) + _cfg("arcade.boost_speed", 95)
		energy = maxf(0.0, energy - _cfg("arcade.boost_drain", 24) * delta)
		if anim == "drive":
			_play("boost")
	else:
		target_speed = normal_speed
		if not _held("drive_boost"):
			energy = minf(_cfg("arcade.boost_capacity", 100), energy + _cfg("arcade.boost_regen", 12) * delta)
	game_time += delta
	fire_cooldown -= delta
	mine_cooldown = maxf(0.0,mine_cooldown-delta)
	if not box.visible and _held("drive_mine"):
		_execute({"intent":"drop_mine"})
	invulnerable -= delta
	dodge_left -= delta
	dodge_cooldown -= delta
	ram_left -= delta
	shake = maxf(0.0, shake - delta)
	for item in pending:
		item["t"] = float(item["t"]) - delta
	var due := pending.filter(func(i: Dictionary) -> bool: return float(i["t"]) <= 0.0)
	pending = pending.filter(func(i: Dictionary) -> bool: return float(i["t"]) > 0.0)
	for item in due:
		_execute(item["command"])

	_move_player(delta)
	speed = move_toward(speed, target_speed, _cfg("player.acceleration", 160) * delta)
	scroll = fposmod(scroll + speed * delta, 48.0)
	distance += speed * delta * float(run_cfg.get("distance_per_pixel", 0.05))
	for line in journey.advance(distance):
		_say(line,true)
		bubble_left=7.0
	car.position = Vector2(round(car_x),round(car_y))

	_spawn(delta)
	_update_bullets(delta)
	_update_mines(delta)
	_update_obstacles(delta)
	_update_enemies(delta)
	if over:
		return
	_update_pickups(delta)
	if arcade.complete_contract(distance, kills):
		hp = minf(max_hp, hp + _cfg("arcade.contract_heal", 10))
		mine_cooldown = 0.0
		_notice("GÖREV TAMAM! +%d puan\n+onarım · mayın hazır" % int(_cfg("arcade.contract_reward", 200)))
	if distance >= _cfg("arcade.finish_distance", 1200):
		_end_run("survived")
	for fx in effects:
		fx["t"] = float(fx["t"]) + delta
		if not fx.get("still", false):
			var k := str(fx["kind"])
			var mul := 0.6 if k.begins_with("wreck_") else (3.0 if k == "speed" else 1.0)
			fx["pos"] = fx["pos"] + Vector2(0, speed * delta * mul)
	if motion_enabled and speed > _cfg("player.base_speed", 220) + 20.0 and visual_rng.randf() < delta * 18.0:
		var sx := visual_rng.randf_range(200, 230) if visual_rng.randf() < 0.5 else visual_rng.randf_range(410, 440)
		effects.append({"pos": Vector2(sx, visual_rng.randf_range(-40, 200)), "t": 0.0, "kind": "speed"})
	effects = effects.filter(func(f: Dictionary) -> bool: return float(f["t"]) < 1.0)
	_scroll_scenery(delta)


func _spawn(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer > 0.0 or enemies.size() >= int(_cfg("spawn.max_alive", 5)):
		return
	var interval := maxf(_cfg("spawn.interval_min", 1.1), _cfg("spawn.interval_start", 3.0) - _cfg("spawn.interval_decay_per_minute", 0.6) * game_time / 60.0)
	spawn_timer = interval * rng.randf_range(0.8, 1.2)
	var weights: Dictionary = DataLoader.dig(run_cfg, "spawn.weights", {"rammer": 1.0})
	var unlocks: Dictionary = DataLoader.dig(run_cfg, "spawn.distance_unlocks", {})
	var pool := {}
	var total := 0.0
	for kind in weights:
		if distance >= float(unlocks.get(kind, 0.0)):
			pool[kind] = float(weights[kind])
			total += float(weights[kind])
	var roll := rng.randf() * total
	var kind := "rammer"
	for k in pool:
		roll -= float(pool[k])
		if roll <= 0.0:
			kind = k
			break
	var y := H + 50.0
	if kind == "truck":
		y = -50.0
	_add_enemy(kind, rng.randi_range(0, lane_count - 1), y)


func _update_pickups(delta: float) -> void:
	pickup_timer -= delta
	if pickup_timer <= 0.0:
		pickup_timer = _cfg("arcade.pickup_interval", 5.5) * rng.randf_range(0.85, 1.15)
		# Prefer the least occupied lane; the player chooses whether to leave safety.
		var chosen := rng.randi_range(0, lane_count - 1)
		for index in range(lane_count):
			if _lane_threat(index) < _lane_threat(chosen):
				chosen = index
		var kinds := ["repair", "energy", "shield"]
		pickups.append({"pos": Vector2(_lane_x(chosen), -18), "kind": kinds[rng.randi_range(0, 2)]})
	for pickup in pickups:
		pickup["pos"] += Vector2(0, speed * delta * 0.65)
		if _rect(pickup["pos"], Vector2(12, 12)).intersects(_player_rect()):
			_collect_pickup(str(pickup["kind"]))
			pickup["dead"] = true
	pickups = pickups.filter(func(p: Dictionary) -> bool: return not p.has("dead") and p["pos"].y < H + 20)


func _collect_pickup(kind: String) -> void:
	sounds.cue("pickup")
	arcade.collected += 1
	arcade.award(int(_cfg("arcade.pickup_points", 15)))
	match kind:
		"repair":
			hp = minf(max_hp, hp + _cfg("arcade.repair_amount", 18))
			_notice("ONARIM +%d" % int(_cfg("arcade.repair_amount", 18)))
		"energy":
			energy = minf(_cfg("arcade.boost_capacity", 100), energy + _cfg("arcade.energy_amount", 30))
			mine_cooldown = 0.0
			_notice("İKMAL · +enerji · mayın hazır")
		"shield":
			shield_left = _cfg("arcade.shield_seconds", 7)
			_notice("KALKAN · Bir darbeye koruma")


## Test hook: puts an enemy of `kind` in `e_lane` at screen y.
func _spawn_enemy_for_test(kind: String, e_lane: int, y: float) -> void:
	_add_enemy(kind, e_lane, y)


func _add_enemy(kind: String, e_lane: int, y: float) -> void:
	var cfg: Dictionary = DataLoader.dig(run_cfg, "enemies." + kind, {})
	var e := {
		"type": kind, "pos": Vector2(_lane_x(e_lane), y), "lane": e_lane,
		"hp": float(cfg.get("hp", 40)), "max_hp": float(cfg.get("hp", 40)),
		"cd": float(cfg.get("fire_cooldown", cfg.get("obstacle_cooldown", 2.0))) * 0.6,
		"state": "drive", "t": 0.0, "near": false, "passed": false, "flash": 0.0,
		"slot": rng.randf_range(70.0, 130.0), "lane_cd": 0.0,
	}
	enemies.append(e)


func _player_rect() -> Rect2:
	return Rect2(Vector2(car_x, car_y) - PLAYER_HALF, PLAYER_HALF * 2)


func _rect(pos: Vector2, half: Vector2) -> Rect2:
	return Rect2(pos - half, half * 2)


func _update_bullets(delta: float) -> void:
	for b in bullets:
		b["pos"] = b["pos"] + b["vel"] * delta
		for e in enemies:
			if _rect(e["pos"], ENEMY_HALF[e["type"]]).has_point(b["pos"]):
				_hurt_enemy(e, _cfg("weapon.damage", 20))
				b["dead"] = true
				break
		if not b.has("dead"):
			for o in obstacles:
				if _rect(o["pos"], Vector2(8, 8)).has_point(b["pos"]):
					o["hp"] = float(o["hp"]) - _cfg("weapon.damage", 20)
					b["dead"] = true
					break
	bullets = bullets.filter(func(b: Dictionary) -> bool: return not b.has("dead") and COMBAT_BOUNDS.has_point(b["pos"]))
	var pr := _player_rect()
	for b in enemy_bullets:
		b["pos"] = b["pos"] + b["vel"] * delta
		if pr.has_point(b["pos"]):
			b["dead"] = true
			_damage_player(float(b["dmg"]))
		else:
			_check_near(b, Rect2(b["pos"] - Vector2(2, 2), Vector2(4, 4)), lane)
	enemy_bullets = enemy_bullets.filter(func(b: Dictionary) -> bool: return not b.has("dead") and COMBAT_BOUNDS.has_point(b["pos"]))


func _update_mines(delta: float) -> void:
	for m in mines:
		m["pos"] = m["pos"] + Vector2(0, speed * delta)
		m["arm"] = float(m["arm"]) - delta
		m["life"] = float(m["life"]) - delta
		if float(m["arm"]) > 0.0:
			continue
		var detonate := false
		for e in enemies:
			if _rect(e["pos"], ENEMY_HALF[e["type"]] + Vector2(10, 10)).has_point(m["pos"]):
				detonate = true
				break
		# Rear fire is counterable even before its shooter reaches the mine.
		for bullet in enemy_bullets:
			if bullet["pos"].distance_to(m["pos"]) <= 24:
				detonate = true
				break
		if detonate:
			for e in enemies:
				if e["pos"].distance_to(m["pos"]) <= 60:
					_hurt_enemy(e, _cfg("mine.damage", 60))
			enemy_bullets=enemy_bullets.filter(func(b): return b["pos"].distance_to(m["pos"])>60)
			effects.append({"pos": m["pos"], "t": 0.0, "kind": "small"})
			m["life"] = -1.0
	mines = mines.filter(func(m: Dictionary) -> bool: return float(m["life"]) > 0.0 and COMBAT_BOUNDS.has_point(m["pos"]))


func _update_obstacles(delta: float) -> void:
	var pr := _player_rect()
	for o in obstacles:
		o["pos"] = o["pos"] + Vector2(0, speed * delta)
		var r := _rect(o["pos"], Vector2(8, 8))
		if float(o["hp"]) <= 0.0:
			effects.append({"pos": o["pos"], "t": 0.0, "kind": str(o["kind"]) + "_break"})
			o["dead"] = true
		elif r.intersects(pr):
			o["dead"] = true
			effects.append({"pos": o["pos"], "t": 0.0, "kind": str(o["kind"]) + "_break"})
			_damage_player(float(o["dmg"]))
		else:
			_check_near(o, r, _lane_of(o["pos"].x))
	obstacles = obstacles.filter(func(o: Dictionary) -> bool: return not o.has("dead") and o["pos"].y < H + 20)


func _update_enemies(delta: float) -> void:
	var pr := _player_rect()
	for e in enemies:
		var kind := str(e["type"])
		var cfg: Dictionary = DataLoader.dig(run_cfg, "enemies." + kind, {})
		var e_speed := float(cfg.get("speed", 200))
		e["t"] = float(e["t"]) + delta
		e["flash"] = maxf(0.0, float(e["flash"]) - delta)
		e["cd"] = float(e["cd"]) - delta
		e["lane_cd"] = float(e["lane_cd"]) - delta
		var vy := speed - e_speed  # positive = moves down the screen
		match kind:
			"rammer":
				var dist := absf(e["pos"].y - car_y)
				if dist < float(cfg.get("aggro_distance", 180)) and float(e["lane_cd"]) <= 0.0 and int(e["lane"]) != lane:
					e["lane"] = lane
					e["lane_cd"] = float(cfg.get("lane_change_seconds", 0.6)) * 2.0
					e["state"] = "attack"
			"pickup":
				# Overtakes from behind, then holds a slot ahead and shoots back.
				if e["pos"].y > float(e["slot"]) + 4.0:
					vy = minf(vy, -60.0)
				else:
					vy = 0.0
					if str(e["state"]) == "windup":
						if float(e["t"]) >= _warning_seconds(kind):
							var origin: Vector2 = e["pos"] + Vector2(0, 20)
							var dir: Vector2 = (e["aim"] - origin).normalized()
							enemy_bullets.append({"pos":origin,"vel":dir * float(cfg.get("bullet_speed",300)),"dmg":float(cfg.get("bullet_damage",8)),"near":false,"passed":false})
							e["state"] = "attack"
							e["t"] = 0.0
					elif float(e["cd"]) <= 0.0:
						e["cd"] = float(cfg.get("fire_cooldown", 1.6))
						e["state"] = "windup"
						e["aim"] = Vector2(car_x, car_y)
						e["t"] = 0.0
					if float(e["lane_cd"]) <= 0.0 and rng.randf() < 0.01:
						e["lane"] = clampi(int(e["lane"]) + (1 if rng.randf() < 0.5 else -1), 0, lane_count - 1)
						e["lane_cd"] = 2.0
			"truck":
				vy = minf(vy, 70.0) if e["pos"].y < 120 else vy
				if str(e["state"]) == "windup":
					if e["pos"].y >= car_y - 80:
						# A passed truck cannot drop an untelegraphed obstacle onto the car.
						e["state"] = "drive"
					elif float(e["t"]) >= _warning_seconds(kind):
						obstacles.append({"pos":e["pos"]+Vector2(0,52),"kind":e["drop_kind"],"hp":20.0,"dmg":float(cfg.get("obstacle_damage",20)),"near":false,"passed":false})
						e["state"] = "attack"
						e["t"] = 0.0
				elif float(e["cd"]) <= 0.0 and e["pos"].y > 0.0 and e["pos"].y < car_y - 80:
					e["cd"] = float(cfg.get("obstacle_cooldown", 3.0))
					e["state"] = "windup"
					e["t"] = 0.0
					e["drop_kind"] = ["crate","barrel","spikes"][rng.randi()%3]
		if str(e["state"]) == "attack" and float(e["t"]) > 0.5 and kind != "rammer":
			e["state"] = "drive"
		e["pos"] = Vector2(move_toward(e["pos"].x, _lane_x(int(e["lane"])), lane_width / maxf(float(cfg.get("lane_change_seconds", 0.6)), 0.05) * delta), e["pos"].y + vy * delta)
		var r := _rect(e["pos"], ENEMY_HALF[kind])
		if r.intersects(pr):
			_collide(e, cfg)
		else:
			_check_near(e, r, int(e["lane"]))
	enemies = enemies.filter(func(e: Dictionary) -> bool: return not e.has("dead") and e["pos"].y > -120 and e["pos"].y < H + 120)


func _collide(e: Dictionary, cfg: Dictionary) -> void:
	if ram_left > 0.0:
		ram_left = 0.0
		_hurt_enemy(e, _cfg("player.ram_damage", 40))
		_damage_player(_cfg("player.ram_self_damage", 10), false)
		e["pos"] = e["pos"] + Vector2(0, -24 if e["pos"].y < car_y else 24)
		return
	_damage_player(float(cfg.get("contact_damage", 15)))
	if str(e["type"]) == "rammer":
		e["hp"] = 0.0
		_explode(e, false)
	else:
		e["pos"] = e["pos"] + Vector2(0, -30 if e["pos"].y < car_y else 30)


## Near miss / successful manoeuvre: something passed the car without touching it.
func _check_near(thing: Dictionary, r: Rect2, thing_lane: int) -> void:
	if thing.get("passed", false):
		return
	var pr := _player_rect()
	var center_y := r.get_center().y
	if center_y < car_y:
		return
	thing["passed"] = true
	if r.position.y > pr.end.y + 40:
		return  # it came from behind and never really overlapped
	var gap := maxf(r.position.x - pr.end.x, pr.position.x - r.end.x)
	if game_time - lane_changed_at < 1.2 and thing_lane == prev_lane:
		arcade.near_misses += 1
		arcade.award(int(_cfg("arcade.near_points", 25)))
		_event("manoeuvre_success")
	elif gap >= 0.0 and gap < float(run_cfg.get("near_miss_distance", 18)):
		arcade.near_misses += 1
		arcade.award(int(_cfg("arcade.near_points", 25)))
		_event("near_miss")
		var side := -1.0 if r.get_center().x < car_x else 1.0
		effects.append({"pos": Vector2(car_x + side * 16.0, car_y), "t": 0.0, "kind": "near_miss", "still": true})


func _hurt_enemy(e: Dictionary, amount: float) -> void:
	e["hp"] = float(e["hp"]) - amount
	e["flash"] = 0.12
	if float(e["hp"]) <= 0.0 and not e.has("dead"):
		_explode(e, true)


func _explode(e: Dictionary, by_player: bool) -> void:
	e["dead"] = true
	effects.append({"pos": e["pos"], "t": 0.0, "kind": "wreck_" + str(e["type"])})
	_shake(float(DataLoader.dig(run_cfg, "screen_shake.kill", 2.0)))
	if by_player:
		sounds.cue("kill")
		arcade.award(int(_cfg("arcade.kill_points", 40)))
		kills += 1
		_event("kill")


func _damage_player(amount: float, tell := true) -> void:
	if invulnerable > 0.0 or dodge_left > 0.0 or over:
		return
	if shield_left > 0.0:
		shield_left = 0.0
		invulnerable = _cfg("player.invulnerable_after_hit", 0.6)
		_notice("Kalkan darbeyi emdi!")
		return
	arcade.break_chain()
	if bool(save["settings"]["vibration"]):
		if touch_enabled: Input.vibrate_handheld(35)
		for device in Input.get_connected_joypads():
			Input.start_joy_vibration(device, 0.25, 0.4, 0.15)
	sounds.cue("hit")
	hp -= amount
	invulnerable = _cfg("player.invulnerable_after_hit", 0.6)
	_shake(float(DataLoader.dig(run_cfg, "screen_shake.hit", 3.0)))
	_play("hit")
	face.hurt = 0.35
	if tell:
		_event({"type": "damage", "amount": amount})
	if hp <= 0.0:
		_end_run()


func _shake(power: float) -> void:
	if not effects_enabled:
		return
	shake = float(DataLoader.dig(run_cfg, "screen_shake.seconds", 0.2))
	shake_power = power


func _to_garage() -> void:
	Engine.time_scale = 1.0
	Session.came_from_run = true
	get_tree().call_deferred("change_scene_to_file", "res://scenes/garage.tscn")


func _end_run(outcome := "destroyed") -> void:
	if over:
		return
	over = true
	sounds.cue("finish" if outcome == "survived" else "hit")
	paused = false
	pause_panel.hide()
	_clear_pointers()
	_close_box()
	anim = "destroyed" if outcome == "destroyed" else "drive"
	anim_t = 0.0
	pending.clear()
	if outcome == "survived":
		arcade.score += int(_cfg("arcade.finish_reward", 500))
	end_result = momo.end_run(outcome, companion_rng)
	var garage := Garage.new(DataLoader.load_json(DataLoader.GARAGE_PATH), balance)
	save["trust"] = momo.trust
	var run_info := end_result.duplicate()
	run_info["distance"] = distance
	run_info["kills"] = kills
	save["memory"] = garage.record_run(save.get("memory", {}), run_info)
	save["memory"]["last_route"]=journey.route
	save["memory"]["last_route_goal"]=int(journey.goal_met(comfort_count,arcade.collected))
	if outcome=="survived":
		save["memory"]["chapter_clears"]=int(save["memory"]["chapter_clears"])+1
	save["best_score"] = maxi(int(save.get("best_score", 0)), arcade.score)
	if Session.story_mode:
		campaign=Book.complete(campaign,outcome=="survived",arcade.score,journey.goal_met(comfort_count,arcade.collected))
		save["campaign"]=campaign
		Session.campaign_state=campaign.duplicate(true)
	var saved: bool = store.save_data(save)
	if Session.story_mode: Session.campaign_save_failed=not saved
	var d := float(end_result.get("trust_delta", 0.0))
	var final_line: String=journey.ending(outcome=="survived",comfort_count,arcade.collected)
	journey.log_lines.append(final_line)
	end_panel.text = "%s\n%s\nOmega-3: %s\nPUAN %d · REKOR %d\nMesafe: %d m · %d düşman · Seri %d\n%s\nGüven: %d (%s%d)\n%s" % [
		("ÜÇ ETAP TAMAMLANDI" if campaign.get("stage",0)==3 else "ETAP TAMAMLANDI") if outcome=="survived" and Session.story_mode else ("EVE DÖNDÜK" if outcome=="survived" else "BU AYRIMDAN YENİDEN"),str(journey.spec()["name"]),final_line,
		arcade.score,int(save["best_score"]),int(distance),kills,arcade.best_chain,
		"Yol hedefi tamamlandı" if journey.goal_met(comfort_count,arcade.collected) else "Yol hedefi bir sonraki sefere kaldı",
		int(momo.trust),"+" if d>=0 else "",int(round(d)),"" if saved else "Kayıt yazılamadı."]
	for button in touch_controls:
		button.hide()
	var layer := end_panel.get_parent()
	var retry := _control_button(layer, Rect2(166, 300, 148, 44), ("Sonu oku" if campaign.get("stage",0)==3 else ("Sonraki seçim" if outcome=="survived" else "Kararı gözden geçir")) if Session.story_mode else "Yeniden sür", _restart_run)
	retry.grab_focus()
	retry.z_index=40
	result_buttons.append(retry)
	result_buttons.append(_control_button(layer, Rect2(326, 300, 148, 44), "Garaj", _to_garage))
	result_buttons[-1].z_index=40
	for i in result_buttons.size():
		var button: Button=result_buttons[i]
		button.focus_mode=Control.FOCUS_ALL
		button.focus_neighbor_left=button.get_path_to(result_buttons[maxi(0,i-1)])
		button.focus_neighbor_right=button.get_path_to(result_buttons[mini(result_buttons.size()-1,i+1)])
		button.focus_neighbor_top=button.focus_neighbor_left
		button.focus_neighbor_bottom=button.focus_neighbor_right
		button.focus_previous=button.get_path_to(result_buttons[(i+result_buttons.size()-1)%result_buttons.size()])
		button.focus_next=button.get_path_to(result_buttons[(i+1)%result_buttons.size()])
	_layout()

	end_panel.visible = true


# ---------------------------------------------------------------------------
# Drawing (enemy sprites are drawn in code until their sheets land in assets/)
# ---------------------------------------------------------------------------

func _animate(delta: float) -> void:
	var name := anim
	if name == "drive" and hp <= max_hp * 0.25:
		name = "critical"
	elif name == "drive" and hp <= max_hp * 0.5:
		name = "damaged"
	var a: Array = ANIMS[name]
	anim_t += delta * float(a[2])
	var frame := int(anim_t)
	if frame >= int(a[1]):
		if bool(a[3]):
			frame %= int(a[1])
		elif anim == "destroyed":
			frame = int(a[1]) - 1
		else:
			anim = "drive"
			anim_t = 0.0
			frame = 0
			a = ANIMS["drive"]
	var index := frame%4
	if name=="drive":
		var blink_phase:=fposmod(game_time,3.8)
		index=(2 if blink_phase>3.62 else int(game_time*3)%2) if motion_enabled else 0
	if anim=="boost": index=4+frame%2
	elif anim=="fire": index=6
	elif name in ["hit","damaged","critical","destroyed"]: index=7
	car.region_rect=Rect2((index%4)*FW,(index/4)*FH,FW,FH)
	car.visible = not (invulnerable > 0.0 and int(game_time * 20) % 2 == 0 and not over)
	car.modulate = Color(0.7, 0.9, 1.0, 0.75) if dodge_left > 0.0 else Color.WHITE


func _scroll_scenery(delta: float) -> void:
	if not motion_enabled:
		return
	road_scroll = fposmod(road_scroll + speed * delta, 256.0)
	for d in decals:
		d["pos"] = d["pos"] + Vector2(0, speed * delta)
	for pr in props:
		pr["pos"] = pr["pos"] + Vector2(0, speed * delta * float(pr["parallax"]))
	decals = decals.filter(func(d: Dictionary) -> bool: return d["pos"].y < H + 40)
	props = props.filter(func(pr: Dictionary) -> bool: return pr["pos"].y < H + 80)
	if visual_rng.randf() < delta * 0.6:
		decals.append({"pos": Vector2(_lane_x(visual_rng.randi_range(0, lane_count - 1)) + visual_rng.randf_range(-14, 14), -30), "frame": visual_rng.randi_range(0, 5)})
	if visual_rng.randf() < delta * 0.5:
		var names := ["billboard_obey", "billboard_buy", "neon_fuel", "neon_open", "pylon", "wreck", "toxic_puddle", "barrels"]
		var anim: String = names[visual_rng.randi() % names.size()]
		var left := visual_rng.randf() < 0.5
		var par: Variant = DataLoader.dig(sheets.sheet("roadside_props"), "parallax." + anim, null)
		if par == null:
			par = 1.15 if anim.begins_with("billboard") or anim.begins_with("neon") else 1.0
		props.append({"pos": Vector2(visual_rng.randf_range(40, 170) if left else visual_rng.randf_range(470, 600), -70), "anim": anim, "parallax": float(par)})


func _camera_offset() -> Vector2:
	# Sample simulation time, not a random stream or render-frame count.
	if shake <= 0.0 or not effects_enabled or not motion_enabled or paused or over:
		return Vector2.ZERO
	return (Vector2(sin(game_time*83.13+2.7),sin(game_time*107.71+0.9))*shake_power).round()


func _warning_seconds(kind: String) -> float:
	return maxf(0.1,_cfg("enemies."+kind+".warning_seconds",0.55))


func _enemy_warnings() -> Array[Dictionary]:
	var warnings: Array[Dictionary] = []
	if over: return warnings
	var rear_lanes := {}
	for enemy in enemies:
		if enemy.has("dead"): continue
		var p: Vector2 = enemy["pos"]
		var enemy_lane: int = int(enemy["lane"])
		if p.y > H:
			if not rear_lanes.has(enemy_lane):
				rear_lanes[enemy_lane]=true
				warnings.append({"kind":"rear","lane":enemy_lane,"progress":0.0,"origin":p,"target":Vector2(_lane_x(enemy_lane),H-13)})
		elif str(enemy["state"]) == "windup":
			var shot: bool = str(enemy["type"]) == "pickup"
			var target: Vector2 = enemy["aim"] if shot else p+Vector2(0,52)
			warnings.append({"kind":"shot" if shot else "drop","lane":_lane_of(target.x),"progress":clampf(float(enemy["t"])/_warning_seconds(str(enemy["type"])),0,1),"origin":p+Vector2(0,20),"target":target})
		elif str(enemy["type"]) == "rammer" and absf(p.x-_lane_x(enemy_lane)) > 2:
			warnings.append({"kind":"ram","lane":enemy_lane,"progress":clampf(1.0-absf(p.x-_lane_x(enemy_lane))/lane_width,0,1),"origin":p,"target":Vector2(_lane_x(enemy_lane),p.y)})
	return warnings


func _draw() -> void:
	position = world_origin + _camera_offset()
	var road := sheets.texture("assets/road/road_tile.png")
	if road == null:
		_draw_fallback_road()
	else:
		var left_tex := sheets.texture("assets/road/roadside_left.png")
		var right_tex := sheets.texture("assets/road/roadside_right.png")
		var y := road_scroll - 256.0
		while y < H + 8:
			draw_texture(left_tex, Vector2(0, y))
			draw_texture(road, Vector2(192, y))
			draw_texture(right_tex, Vector2(448, y))
			y += 256.0
	for d in decals:
		sheets.draw_frame(self, "road_decals", int(d["frame"]), d["pos"])
	for pr in props:
		sheets.draw_anim(self, "roadside_props", str(pr["anim"]), game_time, pr["pos"])
	for pickup in pickups:
		_draw_pickup(pickup)
	if shield_left > 0.0 and not over:
		draw_arc(Vector2(car_x, car_y), 32, 0, TAU, 32, Color("79d4ff"), 2)
	if boosting and not over:
		for side in [-1, 1]:
			draw_line(Vector2(car_x + side * 7, car_y + 28), Vector2(car_x + side * 7, car_y + 38 + sin(game_time * 40) * 5), Color("79d4ff"), 3)
	for m in mines:
		var armed := float(m["arm"]) <= 0.0
		sheets.draw_anim(self, "mine", "armed" if armed else "arming", game_time, m["pos"])
	for o in obstacles:
		sheets.draw_anim(self, "obstacles", str(o["kind"]) + "_idle", game_time, o["pos"])
	for e in enemies:
		_draw_enemy_sprite(e)
	for b in bullets:
		sheets.draw_anim(self, "projectiles", "player_bullet", game_time, b["pos"])
	for b in enemy_bullets:
		sheets.draw_anim(self, "projectiles", "enemy_bullet", game_time, b["pos"])
	for fx in effects:
		_draw_effect_sprite(fx)


const ENEMY_SHEETS := {"rammer": "enemy_rammer", "pickup": "enemy_pickup", "truck": "enemy_truck"}


func _draw_pickup(pickup: Dictionary) -> void:
	var p: Vector2 = pickup["pos"]
	var kind := str(pickup["kind"])
	var color: Color = {"repair": Color("7cddb5"), "energy": Color("ffce70"), "shield": Color("79d4ff")}[kind]
	draw_rect(Rect2(p - Vector2(11, 11), Vector2(22, 22)), Color("101622"))
	draw_rect(Rect2(p - Vector2(11, 11), Vector2(22, 22)), color, false, 1)
	match kind:
		"repair":
			draw_rect(Rect2(p - Vector2(2, 7), Vector2(4, 14)), color)
			draw_rect(Rect2(p - Vector2(7, 2), Vector2(14, 4)), color)
		"energy":
			draw_colored_polygon(PackedVector2Array([p + Vector2(1, -8), p + Vector2(-5, 1), p + Vector2(0, 1), p + Vector2(-1, 8), p + Vector2(6, -2), p + Vector2(1, -2)]), color)
		"shield":
			draw_polyline(PackedVector2Array([p + Vector2(-6, -6), p + Vector2(6, -6), p + Vector2(5, 3), p + Vector2(0, 8), p + Vector2(-5, 3), p + Vector2(-6, -6)]), color, 2)


func _draw_enemy_sprite(e: Dictionary) -> void:
	var name: String = ENEMY_SHEETS[str(e["type"])]
	if sheets.sheet(name).is_empty():
		_draw_enemy(e)
		return
	var anim := "drive"
	var t := game_time
	if float(e["flash"]) > 0.0:
		anim = "hit"
		t = 0.12 - float(e["flash"])
	elif str(e["state"]) == "attack":
		anim = "attack"
		t = float(e["t"])
		if str(e["type"]) == "rammer":
			var dx := _lane_x(int(e["lane"])) - float(e["pos"].x)
			anim = "ram_left" if dx < -2.0 else ("ram_right" if dx > 2.0 else "attack")
			t = game_time
	var p: Vector2 = e["pos"]
	if str(e["type"]) == "pickup":
		sheets.draw_anim(self, name, "drive_noturret" if anim == "drive" or anim == "attack" else anim, t, p)
		var mount: Array = sheets.sheet(name).get("turret_mount", [24, 52])
		var anchor: Array = sheets.sheet(name).get("anchor", [24, 40])
		var tp := p + Vector2(float(mount[0]) - float(anchor[0]), float(mount[1]) - float(anchor[1]))
		var aim: Vector2 = e.get("aim",Vector2(car_x,car_y)) if str(e["state"]) in ["windup","attack"] else Vector2(car_x,car_y)
		var dir := aim - tp
		var idx := posmod(roundi((atan2(dir.y, dir.x) - PI / 2.0) / deg_to_rad(22.5)), 16)
		var firing := str(e["state"]) == "attack" and float(e["t"]) < 0.15
		sheets.draw_frame(self, "enemy_pickup_turret", idx + (16 if firing else 0), tp)
	else:
		sheets.draw_anim(self, name, anim, t, p)
	var frac := float(e["hp"]) / maxf(float(e["max_hp"]), 1.0)
	if frac < 1.0:
		var half: Vector2 = ENEMY_HALF[e["type"]]
		draw_rect(Rect2(p + Vector2(-half.x, -half.y - 8), Vector2(half.x * 2, 2)), Color("101018"))
		draw_rect(Rect2(p + Vector2(-half.x, -half.y - 8), Vector2(half.x * 2 * frac, 2)), Color("e05a5a"))


func _draw_effect_sprite(fx: Dictionary) -> void:
	var kind := str(fx["kind"])
	var t := float(fx["t"])
	var p: Vector2 = fx["pos"]
	if kind=="muzzle": p=Vector2(car_x,car_y)+fx.get("offset",Vector2(0,-30))
	elif kind=="pulse": p=Vector2(car_x,car_y)
	if kind=="pulse":
		if t>0.45: return
		var radius:=18.0+t*160.0 if motion_enabled else 36.0
		var tint:=Color("79d4ff")
		tint.a=clampf(1.0-t/0.45,0,1)
		for i in 8:
			var direction:=Vector2.from_angle(i*TAU/8)
			var tangent:=Vector2(-direction.y,direction.x)
			var points:=PackedVector2Array([p+direction*12,p+direction*(radius*0.45)+tangent*4,p+direction*(radius*0.7)-tangent*3,p+direction*radius])
			draw_polyline(points,tint,2,false)
	elif kind=="muzzle":
		if t>0.1: return
		draw_rect(Rect2(p-Vector2(3,7),Vector2(6,10)),Color("ffce70"))
		draw_line(p+Vector2(-7,-3),p+Vector2(7,-3),Color("fff2df"),2,false)
	elif kind.begins_with("wreck_"):
		var name: String = ENEMY_SHEETS.get(kind.substr(6), "")
		if name != "" and t < sheets.anim_length(name, "destroyed"):
			sheets.draw_frame(self, name, sheets.frame_at(name, "destroyed", t, 0), p + Vector2(0, speed * 0.0))
		if t < sheets.anim_length("explosion", "explode"):
			sheets.draw_frame(self, "explosion", sheets.frame_at("explosion", "explode", t, 0), p)
	elif kind == "near_miss":
		if t < sheets.anim_length("near_miss", "streak"):
			sheets.draw_frame(self, "near_miss", sheets.frame_at("near_miss", "streak", t, 0), p)
	elif kind == "speed":
		if t < sheets.anim_length("speed_lines", "line"):
			sheets.draw_frame(self, "speed_lines", sheets.frame_at("speed_lines", "line", t, 0), p)
	elif kind == "small":
		if t < sheets.anim_length("explosion_small", "explode"):
			sheets.draw_frame(self, "explosion_small", sheets.frame_at("explosion_small", "explode", t, 0), p)
	elif kind.ends_with("_break"):
		if t < sheets.anim_length("obstacles", kind):
			sheets.draw_frame(self, "obstacles", sheets.frame_at("obstacles", kind, t, 0), p)
		elif t < 0.6:
			sheets.draw_frame(self, "smoke_sparks", sheets.frame_at("smoke_sparks", "sparks", t - 0.3, 0), p)
	else:
		_draw_effect(fx)


func _draw_fallback_road() -> void:
	draw_rect(Rect2(-8, -8, W + 16, H + 16), Color("1b1d2b"))
	var road_w := lane_count * lane_width
	var left := W / 2 - road_w / 2
	draw_rect(Rect2(left, -8, road_w, H + 16), Color("3a3d4d"))
	var y := scroll - 48.0
	while y < H + 8:
		for i in range(1, lane_count):
			draw_rect(Rect2(left + i * lane_width - 1, y, 2, 24), Color("d8d8e0"))
		y += 48.0


func _box(c: Vector2, half: Vector2, fill: Color, outline := Color("101018")) -> void:
	draw_rect(Rect2((c - half - Vector2.ONE).round(), (half * 2 + Vector2(2, 2)).round()), outline)
	draw_rect(Rect2((c - half).round(), (half * 2).round()), fill)


func _draw_enemy(e: Dictionary) -> void:
	var p: Vector2 = (e["pos"] as Vector2).round()
	var flash := float(e["flash"]) > 0.0
	var wheel := Color("15151c")
	var bob := 1.0 if int(float(e["t"]) * 10.0) % 2 == 0 else 0.0
	match str(e["type"]):
		"rammer":
			var body := Color("c0392b") if not flash else Color.WHITE
			for wy in [-14.0, 12.0]:
				_box(p + Vector2(-11, wy + bob * 0.0), Vector2(2, 5), wheel)
				_box(p + Vector2(11, wy), Vector2(2, 5), wheel)
			_box(p, Vector2(9, 20), body)
			_box(p + Vector2(0, -4), Vector2(6, 6), Color("2b1a24"))
			draw_rect(Rect2(p + Vector2(-5, -9), Vector2(10, 2)), Color("6a8caf"))
			_box(p + Vector2(0, -21), Vector2(10, 2), Color("9aa0aa"))  # spiked bumper
			for sx in [-8.0, -3.0, 2.0, 7.0]:
				draw_rect(Rect2(p + Vector2(sx, -25 - bob), Vector2(1, 2)), Color("d8dde6"))
			draw_rect(Rect2(p + Vector2(-6, 14), Vector2(12, 2)), Color("ff9a3a") if str(e["state"]) == "attack" else Color("7a2a2a"))
		"pickup":
			var body := Color("d4a017") if not flash else Color.WHITE
			for wy in [-15.0, 13.0]:
				_box(p + Vector2(-12, wy), Vector2(2, 5), wheel)
				_box(p + Vector2(12, wy), Vector2(2, 5), wheel)
			_box(p, Vector2(10, 22), body)
			_box(p + Vector2(0, -10), Vector2(8, 6), Color("2b2a1a"))
			draw_rect(Rect2(p + Vector2(-6, -16), Vector2(12, 2)), Color("6a8caf"))
			_box(p + Vector2(0, 9), Vector2(8, 10), Color("8a6a10"))  # bed
			var turret := p + Vector2(0, 9)
			_box(turret, Vector2(4, 4), Color("3a3d4d"))
			var dir: Vector2 = (Vector2(car_x, car_y) - turret).normalized()
			for i in range(3, 10):
				draw_rect(Rect2((turret + dir * i).round(), Vector2(2, 2)), Color("1a1a22"))
			if str(e["state"]) == "attack" and float(e["t"]) < 0.12:
				draw_rect(Rect2((turret + dir * 11 - Vector2(2, 2)).round(), Vector2(5, 5)), Color("ffe08a"))
		"truck":
			var body := Color("5b6b7a") if not flash else Color.WHITE
			for wy in [-32.0, -20.0, 22.0, 32.0]:
				_box(p + Vector2(-14, wy), Vector2(2, 4), wheel)
				_box(p + Vector2(14, wy), Vector2(2, 4), wheel)
			_box(p + Vector2(0, -28), Vector2(12, 11), Color("8e3b2e") if not flash else Color.WHITE)  # cab in front
			draw_rect(Rect2(p + Vector2(-8, -36), Vector2(16, 3)), Color("6a8caf"))
			_box(p + Vector2(0, 11), Vector2(13, 26), body)  # cargo box
			for sy in range(-12, 34, 6):
				draw_rect(Rect2(p + Vector2(-12, sy), Vector2(24, 1)), Color("4a5866"))
			var open := str(e["state"]) == "attack"
			draw_rect(Rect2(p + Vector2(-10, 36 if not open else 39), Vector2(20, 3)), Color("e0b84a"))
	var frac := float(e["hp"]) / maxf(float(e["max_hp"]), 1.0)
	if frac < 1.0:
		var half: Vector2 = ENEMY_HALF[e["type"]]
		draw_rect(Rect2(p + Vector2(-half.x, -half.y - 6), Vector2(half.x * 2, 2)), Color("101018"))
		draw_rect(Rect2(p + Vector2(-half.x, -half.y - 6), Vector2(half.x * 2 * frac, 2)), Color("e05a5a"))


func _draw_obstacle(o: Dictionary) -> void:
	var p: Vector2 = (o["pos"] as Vector2).round()
	match str(o["kind"]):
		"crate":
			_box(p, Vector2(7, 7), Color("8b5a2b"))
			draw_rect(Rect2(p + Vector2(-7, -1), Vector2(14, 2)), Color("5c3a1a"))
			draw_rect(Rect2(p + Vector2(-1, -7), Vector2(2, 14)), Color("5c3a1a"))
		"barrel":
			_box(p, Vector2(6, 7), Color("2e7d32"))
			draw_rect(Rect2(p + Vector2(-6, -3), Vector2(12, 1)), Color("1b4d1e"))
			draw_rect(Rect2(p + Vector2(-6, 2), Vector2(12, 1)), Color("1b4d1e"))
			draw_rect(Rect2(p + Vector2(-2, -2), Vector2(4, 3)), Color("c6ff3a"))
		_:
			_box(p, Vector2(9, 3), Color("3a3d4d"))
			for sx in range(-8, 9, 4):
				draw_rect(Rect2(p + Vector2(sx, -6), Vector2(1, 3)), Color("d8dde6"))


func _draw_effect(fx: Dictionary) -> void:
	var t := float(fx["t"])
	var p: Vector2 = (fx["pos"] as Vector2).round()
	if str(fx["kind"]) == "boom":
		var r := 4.0 + t * 30.0
		var cols := [Color("fff3b0"), Color("ffb347"), Color("e0552b"), Color("4a3a4a")]
		var c: Color = cols[mini(int(t / 0.2), 3)]
		draw_circle(p, r, c)
		draw_circle(p, r * 0.55, cols[mini(int(t / 0.2) + 1, 3)] if t > 0.1 else Color.WHITE)
	else:
		for i in range(6):
			var a := i * TAU / 6.0 + t * 3.0
			draw_rect(Rect2((p + Vector2(cos(a), sin(a)) * (t * 40.0)).round(), Vector2(2, 2)), Color("ffe08a"))


func _clear_pointers() -> void:
	touch_held.clear()
	if is_instance_valid(joystick): joystick.reset()
	mouse_fire=false
	mouse_mine=false
	for button in touch_controls:
		button.release_visual()


func _sync_touch() -> void:
	var show_controls := touch_enabled and not paused and not over and not box.visible
	for button in touch_controls:
		button.visible=show_controls
	if is_instance_valid(joystick):
		joystick.enabled=show_controls
		joystick.visible=show_controls
		if not show_controls: joystick.reset()
	if is_instance_valid(touch_hint): touch_hint.visible=show_controls


func _place(control: Control, rect: Rect2) -> void:
	control.position=rect.position
	control.size=rect.size


func _layout() -> void:
	if not is_instance_valid(end_panel): return
	var view: Vector2 = get_viewport().get_visible_rect().size
	var portrait: bool = view.y>view.x
	_clear_pointers()
	if layout_initialized and portrait!=was_portrait and not over:
		_set_paused(true)
	was_portrait=portrait
	layout_initialized=true
	var offset: Vector2 = (view-Vector2(640,360))/2 if not portrait else Vector2.ZERO
	for node in base_rects:
		if is_instance_valid(node): _place(node,Rect2(base_rects[node].position+offset,base_rects[node].size))
	momo_title.visible=not portrait
	status_label.visible=not portrait and not touch_enabled
	mission.visible=not portrait and not touch_enabled
	distance_caption.visible=portrait
	ui_panels[2].visible=not portrait and not touch_enabled
	face.scale=Vector2.ONE
	bubble.add_theme_font_size_override("font_size",11 if portrait else 12)
	score_label.add_theme_font_size_override("font_size",16 if portrait else 20)
	hud.add_theme_font_size_override("font_size",11 if portrait else 12)
	brand_label.text="FRAGARIA · AIONIA" if portrait else "FRAGARIA INTERACTIVE"
	brand_label.add_theme_font_size_override("font_size",8 if portrait else 9)
	var column := pause_panel.get_child(0)
	for child in column.get_children():
		if child is BaseButton: child.custom_minimum_size.y=44 if portrait else 36
	pause_panel.reset_size()
	if portrait:
		var width: float = view.x
		_place(ui_panels[0],Rect2(8,8,width-92,72))
		_place(brand_label,Rect2(16,10,width-110,12))
		_place(score_label,Rect2(16,27,94,24))
		_place(hud,Rect2(118,28,width-214,20))
		_place(distance_caption,Rect2(16,62,90,14))
		_place(hp_bar,Rect2(16,55,90,5))
		_place(energy_bar,Rect2(118,55,width-218,5))
		_place(energy_caption,Rect2(118,62,width-214,14))
		energy_caption.add_theme_font_size_override("font_size",9)
		_place(route_bar,Rect2(8,83,width-16,4))
		_place(pause_button,Rect2(width-76,12,64,60))
		pause_button.text="Mola"
		_place(ui_panels[1],Rect2(8,94,width-16,68))
		face.position=Vector2(16,104)
		radio_portrait.position=face.position
		_place(bubble,Rect2(76,102,width-94,40))
		_place(radio_page_caption,Rect2(76,146,width-94,12))
		_place(story_caption,Rect2(8,166,width-16,34))
		_place(toast,Rect2(30,206,width-60,60))
		var play_height := maxf(220,view.y-370)
		var zoom := minf(play_height/360.0,(width-24)/224.0)
		scale=Vector2.ONE*zoom
		world_origin=Vector2(width/2-320*zoom,196)
		road_touch_rect=Rect2(12,196,width-24,play_height)
		_place(touch_hint,Rect2(10,view.y-29,122,20))
		touch_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var gap := 8.0
		var button_width: float = floorf((width-148-gap)/2)
		var buttons_left: float=140
		joystick.fit(Rect2(10,view.y-150,120,120))
		var actions := ["drive_boost","drive_brake","drive_comfort","drive_dodge","drive_fire","drive_mine"]
		for i in actions.size():
			touch_by_action[actions[i]].fit(Rect2(buttons_left+(i%2)*(button_width+gap),view.y-162+(i/2)*50,button_width,44))
		_place(pause_panel,Rect2(20,40,width-40,minf(view.y-80,440)))
		_place(end_panel,Rect2(12,174,width-24,view.y-254))
		_place(box,Rect2(12,view.y-56,width-24,40))
	else:
		scale=Vector2.ONE
		world_origin=offset
		radio_portrait.position=face.position
		if touch_enabled:
			_place(ui_panels[1],Rect2(offset+Vector2(456,8),Vector2(176,136)))
			_place(pause_button,Rect2(offset+Vector2(456,152),Vector2(176,44)))
		road_touch_rect=Rect2(offset+Vector2(192,12),Vector2(256,336))
		pause_button.text="Mola · Start" if Controls.last_device=="pad" else "Mola · Esc"
		energy_caption.add_theme_font_size_override("font_size",9)
		joystick.fit(Rect2(offset+Vector2(18,206),Vector2(144,144)))
		_place(touch_hint,Rect2(offset+Vector2(8,180),Vector2(176,20)))
		touch_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
		var rects := {"drive_boost":Rect2(456,252,80,44),"drive_brake":Rect2(544,252,80,44),"drive_dodge":Rect2(456,202,80,44),"drive_comfort":Rect2(544,202,80,44),"drive_fire":Rect2(456,302,80,44),"drive_mine":Rect2(544,302,80,44)}
		for action in rects:
			var rect: Rect2=rects[action]
			touch_by_action[action].fit(Rect2(rect.position+offset,rect.size))
	position=world_origin
	if not result_buttons.is_empty():
		for i in result_buttons.size():
			_place(result_buttons[i],Rect2(Vector2(12+i*(view.x/2),view.y-64),Vector2(view.x/2-24,48)) if portrait else Rect2(offset+Vector2(166+i*160,300),Vector2(148,44)))
	_place(journal_panel,Rect2(Vector2(12,24),view-Vector2(24,48)) if portrait else Rect2(offset+Vector2(80,24),Vector2(480,312)))
	_sync_touch()
	_update_hud()
	if not radio_text.is_empty(): _reflow_radio()

func _radio_snapshot() -> Dictionary:
	var labels: Array=[bubble,radio_page_caption,status_label,hint,story_caption,toast,mission,momo_title,hud,score_label,energy_caption,distance_caption,brand_label]
	var widgets: Array=[]
	for label in labels:
		if label.visible and not label.text.is_empty(): widgets.append({"rect":QA.rect(label),"fits":TextFit.fits(label),"text":label.text})
	return {"speaker":radio_speaker,"page":radio_page,"pages":radio_pages.size(),"bubble":QA.rect(bubble),"status":QA.rect(status_label),"caption":QA.rect(radio_page_caption),"hint":QA.rect(hint),"widgets":widgets}

func _build_journal(parent: Node) -> void:
	journal_panel=PanelContainer.new()
	journal_panel.z_index=30
	journal_panel.theme=ui_theme
	journal_panel.add_theme_stylebox_override("panel",UiSkin.panel(Color("9de1c3")))
	parent.add_child(journal_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	journal_panel.add_child(column)
	var title := Label.new()
	title.text="YOL GÜNLÜĞÜ · Omega-3"
	column.add_child(title)
	journal_scroll=ScrollContainer.new()
	journal_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	journal_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(journal_scroll)
	journal_text=Label.new()
	journal_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	journal_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	journal_scroll.add_child(journal_text)
	var back := Button.new()
	back.text="Molaya dön · Esc / B"
	back.custom_minimum_size.y=44
	UiSkin.style_button(back)
	back.pressed.connect(_close_journal)
	column.add_child(back)
	journal_panel.hide()


func _open_journal() -> void:
	_set_paused(true)
	_clear_pointers()
	pause_panel.hide()
	journal_text.text="\n\n".join(journey.log_lines)+"\n\n"+journey.goal_text(comfort_count,arcade.collected)+"\n\nYukarı/aşağı, fare tekerleği veya parmağınla kaydır."
	journal_panel.show()
	(journal_panel.get_child(0).get_child(2) as Button).grab_focus()


func _close_journal() -> void:
	journal_panel.hide()
	pause_panel.show()
	(pause_panel.get_child(0).get_child(1) as Button).grab_focus()
