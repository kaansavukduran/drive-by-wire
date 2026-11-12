extends Node2D
## Sefer sahnesi: doğrudan ok tuşlu sürüş, üç şeritli yol, isteğe bağlı sohbet,
## üç düşman tipi, kapsüller, turbo, görevler, puan serisi ve MOMO ilişkisi
## ve sefer sonu ekranı. Oyun kuralları scripts/core/ altında, sayılar data/balance.json'da.

const DataLoader := preload("res://scripts/core/data_loader.gd")
const CommandParser := preload("res://scripts/core/command_parser.gd")
const Momo := preload("res://scripts/core/momo.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Garage := preload("res://scripts/core/garage.gd")
const Session := preload("res://scripts/game/session.gd")
const MomoFace := preload("res://scripts/game/momo_face.gd")
const Sheets := preload("res://scripts/game/sheets.gd")
const UiSkin := preload("res://scripts/game/ui_skin.gd")
const Controls := preload("res://scripts/game/controls.gd")
const Arcade := preload("res://scripts/core/arcade.gd")
const Sounds := preload("res://scripts/game/sounds.gd")
const SettingsPanel := preload("res://scripts/game/settings_panel.gd")
const TouchControl := preload("res://scripts/game/touch_control.gd")
const FONT_SYMBOLS := preload("res://assets/fonts/ControlSymbols.ttf")
const CAR_SHEET := preload("res://assets/sprites/player_car.png")
const FONT_FALLBACK := preload("res://assets/fonts/Lexend.ttf")
const FONT_TERM := preload("res://assets/fonts/VT323.ttf")

const W := 640.0
const H := 360.0
const FW := 48
const FH := 80
const PLAYER_Y := 290.0
const PLAYER_HALF := Vector2(11, 26)
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

var lane_count := 3
var lane_width := 64.0
var lane := 1
var prev_lane := 1
var lane_changed_at := -10.0
var car_x := 0.0
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
var mines_left := 3
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
var face: Control
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
var metrics_clock := 0.0


func _ready() -> void:
	Controls.install()
	rng.randomize()
	var base_balance := DataLoader.load_json(DataLoader.BALANCE_PATH)
	store = SaveStore.new()
	save = store.load_data()
	var garage := Garage.new(DataLoader.load_json(DataLoader.GARAGE_PATH), base_balance)
	balance = garage.effective_balance(base_balance, save.get("upgrades", {}), Session.next_run_modifiers)
	Session.next_run_modifiers = []
	run_cfg = balance.get("run", {})
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
			_set_paused(true))
	parser = CommandParser.new(DataLoader.load_json(DataLoader.INTENTS_PATH), balance)
	momo = Momo.new(balance, DataLoader.load_json(DataLoader.MOMO_LINES_PATH), float(save.get("trust", 50.0)))
	momo.start_run()
	lane_count = int(run_cfg.get("lane_count", 3))
	lane_width = float(run_cfg.get("lane_width", 64))
	speed = _cfg("player.base_speed", 220)
	target_speed = speed
	max_hp = _cfg("player.max_hp", 100)
	hp = max_hp
	mines_left = int(_cfg("mine.count", 3))
	spawn_timer = _cfg("spawn.initial_delay", 2.0)
	slow_scale = float(DataLoader.dig(balance, "time.command_box_time_scale", 0.1))
	lane = lane_count / 2
	prev_lane = lane
	car_x = _lane_x(lane)
	_build_ui()
	face.decorative_motion = motion_enabled
	_say("Oklar sende.\nSpace ile ateş!")


func _cfg(path: String, fallback: float) -> float:
	return float(DataLoader.dig(run_cfg, path, fallback))


