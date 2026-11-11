extends Node2D
## Kilometre taşı 1–2: kayan üç şeritli yol, yazarak sürülen araba, zaman yavaşlaması,
## MOMO'nun komutu ruh haline göre yorumlaması. Düşmanlar sonraki kilometre taşında gelir.

const DataLoader := preload("res://scripts/core/data_loader.gd")
const CommandParser := preload("res://scripts/core/command_parser.gd")
const Momo := preload("res://scripts/core/momo.gd")
const CAR_SHEET := preload("res://assets/sprites/player_car.png")
const FONT := preload("res://assets/fonts/Lexend.ttf")

const W := 640.0
const H := 360.0
const FW := 48
const FH := 80
# sheet rows: animation name -> [row, frame count, fps, loop]
const ANIMS := {
	"drive": [0, 4, 12.0, true], "shift_left": [2, 3, 14.0, false], "shift_right": [3, 3, 14.0, false],
	"boost": [4, 4, 14.0, false], "brake": [5, 2, 8.0, false], "fire": [6, 4, 16.0, false],
}

var balance: Dictionary
var parser: RefCounted
var momo: RefCounted
var rng := RandomNumberGenerator.new()

var lane_count := 3
var lane_width := 64.0
var lane := 1
var car_x := 0.0
var speed := 220.0
var target_speed := 220.0
var scroll := 0.0
var distance := 0.0
var game_time := 0.0
var slow_scale := 0.1
var pending: Array = []   # [{time_left, command, speed}]
var bullets: Array = []   # Vector2
var mines: Array = []     # Vector2
var mines_left := 3
var fire_cooldown := 0.0

var anim := "drive"
var anim_t := 0.0
var car: Sprite2D
var box: LineEdit
var bubble: Label
var hud: Label
var hint: Label
var bubble_left := 0.0


func _ready() -> void:
	rng.randomize()
	balance = DataLoader.load_json(DataLoader.BALANCE_PATH)
	parser = CommandParser.new(DataLoader.load_json(DataLoader.INTENTS_PATH), balance)
	momo = Momo.new(balance, DataLoader.load_json(DataLoader.MOMO_LINES_PATH))
	momo.start_run()
	var run: Dictionary = balance.get("run", {})
	lane_count = int(run.get("lane_count", 3))
	lane_width = float(run.get("lane_width", 64))
	speed = float(DataLoader.dig(run, "player.base_speed", 220))
	target_speed = speed
	mines_left = int(DataLoader.dig(run, "mine.count", 3))
	slow_scale = float(DataLoader.dig(balance, "time.command_box_time_scale", 0.1))
	lane = lane_count / 2
	car_x = _lane_x(lane)

	car = Sprite2D.new()
	car.texture = CAR_SHEET
	car.region_enabled = true
	car.position = Vector2(car_x, H - 70)
	add_child(car)

	var ui := CanvasLayer.new()
	add_child(ui)
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 12
	hud = _label(ui, theme, Vector2(8, 6), Vector2(200, 80))
	bubble = _label(ui, theme, Vector2(W - 208, 6), Vector2(200, 70))
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint = _label(ui, theme, Vector2(0, H - 20), Vector2(W, 16))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "Yazmaya başla: sola geç · sağa geç · hızlan · yavaşla · ateş et · mayın bırak · aferin"
	hint.modulate = Color(1, 1, 1, 0.75)
	box = LineEdit.new()
	box.theme = theme
	box.position = Vector2(W / 2 - 150, H - 48)
	box.size = Vector2(300, 24)
	box.placeholder_text = "MOMO'ya komut yaz, Enter gönderir, Esc vazgeçer"
	box.visible = false
	box.text_submitted.connect(_on_submit)
	ui.add_child(box)
	_say("Hazırım. Ne yapalım?")


func _label(parent: Node, theme: Theme, pos: Vector2, size: Vector2) -> Label:
	var l := Label.new()
	l.theme = theme
	l.position = pos
	l.size = size
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	l.add_theme_constant_override("outline_size", 4)
	parent.add_child(l)
	return l


func _lane_x(index: int) -> float:
	return W / 2 + (index - (lane_count - 1) / 2.0) * lane_width


func _unhandled_input(event: InputEvent) -> void:
	if box.visible:
		if event.is_action_pressed("ui_cancel"):
			_close_box()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var ch := char(event.unicode) if event.unicode > 32 else ""
		if ch != "":
			_open_box(ch)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		_open_box("")


func _input(event: InputEvent) -> void:
	if box.visible and event.is_action_pressed("ui_cancel"):
		_close_box()
		get_viewport().set_input_as_handled()


func _open_box(first: String) -> void:
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
	var commands: Array = parser.parse(text)
	for command in commands:
		var res: Dictionary = momo.interpret(command, rng, game_time)
		if str(res.get("line", "")) != "":
			_say(str(res["line"]))
		var action := str(res.get("action", "none"))
		if action == "execute" or action == "delay":
			var wait := float(res.get("delay", 0.0)) if action == "delay" else 0.0
			pending.append({"t": wait, "command": command})
			for extra in res.get("extra", []):
				pending.append({"t": wait + 0.25, "command": extra})


