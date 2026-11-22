extends SceneTree
const H := preload("res://tests/harness.gd")
const Store := preload("res://scripts/core/save_store.gd")
const Session := preload("res://scripts/game/session.gd")
const VehicleMotion := preload("res://scripts/game/vehicle_motion.gd")
var h := H.new("vehicle_motion")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	Session.story_mode = false
	Session.campaign_state = {}
	var game: Node2D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	game.store = Store.new("user://vehicle-motion-test.json")
	game.spawn_timer = 99999
	game.pickup_timer = 99999
	game.motion_enabled = true

	var overlay: Node2D = game.get_node_or_null("VehicleOverlay")
	var warnings: Node2D = game.get_node_or_null("EnemyWarnings")
	h.check("vehicle overlay exists above car and below enemy warnings", overlay != null and warnings != null and overlay.z_index < warnings.z_index and overlay.get_index() > game.car.get_index())

	for vid in game.Vehicles.IDS:
		game.save["vehicle"] = vid
		game.vehicle_motion.reset()
		game.hp = game.max_hp
		game.over = false
		game.anim = "drive"
		game.anim_t = 0.0
		game.car_x = 320.0
		game.car_y = 220.0
		game.car.position = Vector2(320, 220)
		game.drive_velocity = Vector2.ZERO
		game._animate(0.05)
		var base_offset: Vector2 = game.car.offset
		var rng_before: int = game.rng.state

		# Right steering banks chassis and angles front wheels without shifting hitbox or pivot.
		game.drive_velocity = Vector2(155.0, 0.0)
		for i in 12:
			game._animate(1.0 / 60.0)
		h.check("right steering banks chassis positively " + vid, game.vehicle_motion.steer_bank > 0.02 and game.car.rotation > 0.02)
		h.check("right steering turns front wheels right " + vid, game.vehicle_motion.wheel_angle > 0.05)
		h.eq("steering keeps sprite pivot fixed " + vid, game.car.offset, base_offset)
		h.eq("steering keeps sprite centered on physical hitbox " + vid, game.car.position, game._player_rect().get_center())
		var actual: Rect2 = game.car.get_global_transform() * game.car.get_rect()
		h.check("banked chassis still encloses hitbox " + vid, actual.encloses(game.get_global_transform() * game._player_rect()))

		# Left steering reverses bank and wheel angle cleanly.
		game.drive_velocity = Vector2(-155.0, 0.0)
		for i in 24:
			game._animate(1.0 / 60.0)
		h.check("left steering banks chassis negatively " + vid, game.vehicle_motion.steer_bank < -0.02 and game.car.rotation < -0.02)
		h.check("left steering turns front wheels left " + vid, game.vehicle_motion.wheel_angle < -0.05)

		# Firing triggers recoil while maintaining steering and exact muzzle anchor.
		game.fire_cooldown = 0.0
		game.bullets.clear()
		game._fire({})
		game._animate(1.0 / 60.0)
		h.check("firing sets recoil state without losing bank " + vid, game.vehicle_motion.recoil > 0.5 and game.car.rotation < -0.02)
		h.eq("bullet still spawns at exact front muzzle " + vid, game.bullets[-1]["pos"], Vector2(game.car_x, game.car_y - 30.0))

		# Rear mine triggers rear bay pulse at exact rear socket.
		game.mine_cooldown = 0.0
		game.mines.clear()
		game._execute({"intent": "drop_mine"})
		game._animate(1.0 / 60.0)
		h.check("rear mine sets dispenser pulse " + vid, game.vehicle_motion.mine_pulse > 0.5)
		h.eq("mine still spawns at exact rear socket " + vid, game.mines[-1]["pos"], Vector2(game.car_x, game.car_y + 30.0))

		# Progressive damage tiers produce distinct damage states and deterministic smoke.
		game.hp = game.max_hp * 0.45
		for i in 20:
			game._animate(1.0 / 60.0)
		h.eq("sub-50% HP enters damaged tier " + vid, game.vehicle_motion.damage_tier, 1)
		h.check("damaged tier emits smoke puffs " + vid, game.vehicle_motion.smoke_puffs.size() > 0)

		game.hp = game.max_hp * 0.20
		for i in 20:
			game._animate(1.0 / 60.0)
		h.eq("sub-25% HP enters critical tier " + vid, game.vehicle_motion.damage_tier, 2)

		# Destroyed state zeroes bank and darkens chassis.
		game.hp = 0.0
		game.over = true
		game.anim = "destroyed"
		game._animate(1.0 / 60.0)
		h.eq("destroyed state enters tier 3 " + vid, game.vehicle_motion.damage_tier, 3)
		h.eq("destroyed state clears chassis bank " + vid, game.car.rotation, 0.0)
		h.eq("vehicle motion never consumes combat RNG " + vid, game.rng.state, rng_before)

	# Reduced motion clears decorative bank/tilt while preserving essential damage tier.
	game.over = false
	game.anim = "drive"
	game.hp = game.max_hp * 0.2
	game.drive_velocity = Vector2(155.0, 0.0)
	game.motion_enabled = false
	game._animate(0.1)
	h.eq("reduced motion zeroes decorative rotation", game.car.rotation, 0.0)
	h.eq("reduced motion preserves critical damage tier", game.vehicle_motion.damage_tier, 2)

	# Pause stops _animate progression when _process runs.
	game.motion_enabled = true
	game._set_paused(true)
	var snap_before: Dictionary = game.vehicle_motion.snapshot()
	game._process(0.5)
	h.eq("pause freezes vehicle motion state", game.vehicle_motion.snapshot(), snap_before)

	game.store.clear()
	game.queue_free()
	await process_frame
	quit(h.finish())