func _build_ui() -> void:
	car = Sprite2D.new()
	car.texture = CAR_SHEET
	car.region_enabled = true
	car.position = Vector2(car_x, PLAYER_Y)
	add_child(car)
	var ui := CanvasLayer.new()
	add_child(ui)
	var theme := Theme.new()
	# Pixelify Sans digits (5 looks like S) hurt HUD readability; Lexend stays the UI font.
	var font: FontFile = FONT_FALLBACK.duplicate()
	font.fallbacks = [FONT_SYMBOLS]
	theme.default_font = font
	theme.default_font_size = 12
	ui_theme = theme
	_panel(ui, Rect2(8, 8, 176, 151))
	_panel(ui, Rect2(456, 8, 176, 166))
	_panel(ui, Rect2(8, 172, 176, 97))
	var brand := _label(ui, theme, Vector2(18, 14), Vector2(156, 16))
	brand.text = "FRAGARIA INTERACTIVE"
	brand.add_theme_font_size_override("font_size", 9)
	brand.add_theme_color_override("font_color", Color("ff8fb1"))
	score_label = _label(ui, theme, Vector2(18, 32), Vector2(158, 36))
	score_label.add_theme_font_size_override("font_size", 20)
	hud = _label(ui, theme, Vector2(18, 75), Vector2(155, 65))
	hp_bar = _bar(ui, Rect2(18, 65, 154, 6), Color("7cddb5"))
	energy_bar = _bar(ui, Rect2(18, 146, 154, 5), Color("79d4ff"))
	energy_caption = _label(ui, theme, Vector2(18, 130), Vector2(154, 14))
	energy_caption.add_theme_font_size_override("font_size", 9)
	face = MomoFace.new()
	face.position = Vector2(466, 18)
	ui.add_child(face)
	var momo_title := _label(ui, theme, Vector2(523, 20), Vector2(98, 38))
	momo_title.text = "MOMO\nYol arkadaşın"
	momo_title.add_theme_font_size_override("font_size", 10)
	bubble = _label(ui, theme, Vector2(466, 68), Vector2(156, 58))
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label = _label(ui, theme, Vector2(466, 130), Vector2(156, 38))
	status_label.add_theme_font_size_override("font_size", 10)
	mission = _label(ui, theme, Vector2(18, 181), Vector2(156, 76))
	mission.add_theme_font_size_override("font_size", 11)
	mission.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route_bar = _bar(ui, Rect2(224, 8, 192, 4), Color("ffce70"))
	hint = _label(ui, theme, Vector2(456, 184), Vector2(176, 92))
	hint.text = "← → Şerit değiştir\n↑ Turbo  ·  ↓ Fren\nSpace / F Ateş (basılı tut)\nX Mayın  ·  Shift Sıyrıl\nC Destek  ·  T Sohbet"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_stylebox_override("normal", _panel_style())
	toast = _label(ui, theme, Vector2(202, 30), Vector2(236, 42))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.add_theme_font_size_override("font_size", 12)
	toast.add_theme_color_override("font_color", Color("ffce70"))
	var pause_button := _control_button(ui, Rect2(466, 282, 156, 26), "Mola · Esc", func(): _set_paused(true))
	pause_button.focus_mode = Control.FOCUS_NONE
	_build_pause(ui)
	_build_touch(ui)
	end_panel = _label(ui, theme, Vector2(W / 2 - 170, 70), Vector2(340, 220))
	end_panel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_panel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_panel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_panel.add_theme_font_size_override("font_size", 14)
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
	var term_font: FontFile = FONT_TERM.duplicate()
	term_font.fallbacks = [FONT_FALLBACK]
	box.add_theme_font_override("font", term_font)
	box.add_theme_font_size_override("font_size", 16)
	box.placeholder_text = "MOMO'ya yaz · Enter gönderir · Esc vazgeçer"
	box.visible = false
	box.add_theme_stylebox_override("normal", UiSkin.box("assets/ui/command_box.png", 6))
	box.add_theme_stylebox_override("focus", UiSkin.box("assets/ui/command_box.png", 6))
	box.text_submitted.connect(_on_submit)
	ui.add_child(box)


