extends Node2D
## Sefer sahnesi: kayan üç şeritli yol, yazarak sürülen araba, zaman yavaşlaması,
## üç düşman tipi, silah, mayın, hasar, MOMO'nun komutu ruh haline göre yorumlaması
## ve sefer sonu ekranı. Oyun kuralları scripts/core/ altında, sayılar data/balance.json'da.

const DataLoader := preload("res://scripts/core/data_loader.gd")
const CommandParser := preload("res://scripts/core/command_parser.gd")
const Momo := preload("res://scripts/core/momo.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Garage := preload("res://scripts/core/garage.gd")
const CAR_SHEET := preload("res://assets/sprites/player_car.png")
const FONT := preload("res://assets/fonts/Lexend.ttf")

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


func _ready() -> void:
	rng.randomize()
	balance = DataLoader.load_json(DataLoader.BALANCE_PATH)
	run_cfg = balance.get("run", {})
	parser = CommandParser.new(DataLoader.load_json(DataLoader.INTENTS_PATH), balance)
	store = SaveStore.new()
	save = store.load_data()
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
	_say("Hazırım. Ne yapalım?")


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
	theme.default_font = FONT
	theme.default_font_size = 12
	hud = _label(ui, theme, Vector2(8, 6), Vector2(190, 90))
	bubble = _label(ui, theme, Vector2(W - 218, 6), Vector2(210, 70))
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint = _label(ui, theme, Vector2(0, H - 20), Vector2(W, 16))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "Yazmaya başla: sola geç · sağa geç · hızlan · yavaşla · kamyona ateş et · mayın bırak · kaç · aferin"
	hint.add_theme_font_size_override("font_size", 10)
	hint.modulate = Color(1, 1, 1, 0.75)
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
	end_panel.add_theme_stylebox_override("normal", bg)
	end_panel.visible = false
	box = LineEdit.new()
	box.theme = theme
	box.position = Vector2(W / 2 - 160, H - 48)
	box.size = Vector2(320, 24)
	box.placeholder_text = "MOMO'ya yaz · Enter gönderir · Esc vazgeçer"
	box.visible = false
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


func _lane_x(index: int) -> float:
	return W / 2 + (index - (lane_count - 1) / 2.0) * lane_width


func _lane_of(x: float) -> int:
	return clampi(roundi((x - W / 2) / lane_width + (lane_count - 1) / 2.0), 0, lane_count - 1)


# ---------------------------------------------------------------------------
# Input: the only control is typing.
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if over:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			get_tree().reload_current_scene()
		elif event is InputEventScreenTouch and event.pressed:
			get_tree().reload_current_scene()
		return
	if box.visible:
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
	if over:
		return
	for command in parser.parse(text):
		var res: Dictionary = momo.interpret(command, rng, game_time)
		if str(res.get("line", "")) != "":
			_say(str(res["line"]))
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
	bubble.text = "MOMO: " + line
	bubble_left = 3.5


func _event(ev: Variant) -> void:
	var res: Dictionary = momo.apply_event(ev, rng)
	if str(res.get("line", "")) != "":
		_say(str(res["line"]))


func _play(name: String) -> void:
	if anim == "destroyed":
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
	var origin := Vector2(car_x, PLAYER_Y - 30)
	var dir := Vector2.UP
	var want: Dictionary = target if target is Dictionary else {}
	var aim := _find_target(want) if not want.is_empty() and (str(want.get("type", "")) != "" or str(want.get("position", "")) != "" or str(want.get("side", "")) != "") else _find_target({"position": "front"})
	if not aim.is_empty():
		dir = (aim["pos"] - origin).normalized()
	elif not want.is_empty() and str(want.get("type", "")) != "":
		_say("Orada %s yok ki." % TYPE_NAMES.get(str(want["type"]), "öyle bir şey"))
	bullets.append({"pos": origin, "vel": dir * _cfg("weapon.bullet_speed", 420)})
	_play("fire")


# ---------------------------------------------------------------------------
# Simulation
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not over:
		_simulate(delta)
	_animate(delta)
	bubble_left -= delta / maxf(Engine.time_scale, 0.01)  # the bubble ignores slow time
	if bubble_left <= 0.0:
		bubble.text = ""
	var minutes := game_time / 60.0
	hud.text = "Can %d/%d\nMesafe %d m · Yok edilen %d\nHız %d · Mayın %d\nGüven %d · MOMO %s" % [
		maxi(0, int(ceil(hp))), int(max_hp), int(distance), kills, int(speed), mines_left,
		int(momo.trust), Momo.mood_name_tr(momo.mood)]
	hint.visible = not box.visible and not over and minutes < 1.5
	queue_redraw()


func _simulate(delta: float) -> void:
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
	for fx in effects:
		fx["t"] = float(fx["t"]) + delta
	effects = effects.filter(func(f: Dictionary) -> bool: return float(f["t"]) < 0.8)


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
				effects.append({"pos": m["pos"], "t": 0.0, "kind": "boom"})
				m["life"] = -1.0
				break
	mines = mines.filter(func(m: Dictionary) -> bool: return float(m["life"]) > 0.0 and m["pos"].y < H + 20)


func _update_obstacles(delta: float) -> void:
	var pr := _player_rect()
	for o in obstacles:
		o["pos"] = o["pos"] + Vector2(0, speed * delta)
		var r := _rect(o["pos"], Vector2(8, 8))
		if float(o["hp"]) <= 0.0:
			effects.append({"pos": o["pos"], "t": 0.0, "kind": "spark"})
			o["dead"] = true
		elif r.intersects(pr):
			o["dead"] = true
			effects.append({"pos": o["pos"], "t": 0.0, "kind": "spark"})
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
					obstacles.append({"pos": e["pos"] + Vector2(0, 44), "kind": kinds[rng.randi() % 3], "hp": 20.0, "dmg": float(cfg.get("obstacle_damage", 20)), "near": false, "passed": false})
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
		_event("manoeuvre_success")
	elif gap >= 0.0 and gap < float(run_cfg.get("near_miss_distance", 18)):
		_event("near_miss")


func _hurt_enemy(e: Dictionary, amount: float) -> void:
	e["hp"] = float(e["hp"]) - amount
	e["flash"] = 0.12
	if float(e["hp"]) <= 0.0 and not e.has("dead"):
		_explode(e, true)


func _explode(e: Dictionary, by_player: bool) -> void:
	e["dead"] = true
	effects.append({"pos": e["pos"], "t": 0.0, "kind": "boom"})
	_shake(float(DataLoader.dig(run_cfg, "screen_shake.kill", 2.0)))
	if by_player:
		kills += 1
		_event("kill")


func _damage_player(amount: float, tell := true) -> void:
	if invulnerable > 0.0 or dodge_left > 0.0 or over:
		return
	hp -= amount
	invulnerable = _cfg("player.invulnerable_after_hit", 0.6)
	_shake(float(DataLoader.dig(run_cfg, "screen_shake.hit", 3.0)))
	_play("hit")
	if tell:
		_event({"type": "damage", "amount": amount})
	if hp <= 0.0:
		_end_run()


func _shake(power: float) -> void:
	shake = float(DataLoader.dig(run_cfg, "screen_shake.seconds", 0.2))
	shake_power = power


func _end_run() -> void:
	over = true
	_close_box()
	anim = "destroyed"
	anim_t = 0.0
	pending.clear()
	end_result = momo.end_run("destroyed", rng)
	var garage := Garage.new(DataLoader.load_json(DataLoader.GARAGE_PATH), balance)
	save["trust"] = momo.trust
	var run_info := end_result.duplicate()
	run_info["distance"] = distance
	run_info["kills"] = kills
	save["memory"] = garage.record_run(save.get("memory", {}), run_info)
	var saved: bool = store.save_data(save)
	var d := float(end_result.get("trust_delta", 0.0))
	end_panel.text = "SEFER BİTTİ\n\nMesafe: %d m\nYok edilen düşman: %d\nGüven: %d → %d (%s%d)\n\nMOMO: “%s”\n\n%sEnter ile yeni sefer" % [
		int(distance), kills, int(round(float(end_result.get("trust_before", 0)))), int(round(momo.trust)),
		"+" if d >= 0 else "", int(round(d)), str(end_result.get("comment", "...")),
		"" if saved else "(Kayıt yazılamadı)\n"]
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


func _draw() -> void:
	var off := Vector2.ZERO
	if shake > 0.0:
		off = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * shake_power
	position = off.round()
	draw_rect(Rect2(-8, -8, W + 16, H + 16), Color("1b1d2b"))
	var road_w := lane_count * lane_width
	var left := W / 2 - road_w / 2
	draw_rect(Rect2(left - 10, -8, road_w + 20, H + 16), Color("2a2c3a"))
	draw_rect(Rect2(left, -8, road_w, H + 16), Color("3a3d4d"))
	draw_rect(Rect2(left - 10, -8, 3, H + 16), Color("e0b84a"))
	draw_rect(Rect2(left + road_w + 7, -8, 3, H + 16), Color("e0b84a"))
	var y := scroll - 48.0
	while y < H + 8:
		for i in range(1, lane_count):
			draw_rect(Rect2(left + i * lane_width - 1, y, 2, 24), Color("d8d8e0"))
		draw_rect(Rect2(left - 40, y + 8, 12, 6), Color("3d2f4f"))
		draw_rect(Rect2(left + road_w + 28, y + 30, 12, 6), Color("3d2f4f"))
		y += 48.0
	for m in mines:
		var blink := Color("ff5a5a") if int(game_time * 6) % 2 == 0 or float(m["arm"]) > 0.0 else Color("7a2a2a")
		draw_rect(Rect2(m["pos"].x - 5, m["pos"].y - 5, 10, 10), Color("101018"))
		draw_rect(Rect2(m["pos"].x - 4, m["pos"].y - 4, 8, 8), Color("2f3140"))
		draw_rect(Rect2(m["pos"].x - 1, m["pos"].y - 1, 2, 2), blink)
	for o in obstacles:
		_draw_obstacle(o)
	for e in enemies:
		_draw_enemy(e)
	for b in bullets:
		draw_rect(Rect2(b["pos"].x - 1, b["pos"].y - 4, 2, 8), Color("7fe7ff"))
	for b in enemy_bullets:
		draw_rect(Rect2(b["pos"].x - 2, b["pos"].y - 2, 4, 4), Color("ff7a3a"))
		draw_rect(Rect2(b["pos"].x - 1, b["pos"].y - 1, 2, 2), Color("ffe08a"))
	for fx in effects:
		_draw_effect(fx)


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
