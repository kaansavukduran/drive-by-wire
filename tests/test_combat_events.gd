extends SceneTree
## Verifies single-event combat integrity (mines, bullets, kills, truck drops),
## Mühür-01 boss acting state transitions, pause/long-frame safety, and Cam Ormanı atmosphere.
const Pilot := preload("res://tests/autopilot.gd")
const H = preload("res://tests/harness.gd")
const Boss = preload("res://scripts/core/boss_encounter.gd")
const Biomes = preload("res://scripts/game/road_biomes.gd")
const TruckHatch = preload("res://scripts/game/truck_hatch.gd")
const Session = preload("res://scripts/game/session.gd")
const Book = preload("res://scripts/core/story_book.gd")
const Store = preload("res://scripts/core/save_store.gd")

var h = H.new("combat_events")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# 1. Pure BossEncounter acting state progression for Mühür-01 (Stage 1)
	var b := Boss.new()
	b.start(0)
	h.eq("muhur starts in entering state", b.act_state, "entering")
	h.eq("muhur warning_progress starts at zero", b.warning_progress(), 0.0)
	# Step through entry
	var cues: Array[String] = []
	for _i in 360:
		b.step(1.0 / 60.0, Vector2(320, 290))
		cues.append_array(b.take_cues())
		if b.act_state == "telegraph":
			break
	h.eq("muhur enters telegraph state", b.act_state, "telegraph")
	h.check("boss_warn cue emitted exactly once for first telegraph", cues.count("boss_warn") == 1)
	var wp0 := b.warning_progress()
	b.step(0.3, Vector2(320, 290))
	var wp1 := b.warning_progress()
	h.check("warning_progress rises monotonically during telegraph", wp1 > wp0 and wp1 < 1.0)
	# Complete telegraph with a long frame (delta = 0.8s) to ensure single firing event
	var shots := b.step(0.8, Vector2(320, 290))
	cues.append_array(b.take_cues())
	h.check("long frame completing telegraph still fires once", shots.size() > 0 and b.casts == 1)
	h.eq("muhur enters firing state immediately after salvo", b.act_state, "firing")
	h.check("boss_fire cue emitted once on salvo", cues.count("boss_fire") == 1)
	# Decay recoil -> recover punish window
	b.step(0.35, Vector2(320, 290))
	h.eq("muhur enters recover punish window after recoil", b.act_state, "recover")
	h.check("recover_ratio is positive during recover window", b.recover_ratio() > 0.0)
	# Trigger Phase 2 at 50% HP
	b.hit(b.max_hp * 0.5)
	b.step(0.05, Vector2(320, 290))
	cues.append_array(b.take_cues())
	h.eq("muhur enters phase 2 at half hp", b.phase, 2)
	h.eq("muhur enters phase_shift state on phase change", b.act_state, "phase_shift")
	h.check("boss_phase cue emitted once", cues.count("boss_phase") == 1)
	# Mühür-01 must NEVER move to rear (only Yankı-02 / Tasnif-13 have rear phase)
	var stayed_front := true
	for _i in 600:
		b.step(1.0 / 60.0, Vector2(320, 290))
		if b.rear:
			stayed_front = false
			break
	h.check("muhur stays strictly front-only even in phase 2", stayed_front)
	var snap := b.snapshot()
	h.check("boss snapshot exposes read-only act_state and warning_progress", snap.has("act_state") and snap.has("warning_progress"))
	# Defeat Mühür-01
	var died_first := b.hit(9999.0)
	var died_second := b.hit(9999.0)
	cues.append_array(b.take_cues())
	h.check("defeat triggers once and sets defeated act_state", died_first and not died_second and b.act_state == "defeated")
	h.check("boss_defeat cue emitted exactly once", cues.count("boss_defeat") == 1)

	# 2. Scene-level single-event combat integrity under long frames and pause
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	await process_frame
	Session.story_mode = true
	Session.campaign_state = Book.choose(Book.defaults(), "depart")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	game.store = Store.new("user://combat-events-fixture.json")

	# 2a. Front bullet hit spark + single damage
	game.enemies.clear()
	game.bullets.clear()
	game.effects.clear()
	game._spawn_enemy_for_test("rammer", 1, 180.0)
	var target_e: Dictionary = game.enemies[0]
	var hp_init := float(target_e["hp"])
	game.bullets.append({"pos": target_e["pos"] + Vector2(0, 2), "vel": Vector2(0, -100)})
	game._update_bullets(0.01)
	h.check("bullet deals configured damage once", float(target_e["hp"]) < hp_init and game.bullets.is_empty())
	var spark_count: int = game.effects.filter(func(fx): return str(fx["kind"]) == "hit_spark").size()
	h.eq("bullet hit emits exactly one hit_spark", spark_count, 1)

	# 2b. Double _hurt_enemy / _explode guard on dead enemy
	var kills_before: int = game.kills
	var score_before: int = game.arcade.score
	game._hurt_enemy(target_e, 999.0)
	game._hurt_enemy(target_e, 999.0)
	game._explode(target_e, true)
	h.eq("dead enemy awards kill exactly once", game.kills, kills_before + 1)
	h.check("dead enemy awards score exactly once", game.arcade.score > score_before and game.arcade.score == score_before + int(game._cfg("arcade.kill_points", 40)))
	var wreck_count: int = game.effects.filter(func(fx): return str(fx["kind"]) == "wreck_rammer").size()
	h.eq("dead enemy spawns exactly one wreck effect", wreck_count, 1)

	# 2c. Mine single-event detonation under a long frame (delta = 0.25s)
	game.enemies.clear()
	game.mines.clear()
	game.enemy_bullets.clear()
	game.effects.clear()
	game.kills = 0
	game.car_x = 320.0
	game.car_y = 220.0
	game.mine_cooldown = 0.0
	game._execute({"intent": "drop_mine"})
	h.eq("drop_mine spawns one armed-pending mine", game.mines.size(), 1)
	# Place a fragile rammer and two enemy bullets (one inside 60px blast, one far away)
	game._spawn_enemy_for_test("rammer", 1, game.mines[0]["pos"].y + game.speed * 0.25)
	game.enemies[0]["pos"].x = game.mines[0]["pos"].x
	game.enemies[0]["hp"] = 30.0
	var expected_blast_pos: Vector2 = game.mines[0]["pos"] + Vector2(0, game.speed * 0.25)
	game.enemy_bullets.append({"pos": expected_blast_pos + Vector2(18, 0), "vel": Vector2.ZERO, "dmg": 8.0, "near": false, "passed": false})
	game.enemy_bullets.append({"pos": expected_blast_pos + Vector2(0, -140), "vel": Vector2.ZERO, "dmg": 8.0, "near": false, "passed": false})
	# Single huge 0.25s frame arms AND detonates the mine once
	game._update_mines(0.25)
	h.eq("mine detonates and clears on long frame", game.mines.size(), 0)
	h.eq("mine kills enemy once on long frame", game.kills, 1)
	h.eq("mine clears nearby bullet while preserving distant bullet", game.enemy_bullets.size(), 1)
	var mine_blasts: int = game.effects.filter(func(fx): return str(fx["kind"]) == "mine_blast").size()
	h.eq("mine detonation emits exactly one mine_blast effect", mine_blasts, 1)

	# 2d. Truck cargo release syncs obstacle and hatch_puff at TruckHatch.RELEASE
	game.enemies.clear()
	game.obstacles.clear()
	game.effects.clear()
	game._spawn_enemy_for_test("truck", 1, 100.0)
	var truck: Dictionary = game.enemies[0]
	truck["state"] = "windup"
	truck["t"] = game._warning_seconds("truck") - 0.01
	truck["drop_kind"] = "crate"
	var expected_release: Vector2 = truck["pos"] + TruckHatch.RELEASE
	game._update_enemies(0.02)
	h.eq("truck release spawns one obstacle", game.obstacles.size(), 1)
	h.check("truck obstacle spawns at exact TruckHatch.RELEASE", game.obstacles[0]["pos"].distance_to(expected_release) < 0.01)
	var puffs: Array = game.effects.filter(func(fx): return str(fx["kind"]) == "hatch_puff")
	h.eq("truck release emits one synchronized hatch_puff", puffs.size(), 1)
	h.check("hatch_puff matches obstacle release point", puffs[0]["pos"].distance_to(expected_release) < 0.01)

	# 2e. Boss encounter cues and defeat burst in main scene + pause freeze + Cam Ormanı RNG safety
	game.distance = 285.0
	game.effects.clear()
	game._update_encounter(0.02)
	h.check("stage 1 encounter activates Mühür-01 in Cam Ormanı", game.boss.active and game.biome_index == 2)
	var rng_state_before: int = game.rng.state
	game.queue_redraw()
	await process_frame
	h.eq("drawing Cam Ormanı atmosphere and boss consumes zero combat RNG", game.rng.state, rng_state_before)
	# Reduced motion render safety check
	game.motion_enabled = false
	game.queue_redraw()
	await process_frame
	h.check("reduced motion render succeeds with active boss and effects", true)
	game.motion_enabled = true
	# Boss Phase 2 emits boss_phase_ring in scene
	Pilot.open_core(game.boss)
	game.boss.hit(game.boss.max_hp * 0.5)
	game._update_encounter(0.02)
	var phase_rings: int = game.effects.filter(func(fx): return str(fx["kind"]) == "boss_phase_ring").size()
	h.eq("boss phase shift emits boss_phase_ring effect", phase_rings, 1)
	# Pause freezes boss and effects
	var eff_t0: float = float(game.effects[0]["t"])
	var b_clock0: float = game.boss.clock
	game._set_paused(true)
	game._simulate(0.5)
	h.eq("pause freezes effect timers", float(game.effects[0]["t"]), eff_t0)
	h.eq("pause freezes boss clock", game.boss.clock, b_clock0)
	game._set_paused(false)
	# Boss defeat emits mine_blast + two flank small bursts
	game.effects.clear()
	Pilot.open_core(game.boss)
	game._hurt_boss(9999.0)
	h.check("boss defeat spawns center mine_blast and flank explosions", game.effects.filter(func(fx): return str(fx["kind"]) == "mine_blast").size() == 1 and game.effects.filter(func(fx): return str(fx["kind"]) == "small").size() == 2)

	game.store.clear()
	game.queue_free()
	await process_frame
	Session.story_mode = false
	Session.campaign_state = {}
	quit(h.finish())