func _label(parent: Node, theme: Theme, pos: Vector2, size: Vector2) -> Label:
	var l := Label.new()
	l.theme = theme
	l.position = pos
	l.size = size
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	l.add_theme_constant_override("outline_size", 4)
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
	pause_panel.position = Vector2(200, 42)
	pause_panel.size = Vector2(240, 250)
	pause_panel.theme = ui_theme
	pause_panel.add_theme_stylebox_override("panel", _panel_style())
	parent.add_child(pause_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
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
		["Yeniden sür", _restart_run], ["Garaja dön", _to_garage], ["Ana menü", _to_title],
	]
	for item in items:
		var button := Button.new()
		button.text = item[0]
		button.custom_minimum_size.y = 27
		UiSkin.style_button(button)
		button.pressed.connect(item[1])
		column.add_child(button)
	var touch_toggle := CheckButton.new()
	touch_toggle.text = "Dokunmatik kontroller"
	touch_toggle.button_pressed = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	touch_toggle.toggled.connect(func(value: bool):
		touch_enabled = value
		for button in touch_controls:
			button.visible = value and not paused)
	column.add_child(touch_toggle)
	pause_panel.hide()
	settings_panel = SettingsPanel.new()
	settings_panel.changed.connect(_apply_settings)
	settings_panel.closed.connect(func():
		settings_panel.hide()
		pause_panel.show()
		(column.get_child(1) as Button).grab_focus())
	parent.add_child(settings_panel)


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


func _to_title() -> void:
	Engine.time_scale = 1.0
	get_tree().call_deferred("change_scene_to_file", "res://scenes/title.tscn")


