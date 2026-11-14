extends SceneTree
## Real scene integration: input events, held controls, pause, rewards and victory.

const Harness := preload("res://tests/harness.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const Arcade := preload("res://scripts/core/arcade.gd")
var game: Node2D
var h := Harness.new("arcade_scene")
var step := 0

func _initialize() -> void:
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)

func key(code: int, pressed := true) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func tick(seconds: float) -> void:
	for i in range(int(seconds * 60)):
		game._simulate(1.0 / 60.0)

func touch(id: int, pos: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = root.get_final_transform() * pos
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _process(_delta: float) -> bool:
	step += 1
	if step < 2:
		return false
	game.store = SaveStore.new("user://test_arcade_scene.json")
	game.store.clear()
	game.spawn_timer = 9999.0
	game.pickup_timer = 9999.0
	game.momo.set_mood("sulky")
	key(KEY_LEFT)
	tick(0.4)
	h.check("held left moves freely despite companion mood", game.car_x < 280)
	key(KEY_LEFT, false)
	key(KEY_RIGHT)
	tick(0.4)
	h.check("held right reverses free movement", game.car_x > 290)
	key(KEY_RIGHT, false)
	key(KEY_E)
	tick(1)
	h.near("retired E does not accelerate",game.speed,220,0.1)
	h.eq("retired turbo consumes no energy",game.energy,100.0)
	key(KEY_E, false)
	key(KEY_Q)
	tick(2)
	h.near("retired Q does not brake",game.speed,220,0.1)
	key(KEY_Q, false)
	key(KEY_SPACE)
	h.check("space fires with no text box", game.bullets.size() > 0 and not game.box.visible)
	key(KEY_SPACE, false)
	game.fire_cooldown = 0
	game._spawn_enemy_for_test("rammer", game.lane, game.PLAYER_Y + 80)
	game._fire({})
	h.check("front gun never aims behind the car", game.bullets[-1]["vel"].y < 0)
	game.enemies.clear()
	key(KEY_X)
	h.eq("X drops a mine immediately", game.mine_drops, 1)
	key(KEY_X, false)
	key(KEY_ESCAPE)
	var time: float = game.game_time
	tick(1)
	h.near("pause freezes the world", game.game_time, time, 0.001)
	h.check("pause shows menu", game.pause_panel.visible)
	key(KEY_ESCAPE, false)
	key(KEY_ESCAPE)
	key(KEY_ESCAPE, false)
	h.check("escape resumes", not game.paused)
	key(KEY_T)
	h.check("only explicit T opens optional chat", game.box.visible)
	key(KEY_T, false)
	game._close_box()
	game.touch_enabled=true
	game._layout()
	for button in game.touch_controls:
		button.show()
	touch(0, game.touch_by_action["drive_mine"].position + game.touch_by_action["drive_mine"].size / 2, true)
	touch(1, game.touch_by_action["drive_fire"].position + game.touch_by_action["drive_fire"].size / 2, true)
	h.check("two fingers hold mine and fire together", game._held("drive_mine") and game._held("drive_fire"))
	touch(0, game.touch_by_action["drive_mine"].position + game.touch_by_action["drive_mine"].size / 2, false)
	h.check("releasing mine preserves second finger fire", not game._held("drive_mine") and game._held("drive_fire"))
	touch(1, game.touch_by_action["drive_fire"].position + game.touch_by_action["drive_fire"].size / 2, false)
	h.check("releasing all fingers clears held actions", not game._held("drive_fire"))
	game.hp = 60
	game.pickups.append({"kind": "repair", "pos": Vector2(game.car_x, game.car_y)})
	game._update_pickups(0)
	h.eq("actual overlap collects repair and removes it", game.pickups.size(), 0)
	h.near("repair restores health", game.hp, 78, 0.01)
	h.eq("collection counted", game.arcade.collected, 1)
	game._collect_pickup("shield")
	game.invulnerable = 0
	game._damage_player(35)
	h.near("shield absorbs one hit", game.hp, 78, 0.01)
	h.eq("shield is consumed", game.shield_left, 0.0)
	game.invulnerable = 0
	game._damage_player(10)
	h.near("following unshielded hit damages car", game.hp, 68, 0.01)
	h.eq("damage breaks score chain", game.arcade.chain, 0)
	game.enemies.clear()
	game.obstacles.clear()
	game.enemy_bullets.clear()
	game.mines.clear()
	game.distance = 250
	tick(0.1)
	h.eq("distance contract advances exactly once", game.arcade.contract, 1)
	var score: int = game.arcade.score
	game.distance = 1200
	tick(0.1)
	h.check("finish produces a survived outcome", game.over and game.end_result.get("outcome") == "survived")
	h.eq("finish bonus awarded once", game.arcade.score, score + 500)
	game._end_run("survived")
	h.eq("end is idempotent", game.arcade.score, score + 500)
	var saved: Dictionary = game.store.load_data()
	h.eq("best score survives save/load", saved["best_score"], game.arcade.score)
	var clean := SaveStore.new().sanitize({"trust": 55, "best_score": "broken", "settings": {"effects": "broken"}})
	h.eq("malformed score safely defaults", clean["best_score"], 0)
	h.eq("malformed effects preference safely defaults", clean["settings"]["effects"], true)
	var tally := Arcade.new()
	for i in range(3):
		tally.award(40)
	h.eq("fourth consecutive action doubles its reward", tally.award(40), 80)
	tally.tick(6)
	h.eq("idle timeout removes the multiplier", tally.award(40), 40)
	saved["settings"] = {"effects": false, "sound": false, "motion": false, "volume": 0.35}
	game.store.save_data(saved)
	h.check("sound and effects preferences round-trip", not game.store.load_data()["settings"]["sound"] and not game.store.load_data()["settings"]["effects"] and not game.store.load_data()["settings"]["motion"] and is_equal_approx(float(game.store.load_data()["settings"]["volume"]), 0.35))
	game.store.clear()
	quit(h.finish())
	return true
