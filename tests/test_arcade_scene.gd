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
	h.eq("left event steers immediately despite sulky MOMO", game.lane, 0)
	key(KEY_LEFT, false)
	key(KEY_RIGHT)
	h.eq("right event steers immediately", game.lane, 1)
	key(KEY_RIGHT, false)
	key(KEY_UP)
	tick(1)
	h.check("held up accelerates", game.speed > 300)
	h.check("turbo consumes energy", game.energy < 100)
	key(KEY_UP, false)
	key(KEY_DOWN)
	tick(2)
	h.near("held down brakes to minimum", game.speed, 140, 0.1)
	key(KEY_DOWN, false)
	key(KEY_SPACE)
	h.check("space fires with no text box", game.bullets.size() > 0 and not game.box.visible)
	key(KEY_SPACE, false)
	game.fire_cooldown = 0
	game._spawn_enemy_for_test("rammer", game.lane, game.PLAYER_Y + 80)
	game._fire({})
	h.check("direct fire can defend against a rear pursuer", game.bullets[-1]["vel"].y > 0)
	game.enemies.clear()
	key(KEY_X)
	h.eq("X drops a mine immediately", game.mines_left, 2)
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
	for button in game.touch_controls:
		button.show()
	touch(0, Vector2(48, 333), true)
	touch(1, Vector2(490, 333), true)
	h.check("two fingers hold turbo and fire together", game._held("drive_up") and game._held("drive_fire"))
	touch(0, Vector2(48, 333), false)
	h.check("releasing turbo preserves second finger fire", not game._held("drive_up") and game._held("drive_fire"))
	touch(1, Vector2(490, 333), false)
	h.check("releasing all fingers clears held actions", not game._held("drive_fire"))
	game.hp = 60
	game.pickups.append({"kind": "repair", "pos": Vector2(game.car_x, game.PLAYER_Y)})
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
	h.eq("sound and effects preferences round-trip", game.store.load_data()["settings"], saved["settings"])
	game.store.clear()
	quit(h.finish())
	return true