func _say(line: String) -> void:
	if line == "":
		return
	bubble.text = "MOMO: " + line
	bubble_left = 3.5


func _play(name: String) -> void:
	anim = name
	anim_t = 0.0


func _execute(command: Dictionary) -> void:
	var run: Dictionary = balance.get("run", {})
	var step := float(DataLoader.dig(run, "player.speed_step", 40))
	match str(command.get("intent", "")):
		"lane_left":
			if lane > 0:
				lane -= 1
				_play("shift_left")
		"lane_right":
			if lane < lane_count - 1:
				lane += 1
				_play("shift_right")
		"dodge":
			lane = lane - 1 if lane > 0 else lane + 1
			_play("shift_left" if _lane_x(lane) < car_x else "shift_right")
		"speed_up", "ram":
			target_speed = minf(target_speed + step, float(DataLoader.dig(run, "player.max_speed", 340)))
			_play("boost")
		"slow_down":
			target_speed = maxf(target_speed - step, float(DataLoader.dig(run, "player.min_speed", 140)))
			_play("brake")
		"fire":
			if fire_cooldown <= 0.0:
				bullets.append(Vector2(car_x, car.position.y - 34))
				fire_cooldown = float(DataLoader.dig(run, "weapon.cooldown", 0.45))
				_play("fire")
		"drop_mine":
			if mines_left > 0:
				mines_left -= 1
				mines.append(Vector2(car_x, car.position.y + 36))


func _process(delta: float) -> void:
	game_time += delta
	fire_cooldown -= delta
	for item in pending:
		item["t"] = float(item["t"]) - delta
	var ready := pending.filter(func(i: Dictionary) -> bool: return float(i["t"]) <= 0.0)
	pending = pending.filter(func(i: Dictionary) -> bool: return float(i["t"]) > 0.0)
	for item in ready:
		_execute(item["command"])

	var run: Dictionary = balance.get("run", {})
	var change := maxf(float(run.get("lane_change_seconds", 0.25)), 0.01)
	car_x = move_toward(car_x, _lane_x(lane), lane_width / change * delta)
	speed = move_toward(speed, target_speed, float(DataLoader.dig(run, "player.acceleration", 160)) * delta)
	scroll = fposmod(scroll + speed * delta, 48.0)
	distance += speed * delta * float(run.get("distance_per_pixel", 0.05))
	car.position.x = round(car_x)

	var bullet_speed := float(DataLoader.dig(run, "weapon.bullet_speed", 420))
	for i in range(bullets.size()):
		bullets[i] = bullets[i] + Vector2(0, -bullet_speed * delta)
	bullets = bullets.filter(func(b: Vector2) -> bool: return b.y > -8)
	for i in range(mines.size()):
		mines[i] = mines[i] + Vector2(0, speed * delta)
	mines = mines.filter(func(m: Vector2) -> bool: return m.y < H + 8)

	var a: Array = ANIMS[anim]
	anim_t += delta * float(a[2])
	var frame := int(anim_t)
	if frame >= int(a[1]):
		if bool(a[3]):
			frame %= int(a[1])
		else:
			_play("drive")
			a = ANIMS[anim]
			frame = 0
	car.region_rect = Rect2(frame * FW, int(a[0]) * FH, FW, FH)

	# The bubble timer must not stretch while time is slowed.
	bubble_left -= delta / maxf(Engine.time_scale, 0.01)
	if bubble_left <= 0.0:
		bubble.text = ""
	hud.text = "Mesafe %d m\nHız %d\nMayın %d\nGüven %d · %s" % [
		int(distance), int(speed), mines_left, int(momo.trust), Momo.mood_name_tr(momo.mood)]
	hint.visible = not box.visible
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("1b1d2b"))
	var road_w := lane_count * lane_width
	var left := W / 2 - road_w / 2
	draw_rect(Rect2(left - 10, 0, road_w + 20, H), Color("2a2c3a"))
	draw_rect(Rect2(left, 0, road_w, H), Color("3a3d4d"))
	draw_rect(Rect2(left - 10, 0, 3, H), Color("e0b84a"))
	draw_rect(Rect2(left + road_w + 7, 0, 3, H), Color("e0b84a"))
	var y := scroll - 48.0
	while y < H:
		for i in range(1, lane_count):
			draw_rect(Rect2(left + i * lane_width - 1, y, 2, 24), Color("d8d8e0"))
		draw_rect(Rect2(left - 40, y + 8, 12, 6), Color("3d2f4f"))
		draw_rect(Rect2(left + road_w + 28, y + 30, 12, 6), Color("3d2f4f"))
		y += 48.0
	for b in bullets:
		draw_rect(Rect2(b.x - 1, b.y - 4, 2, 8), Color("7fe7ff"))
	for m in mines:
		var blink := Color("ff5a5a") if int(game_time * 6) % 2 == 0 else Color("7a2a2a")
		draw_rect(Rect2(m.x - 4, m.y - 4, 8, 8), Color("22222c"))
		draw_rect(Rect2(m.x - 1, m.y - 1, 2, 2), blink)
