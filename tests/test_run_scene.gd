extends SceneTree
## Drives the real run scene headlessly: typed commands, combat, damage and run end.
## The save goes to a throwaway path so the player's real save is untouched.

const Harness := preload("res://tests/harness.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")

var h: RefCounted
var game: Node2D
var step := 0


func _initialize() -> void:
	h = Harness.new("run_scene")
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)


func _tick(seconds: float) -> void:
	var n := int(seconds * 60.0)
	for i in range(n):
		game._simulate(1.0 / 60.0)


func _process(_delta: float) -> bool:
	step += 1
	if step < 2:
		return false  # let _ready run
	game.store = SaveStore.new("user://test_run_scene_save.json")
	game.store.clear()
	game.rng.seed = 7
	game.spawn_timer = 999.0  # spawn by hand

	var start_lane: int = game.lane
	game._on_submit("sola geç")
	_tick(0.6)
	h.check("typed 'sola geç' moves one lane left (or MOMO refuses with a line)", game.lane == start_lane - 1 or game.bubble.text != "")
	game.momo.set_mood("calm")
	game.lane = 1
	game.car_x = game._lane_x(1)
	game._on_submit("sağa geç ve ateş et")
	_tick(0.6)
	h.eq("chained: lane right", game.lane, 2)
	h.check("chained: a bullet was fired", game.bullets.size() > 0 or game.fire_cooldown < 0.45)

	game.box.visible = false
	game._open_box("x")
	h.near("command box slows time to the configured scale", Engine.time_scale, game.slow_scale, 0.001)
	game._close_box()
	h.eq("closing the box restores time", Engine.time_scale, 1.0)

	# Truck ahead in our lane: targeted fire destroys it and counts a kill.
	game.momo.set_mood("calm")
	game.enemies.clear()
	game.bullets.clear()
	game.lane = 1
	game.car_x = game._lane_x(1)
	game._spawn_enemy_for_test("truck", 1, 150.0)
	var truck_hp: float = game.enemies[0]["hp"]
	var shots := 0
	while game.enemies.size() > 0 and shots < 20:
		game.fire_cooldown = 0.0
		game._fire({"type": "truck", "position": "", "side": ""})
		_tick(0.5)
		shots += 1
	h.check("targeted fire destroys the truck (hp %d) within 20 shots" % int(truck_hp), game.enemies.is_empty(), "shots %d" % shots)
	h.check("kill counted", game.kills >= 1)

	# Rammer from behind in our lane hits us.
	game.obstacles.clear()
	game.enemy_bullets.clear()
	var hp_before: float = game.hp
	game.invulnerable = 0.0
	game._spawn_enemy_for_test("rammer", 1, game.PLAYER_Y + 80.0)
	_tick(3.0)
	h.check("rammer contact damages the car", game.hp < hp_before, "hp %s -> %s" % [hp_before, game.hp])

	# Mine behind us destroys a rammer coming from behind.
	game.lane = 0
	game.car_x = game._lane_x(0)
	game.mines_left = 3
	game._execute({"intent": "drop_mine"})
	game.mines[0]["pos"] = Vector2(game._lane_x(2), game.PLAYER_Y + 60.0)
	game.mines[0]["arm"] = 0.0
	var kills_before: int = game.kills
	game._spawn_enemy_for_test("rammer", 2, game.PLAYER_Y + 100.0)
	game.enemies[-1]["lane_cd"] = 999.0
	_tick(0.4)
	h.check("an armed mine destroys an enemy", game.kills > kills_before)

	# Pickup holds a slot ahead and shoots.
	game.enemies.clear()
	game._spawn_enemy_for_test("pickup", 1, 100.0)
	game.enemies[0]["cd"] = 0.0
	_tick(0.2)
	h.check("pickup shoots at the car", game.enemy_bullets.size() > 0)

	# Unknown text: confused line, nothing breaks.
	game.bubble.text = ""
	game._on_submit("muz kabuğu fırlat galaksiye")
	h.check("nonsense gets a confused MOMO line", game.bubble.text != "")

	# Death ends the run, writes trust to the save and shows the end screen.
	game.hp = 1.0
	game.invulnerable = 0.0
	game.dodge_left = 0.0
	game._damage_player(50.0)
	h.check("run over", game.over)
	h.check("end panel visible with distance and trust", game.end_panel.visible and game.end_panel.text.contains("Mesafe") and game.end_panel.text.contains("Güven"))
	var saved: Dictionary = game.store.load_data()
	h.near("trust saved to file", float(saved["trust"]), float(game.momo.trust), 0.01)
	game.store.clear()
	quit(h.finish())
	return true