func _build_touch(parent: Node) -> void:
	touch_enabled = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	var specs := [
		[Rect2(8, 270, 80, 42), "←", "drive_left"], [Rect2(96, 270, 80, 42), "→", "drive_right"],
		[Rect2(8, 316, 80, 42), "TURBO", "drive_up"], [Rect2(96, 316, 80, 42), "FREN", "drive_down"],
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


func _notice(text: String) -> void:
	toast.text = text
	toast_left = 2.0


func _lane_x(index: int) -> float:
	return W / 2 + (index - (lane_count - 1) / 2.0) * lane_width


func _lane_of(x: float) -> int:
	return clampi(roundi((x - W / 2) / lane_width + (lane_count - 1) / 2.0), 0, lane_count - 1)


# ---------------------------------------------------------------------------
# Direct driving never passes through MOMO's probabilistic interpretation.
# Typing is an optional conversation mode, opened explicitly with T.
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if is_instance_valid(settings_panel) and settings_panel.visible:
		if event.is_action_pressed("drive_pause"):
			settings_panel.closed.emit()
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
	if over or paused:
		return
	for action in Controls.KEYS:
		if event.is_action_pressed(action):
			_direct_action(action)
			get_viewport().set_input_as_handled()
			return


func _unhandled_input(event: InputEvent) -> void:
	if over and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			_restart_run()
		elif event.keycode == KEY_G:
			_to_garage()


func _direct_action(action: String) -> void:
	if over or paused or box.visible:
		return
	match action:
		"drive_left": _change_lane(lane - 1)
		"drive_right": _change_lane(lane + 1)
		"drive_fire": _fire({})
		"drive_mine": _execute({"intent": "drop_mine"})
		"drive_dodge": _execute({"intent": "dodge"})
		"drive_chat": _open_box("")
		"drive_comfort":
			if comfort_cooldown <= 0.0:
				comfort_cooldown = _cfg("arcade.comfort_cooldown", 8)
				_event("comfort")
				energy = minf(_cfg("arcade.boost_capacity", 100), energy + _cfg("arcade.energy_amount", 30))
				_notice("İyi bir ekibiz! +enerji")


func _held(action: String) -> bool:
	return Input.is_action_pressed(action) or bool(touch_held.get(action, false))


func _set_paused(value: bool) -> void:
	if over:
		return
	_close_box()
	paused = value
	for action in Controls.KEYS:
		Input.action_release(action)
	face.set_process(not value)
	face.queue_redraw()
	touch_held.clear()
	boosting = false
	pause_panel.visible = value
	for button in touch_controls:
		button.visible = touch_enabled and not value
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
	get_tree().call_deferred("reload_current_scene")


func _open_box(first: String) -> void:
	if paused or over:
		return
	touch_held.clear()
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
		var res: Dictionary = momo.interpret(command, rng, game_time)
		if str(res.get("line", "")) != "":
			_say(str(res["line"]))
		if str(command.get("intent", "")) == "unknown":
			face.confused = 1.5
		var action := str(res.get("action", "none"))
		if action == "execute" or action == "delay":
			var wait := float(res.get("delay", 0.0)) if action == "delay" else 0.0
			# Mood speed: >1 means MOMO reacts faster (escapes when scared, everything when excited).
			wait += 0.08 / maxf(float(res.get("speed", 1.0)), 0.25)
			pending.append({"t": wait, "command": command})
			for extra in res.get("extra", []):
				pending.append({"t": wait + 0.3, "command": extra})


func _say(line: String) -> void:
	if line == "":
		return
	bubble.text = line
	bubble_left = 3.5
	if face:
		face.talking = 1.2


func _event(ev: Variant) -> void:
	var res: Dictionary = momo.apply_event(ev, rng)
	if str(res.get("line", "")) != "":
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
			if mines_left > 0:
				mines_left -= 1
				mines.append({"pos": Vector2(car_x, PLAYER_Y + 30), "arm": _cfg("mine.arm_seconds", 0.3), "life": _cfg("mine.lifetime", 8.0)})
			else:
				_say("Mayın kalmadı!")


## Score for how dangerous a lane is right now (for dodge).
func _lane_threat(index: int) -> float:
	var t := 0.0
	for e in enemies:
		if int(e["lane"]) == index:
			t += 1.0
	for o in obstacles:
		if _lane_of(o["pos"].x) == index and o["pos"].y < PLAYER_Y:
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
		if position in ["front", "ahead", "öndeki", "ondeki"] and p.y > PLAYER_Y:
			continue
		if position in ["behind", "back", "arkadaki"] and p.y < PLAYER_Y:
			continue
		if side == "left" and p.x >= car_x - 4:
			continue
		if side == "right" and p.x <= car_x + 4:
			continue
		var score := p.distance_to(Vector2(car_x, PLAYER_Y))
		if score < best_score:
			best_score = score
			best = e
	return best


func _fire(target: Variant) -> void:
	if fire_cooldown > 0.0:
		return
	fire_cooldown = _cfg("weapon.cooldown", 0.45)
	sounds.cue("fire")
	var origin := Vector2(car_x, PLAYER_Y - 30)
	var dir := Vector2.UP
	var want: Dictionary = target if target is Dictionary else {}
	var aim := _find_target(want)
	if not aim.is_empty():
		dir = (aim["pos"] - Vector2(car_x, PLAYER_Y)).normalized()
		origin = Vector2(car_x, PLAYER_Y) + dir * 30.0
	elif not want.is_empty() and str(want.get("type", "")) != "":
		_say("Orada %s yok ki." % TYPE_NAMES.get(str(want["type"]), "öyle bir şey"))
	bullets.append({"pos": origin, "vel": dir * _cfg("weapon.bullet_speed", 420)})
	_play("fire")


# ---------------------------------------------------------------------------
# Simulation
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	metrics_clock += delta
	if OS.has_feature("web") and metrics_clock > 5.0:
		metrics_clock = 0.0
		# Local QA snapshot only. No network, analytics, player data or telemetry.
		JavaScriptBridge.eval("document.documentElement.dataset.gameFps='%d';document.documentElement.dataset.godotMemoryBytes='%d';" % [Engine.get_frames_per_second(), OS.get_static_memory_usage()])
	if not paused:
		_animate(delta)
		bubble_left -= delta / maxf(Engine.time_scale, 0.01)
		toast_left -= delta
	if bubble_left <= 0.0:
		bubble.text = ""
	toast.visible = toast_left > 0.0 and not paused and not over
	score_label.text = "%06d" % arcade.score
	hud.text = "CAN %d / %d\n%d m / %d m\nHız %d · Mayın %d" % [maxi(0, ceili(hp)), int(max_hp), int(distance), int(_cfg("arcade.finish_distance", 1200)), int(speed), mines_left]
	hp_bar.value = hp / max_hp * 100.0
	energy_bar.value = energy / _cfg("arcade.boost_capacity", 100) * 100.0
	energy_caption.text = "TURBO · ENERJİ %d%%" % int(energy_bar.value)
	route_bar.value = distance / _cfg("arcade.finish_distance", 1200) * 100.0
	var progress: Vector2 = arcade.contract_progress(distance, kills)
	mission.text = "GÖREV %02d\n%s\n%d / %d\nSeri %d · En iyi %d" % [arcade.contract + 1, arcade.contract_title(), mini(int(progress.x), int(progress.y)), int(progress.y), arcade.chain, arcade.best_chain]
	status_label.text = "Güven %d · %s\n%s" % [int(momo.trust), Momo.mood_name_tr(momo.mood), ("KALKAN %.1f sn" % shield_left) if shield_left > 0 else (("Destek %.0f sn" % comfort_cooldown) if comfort_cooldown > 0 else "C · Destek hazır")]
	face.mood = momo.mood
	face.queue_redraw()
	hint.visible = not box.visible and not over
	queue_redraw()


func _physics_process(delta: float) -> void:
	if paused or over:
		return
	if not box.visible and _held("drive_fire"):
		_fire({})
	_simulate(delta)


func _simulate(delta: float) -> void:
	if paused or over:
		return
	arcade.tick(delta)
	shield_left = maxf(0.0, shield_left - delta)
	comfort_cooldown = maxf(0.0, comfort_cooldown - delta)
	var normal_speed := _cfg("player.base_speed", 220)
	boosting = not box.visible and _held("drive_up") and energy > 0.0 and not _held("drive_down")
	if not box.visible and _held("drive_down"):
		target_speed = _cfg("player.min_speed", 140)
	elif boosting:
		target_speed = _cfg("player.max_speed", 340) + _cfg("arcade.boost_speed", 95)
		energy = maxf(0.0, energy - _cfg("arcade.boost_drain", 24) * delta)
		if anim == "drive":
			_play("boost")
	else:
		target_speed = normal_speed
		if not _held("drive_up"):
			energy = minf(_cfg("arcade.boost_capacity", 100), energy + _cfg("arcade.boost_regen", 12) * delta)
	game_time += delta
	fire_cooldown -= delta
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

	var change := maxf(float(run_cfg.get("lane_change_seconds", 0.25)), 0.01)
	car_x = move_toward(car_x, _lane_x(lane), lane_width / change * delta)
	speed = move_toward(speed, target_speed, _cfg("player.acceleration", 160) * delta)
	scroll = fposmod(scroll + speed * delta, 48.0)
	distance += speed * delta * float(run_cfg.get("distance_per_pixel", 0.05))
	car.position = Vector2(round(car_x), PLAYER_Y)

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
		mines_left += 1
		_notice("GÖREV TAMAM! +%d puan\n+onarım · +mayın" % int(_cfg("arcade.contract_reward", 200)))
	if distance >= _cfg("arcade.finish_distance", 1200):
		_end_run("survived")
	for fx in effects:
		fx["t"] = float(fx["t"]) + delta
		if not fx.get("still", false):
			var k := str(fx["kind"])
			var mul := 0.6 if k.begins_with("wreck_") else (3.0 if k == "speed" else 1.0)
			fx["pos"] = fx["pos"] + Vector2(0, speed * delta * mul)
	if motion_enabled and speed > _cfg("player.base_speed", 220) + 20.0 and rng.randf() < delta * 18.0:
		var sx := rng.randf_range(200, 230) if rng.randf() < 0.5 else rng.randf_range(410, 440)
		effects.append({"pos": Vector2(sx, rng.randf_range(-40, 200)), "t": 0.0, "kind": "speed"})
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
			mines_left += 1
			_notice("İKMAL · +enerji +mayın")
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
	return Rect2(Vector2(car_x, PLAYER_Y) - PLAYER_HALF, PLAYER_HALF * 2)


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
	bullets = bullets.filter(func(b: Dictionary) -> bool: return not b.has("dead") and b["pos"].y > -10 and b["pos"].y < H + 10)
	var pr := _player_rect()
	for b in enemy_bullets:
		b["pos"] = b["pos"] + b["vel"] * delta
		if pr.has_point(b["pos"]):
			b["dead"] = true
			_damage_player(float(b["dmg"]))
		else:
			_check_near(b, Rect2(b["pos"] - Vector2(2, 2), Vector2(4, 4)), lane)
	enemy_bullets = enemy_bullets.filter(func(b: Dictionary) -> bool: return not b.has("dead") and b["pos"].y < H + 10)


func _update_mines(delta: float) -> void:
	for m in mines:
		m["pos"] = m["pos"] + Vector2(0, speed * delta)
		m["arm"] = float(m["arm"]) - delta
		m["life"] = float(m["life"]) - delta
		if float(m["arm"]) > 0.0:
			continue
		for e in enemies:
			if _rect(e["pos"], ENEMY_HALF[e["type"]] + Vector2(4, 4)).has_point(m["pos"]):
				_hurt_enemy(e, _cfg("mine.damage", 60))
				effects.append({"pos": m["pos"], "t": 0.0, "kind": "small"})
				m["life"] = -1.0
				break
	mines = mines.filter(func(m: Dictionary) -> bool: return float(m["life"]) > 0.0 and m["pos"].y < H + 20)


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
				var dist := absf(e["pos"].y - PLAYER_Y)
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
					if float(e["cd"]) <= 0.0:
						e["cd"] = float(cfg.get("fire_cooldown", 1.6))
						e["state"] = "attack"
						e["t"] = 0.0
						var dir: Vector2 = (Vector2(car_x, PLAYER_Y) - e["pos"]).normalized()
						enemy_bullets.append({"pos": e["pos"] + Vector2(0, 20), "vel": dir * float(cfg.get("bullet_speed", 300)), "dmg": float(cfg.get("bullet_damage", 8)), "near": false, "passed": false})
					if float(e["lane_cd"]) <= 0.0 and rng.randf() < 0.01:
						e["lane"] = clampi(int(e["lane"]) + (1 if rng.randf() < 0.5 else -1), 0, lane_count - 1)
						e["lane_cd"] = 2.0
			"truck":
				vy = minf(vy, 70.0) if e["pos"].y < 120 else vy
				if float(e["cd"]) <= 0.0 and e["pos"].y > 0.0 and e["pos"].y < PLAYER_Y - 80:
					e["cd"] = float(cfg.get("obstacle_cooldown", 3.0))
					e["state"] = "attack"
					e["t"] = 0.0
					var kinds := ["crate", "barrel", "spikes"]
					obstacles.append({"pos": e["pos"] + Vector2(0, 52), "kind": kinds[rng.randi() % 3], "hp": 20.0, "dmg": float(cfg.get("obstacle_damage", 20)), "near": false, "passed": false})
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
		e["pos"] = e["pos"] + Vector2(0, -24 if e["pos"].y < PLAYER_Y else 24)
		return
	_damage_player(float(cfg.get("contact_damage", 15)))
	if str(e["type"]) == "rammer":
		e["hp"] = 0.0
		_explode(e, false)
	else:
		e["pos"] = e["pos"] + Vector2(0, -30 if e["pos"].y < PLAYER_Y else 30)


## Near miss / successful manoeuvre: something passed the car without touching it.
func _check_near(thing: Dictionary, r: Rect2, thing_lane: int) -> void:
	if thing.get("passed", false):
		return
	var pr := _player_rect()
	var center_y := r.get_center().y
	if center_y < PLAYER_Y:
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
		effects.append({"pos": Vector2(car_x + side * 16.0, PLAYER_Y), "t": 0.0, "kind": "near_miss", "still": true})


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
	touch_held.clear()
	_close_box()
	anim = "destroyed" if outcome == "destroyed" else "drive"
	anim_t = 0.0
	pending.clear()
	if outcome == "survived":
		arcade.score += int(_cfg("arcade.finish_reward", 500))
	end_result = momo.end_run(outcome, rng)
	var garage := Garage.new(DataLoader.load_json(DataLoader.GARAGE_PATH), balance)
	save["trust"] = momo.trust
	var run_info := end_result.duplicate()
	run_info["distance"] = distance
	run_info["kills"] = kills
	save["memory"] = garage.record_run(save.get("memory", {}), run_info)
	save["best_score"] = maxi(int(save.get("best_score", 0)), arcade.score)
	var saved: bool = store.save_data(save)
	var d := float(end_result.get("trust_delta", 0.0))
	end_panel.text = "%s\n\nPUAN %d · REKOR %d\nMesafe: %d m · Düşman: %d\nEn iyi seri: %d · Görev: %d\nGüven: %d (%s%d)\n\nMOMO: %s\n\n%sEnter: yeniden sür · G: garaj" % [
		"YOLU AŞTIK!" if outcome == "survived" else "TEKRAR DENEYELİM",
		arcade.score, int(save["best_score"]), int(distance), kills, arcade.best_chain, arcade.contract,
		int(momo.trust), "+" if d >= 0 else "", int(round(d)), str(end_result.get("comment", "...")),
		"" if saved else "Kayıt yazılamadı.\n"]
	for button in touch_controls:
		button.hide()
	var layer := end_panel.get_parent()
	var retry := _control_button(layer, Rect2(166, 300, 148, 30), "Yeniden sür", _restart_run)
	retry.grab_focus()
	_control_button(layer, Rect2(326, 300, 148, 30), "Garaj", _to_garage)

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
	car.region_rect = Rect2(frame * FW, int(a[0]) * FH, FW, FH)
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
	if rng.randf() < delta * 0.6:
		decals.append({"pos": Vector2(_lane_x(rng.randi_range(0, lane_count - 1)) + rng.randf_range(-14, 14), -30), "frame": rng.randi_range(0, 5)})
	if rng.randf() < delta * 0.5:
		var names := ["billboard_obey", "billboard_buy", "billboard_momo", "neon_fuel", "neon_open", "pylon", "wreck", "toxic_puddle", "barrels"]
		var anim: String = names[rng.randi() % names.size()]
		var left := rng.randf() < 0.5
		var par: Variant = DataLoader.dig(sheets.sheet("roadside_props"), "parallax." + anim, null)
		if par == null:
			par = 1.15 if anim.begins_with("billboard") or anim.begins_with("neon") else 1.0
		props.append({"pos": Vector2(rng.randf_range(40, 170) if left else rng.randf_range(470, 600), -70), "anim": anim, "parallax": float(par)})


func _draw() -> void:
	var off := Vector2.ZERO
	if shake > 0.0 and effects_enabled and not paused:
		off = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * shake_power
	position = off.round()
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
		draw_arc(Vector2(car_x, PLAYER_Y), 32, 0, TAU, 32, Color("79d4ff"), 2)
	if boosting and not over:
		for side in [-1, 1]:
			draw_line(Vector2(car_x + side * 7, PLAYER_Y + 28), Vector2(car_x + side * 7, PLAYER_Y + 38 + sin(game_time * 40) * 5), Color("79d4ff"), 3)
	# Offscreen pursuers receive a lane marker before entering the playfield.
	for enemy in enemies:
		if enemy["pos"].y > H and not enemy.has("dead"):
			var x := _lane_x(int(enemy["lane"]))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 6, 347), Vector2(x + 6, 347), Vector2(x, 339)]), Color("ff8b8b"))
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
		var dir := Vector2(car_x, PLAYER_Y) - tp
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
	if kind.begins_with("wreck_"):
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
			var dir: Vector2 = (Vector2(car_x, PLAYER_Y) - turret).normalized()
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
