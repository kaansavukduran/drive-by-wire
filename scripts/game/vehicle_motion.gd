extends RefCounted
## Pure visual motion vocabulary for player vehicles.
## Never alters physics position, hitbox, combat RNG, or weapon/mine sockets.

const MAX_BANK_RAD := 0.085
const MAX_WHEEL_RAD := 0.24
const RECOIL_DECAY := 8.0
const MINE_FLASH_DECAY := 3.5

const PROFILES := {
	"roadster": {
		"roll": 1.0,
		"beam": Color(1.0, 0.90, 0.65, 0.16),
		"headlights": [Vector2(-11, -30), Vector2(11, -30)],
		"exhausts": [Vector2(-7, 32), Vector2(7, 32)],
		"wheels_front": [Vector2(-19, -18), Vector2(19, -18)],
		"wheels_rear": [Vector2(-19, 16), Vector2(19, 16)],
	},
	"courier": {
		"roll": 0.85,
		"beam": Color(1.0, 0.94, 0.78, 0.17),
		"headlights": [Vector2(-12, -31), Vector2(12, -31)],
		"exhausts": [Vector2(-9, 32), Vector2(9, 32)],
		"wheels_front": [Vector2(-19, -18), Vector2(19, -18)],
		"wheels_rear": [Vector2(-19, 17), Vector2(19, 17)],
	},
	"comet": {
		"roll": 1.15,
		"beam": Color(0.98, 0.78, 0.92, 0.16),
		"headlights": [Vector2(-10, -27), Vector2(10, -27)],
		"exhausts": [Vector2(0, 34)],
		"wheels_front": [Vector2(-18, -16), Vector2(18, -16)],
		"wheels_rear": [Vector2(-19, 16), Vector2(19, 16)],
	},
}

var steer_bank := 0.0
var wheel_angle := 0.0
var suspension_phase := 0.0
var recoil := 0.0
var mine_pulse := 0.0
var mine_ready_glow := 0.0
var hit_flash := 0.0
var damage_tier := 0
var state := "drive"
var last_mine_ready := true
var smoke_clock := 0.0
var smoke_puffs: Array[Dictionary] = []


func reset() -> void:
	steer_bank = 0.0
	wheel_angle = 0.0
	suspension_phase = 0.0
	recoil = 0.0
	mine_pulse = 0.0
	mine_ready_glow = 0.0
	hit_flash = 0.0
	damage_tier = 0
	state = "drive"
	last_mine_ready = true
	smoke_clock = 0.0
	smoke_puffs.clear()


func trigger_fire() -> void:
	recoil = 1.0


func trigger_mine() -> void:
	mine_pulse = 1.0
	last_mine_ready = false


func trigger_hit() -> void:
	hit_flash = 1.0


static func profile_for(vehicle_id: Variant) -> Dictionary:
	var key := str(vehicle_id)
	return PROFILES[key] if PROFILES.has(key) else PROFILES["roadster"]


func step(
	delta: float,
	velocity: Vector2,
	anim_name: String,
	hp: float,
	max_hp: float,
	mine_cooldown: float,
	over: bool,
	motion_enabled: bool,
	vehicle_id: Variant
) -> void:
	var dt := maxf(0.0, delta)
	var ratio := hp / maxf(max_hp, 1.0)
	if over and hp <= 0.0 or anim_name == "destroyed":
		damage_tier = 3
	elif ratio <= 0.25:
		damage_tier = 2
	elif ratio <= 0.5:
		damage_tier = 1
	else:
		damage_tier = 0

	var target_steer := clampf(velocity.x / 155.0, -1.0, 1.0)
	if absf(target_steer) < 0.05:
		if anim_name == "shift_left":
			target_steer = -0.8
		elif anim_name == "shift_right":
			target_steer = 0.8

	var profile := profile_for(vehicle_id)
	var roll_scale := float(profile["roll"])

	if motion_enabled and not (over and hp <= 0.0):
		steer_bank = move_toward(steer_bank, target_steer * MAX_BANK_RAD * roll_scale, dt * 1.1)
		wheel_angle = move_toward(wheel_angle, target_steer * MAX_WHEEL_RAD, dt * 3.2)
		suspension_phase = fposmod(suspension_phase + dt * 14.0, TAU)
	else:
		steer_bank = 0.0
		wheel_angle = 0.0

	recoil = maxf(0.0, recoil - dt * RECOIL_DECAY)
	mine_pulse = maxf(0.0, mine_pulse - dt * MINE_FLASH_DECAY)
	hit_flash = maxf(0.0, hit_flash - dt * 5.0)

	var mine_ready := mine_cooldown <= 0.0
	if mine_ready and not last_mine_ready and not over:
		mine_ready_glow = 1.0
	last_mine_ready = mine_ready
	mine_ready_glow = maxf(0.0, mine_ready_glow - dt * 2.5)

	if damage_tier == 3:
		state = "destroyed"
	elif hit_flash > 0.1:
		state = "hit"
	elif recoil > 0.2:
		state = "fire"
	elif absf(target_steer) > 0.2:
		state = "steer_left" if target_steer < 0.0 else "steer_right"
	elif damage_tier == 2:
		state = "critical"
	elif damage_tier == 1:
		state = "damaged"
	else:
		state = "drive"

	# Deterministic damage smoke plumes (never consumes gameplay RNG).
	if damage_tier >= 1 and motion_enabled:
		var interval := 0.24 if damage_tier == 1 else (0.13 if damage_tier == 2 else 0.16)
		smoke_clock += dt
		while smoke_clock >= interval:
			smoke_clock -= interval
			var idx := smoke_puffs.size()
			var jitter_x := sin(suspension_phase * 2.3 + float(idx) * 1.7) * 5.0
			smoke_puffs.append({
				"offset": Vector2(jitter_x, -10.0),
				"age": 0.0,
				"max_age": 0.55 if damage_tier < 3 else 0.75,
				"spark": damage_tier >= 2 and (int(suspension_phase * 10.0) % 3 == 0),
			})
	for puff in smoke_puffs:
		puff["age"] = float(puff["age"]) + dt
		puff["offset"] = (puff["offset"] as Vector2) + Vector2(0.0, 52.0 * dt)
	smoke_puffs = smoke_puffs.filter(func(p: Dictionary) -> bool: return float(p["age"]) < float(p["max_age"]))
	if smoke_puffs.size() > 14:
		smoke_puffs = smoke_puffs.slice(smoke_puffs.size() - 14)


func apply_to_sprite(car: Sprite2D, base_scale: Vector2, invulnerable: float, game_time: float, over: bool, dodge_left: float, motion_enabled: bool) -> void:
	if motion_enabled and damage_tier < 3:
		car.rotation = steer_bank
		var squash_y := 1.0 - recoil * 0.035 + sin(suspension_phase) * 0.008
		var squash_x := 1.0 + recoil * 0.025
		car.scale = Vector2(base_scale.x * squash_x, base_scale.y * squash_y)
	else:
		car.rotation = 0.0
		car.scale = base_scale

	car.visible = not (invulnerable > 0.0 and int(game_time * 20.0) % 2 == 0 and not over)
	if damage_tier == 3:
		car.modulate = Color(0.42, 0.40, 0.44, 1.0)
	elif hit_flash > 0.25:
		car.modulate = Color(1.35, 1.15, 1.15, 1.0)
	elif dodge_left > 0.0:
		car.modulate = Color(0.7, 0.9, 1.0, 0.75)
	else:
		car.modulate = Color.WHITE


func draw_underlay(canvas: CanvasItem, center: Vector2, vehicle_id: Variant, motion_enabled: bool, over: bool) -> void:
	var profile := profile_for(vehicle_id)
	# Two-layer grounded asphalt contact shadow (shifts subtly with lateral roll, never moves hitbox).
	var shadow_shift := Vector2(steer_bank * 28.0, 3.0)
	for layer in [[23.0, 36.0, 0.16], [19.5, 32.0, 0.34]]:
		var shadow_poly := PackedVector2Array()
		for i in 16:
			var a := float(i) * TAU / 16.0
			shadow_poly.append(center + shadow_shift + Vector2(cos(a) * float(layer[0]), sin(a) * float(layer[1])))
		canvas.draw_colored_polygon(shadow_poly, Color(0.02, 0.03, 0.05, float(layer[2])))

	if over and damage_tier == 3:
		return

	# Smoothly feathered headlamp beams ahead on the road surface (zero hard cutoff edge).
	var beam_color: Color = profile["beam"]
	var near_col := Color(beam_color.r, beam_color.g, beam_color.b, 0.24)
	var far_col := Color(beam_color.r, beam_color.g, beam_color.b, 0.0)
	for lamp in profile["headlights"]:
		var base: Vector2 = center + (lamp as Vector2).rotated(steer_bank if motion_enabled else 0.0)
		var spread := 11.0
		var reach := 54.0
		var poly := PackedVector2Array([
			base + Vector2(-2.5, 0),
			base + Vector2(2.5, 0),
			base + Vector2(spread, -reach),
			base + Vector2(-spread, -reach),
		])
		canvas.draw_polygon(poly, PackedColorArray([near_col, near_col, far_col, far_col]))

	# Steered front wheel tread projection visible when banking left/right.
	if motion_enabled and absf(wheel_angle) > 0.04:
		for wheel_pos in profile["wheels_front"]:
			var wp: Vector2 = center + (wheel_pos as Vector2).rotated(steer_bank)
			var dir := Vector2.UP.rotated(steer_bank + wheel_angle)
			var perp := Vector2(-dir.y, dir.x)
			var tire := PackedVector2Array([
				wp - dir * 7.0 - perp * 3.0,
				wp - dir * 7.0 + perp * 3.0,
				wp + dir * 7.0 + perp * 3.0,
				wp + dir * 7.0 - perp * 3.0,
			])
			canvas.draw_colored_polygon(tire, Color(0.09, 0.11, 0.14, 0.95))

	# Rear exhaust cadence pulses (purely cosmetic, scaled down in reduced motion).
	if motion_enabled:
		var pulse := 0.5 + 0.5 * sin(suspension_phase * 2.0)
		for pipe in profile["exhausts"]:
			var ep: Vector2 = center + (pipe as Vector2).rotated(steer_bank)
			canvas.draw_circle(ep + Vector2(0, 2.0 + pulse * 2.5), 2.2 + pulse * 1.1, Color(0.68, 0.78, 0.86, 0.24))

	# Rear mine-dispenser release glow and reload-ready ring at the exact rear socket (0, +30).
	var rear_socket := center + Vector2(0, 30)
	if mine_pulse > 0.02:
		var r := 6.0 + (1.0 - mine_pulse) * 10.0
		canvas.draw_arc(rear_socket, r, 0.0, TAU, 16, Color(1.0, 0.52, 0.28, mine_pulse * 0.85), 2.0)
	elif mine_ready_glow > 0.02:
		canvas.draw_arc(rear_socket, 8.0, 0.0, TAU, 16, Color(0.62, 0.88, 0.76, mine_ready_glow * 0.7), 1.5)


func draw_overlay(canvas: CanvasItem, center: Vector2, vehicle_id: Variant, motion_enabled: bool) -> void:
	# Recoil muzzle glow kick right at front weapon mount (0, -30).
	if recoil > 0.15:
		var muzzle := center + Vector2(0, -30)
		var glow := Color(0.55, 0.92, 1.0, recoil * 0.65)
		canvas.draw_circle(muzzle, 4.0 + recoil * 3.5, glow)

	# Progressive damage cues (readable even in reduced-motion via static indicator).
	if damage_tier >= 1 and not motion_enabled:
		var mark_color := Color(0.95, 0.65, 0.25, 0.85) if damage_tier == 1 else Color(0.95, 0.30, 0.25, 0.92)
		canvas.draw_arc(center + Vector2(0, -10), 6.0, 0.0, TAU, 12, mark_color, 1.5)

	for puff in smoke_puffs:
		var frac := clampf(float(puff["age"]) / maxf(float(puff["max_age"]), 0.01), 0.0, 1.0)
		var p: Vector2 = center + (puff["offset"] as Vector2)
		var r := lerpf(3.0, 8.5 if damage_tier >= 2 else 6.5, frac)
		var c := Color(0.18, 0.20, 0.25, (1.0 - frac) * (0.72 if damage_tier >= 2 else 0.48))
		canvas.draw_circle(p, r, c)
		if bool(puff["spark"]) and frac < 0.35:
			canvas.draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1.0, 0.82, 0.36, 1.0 - frac * 2.5))

	# Critical overheat hull warning rim.
	if damage_tier == 2:
		var flicker := 0.55 if not motion_enabled else (0.35 + 0.45 * absf(sin(suspension_phase * 1.5)))
		canvas.draw_arc(center, 22.0, 0.0, TAU, 20, Color(1.0, 0.32, 0.24, flicker), 1.5)


func snapshot() -> Dictionary:
	return {
		"state": state,
		"steer_bank": snappedf(steer_bank, 0.001),
		"wheel_angle": snappedf(wheel_angle, 0.001),
		"recoil": snappedf(recoil, 0.01),
		"mine_pulse": snappedf(mine_pulse, 0.01),
		"damage_tier": damage_tier,
		"smoke_count": smoke_puffs.size(),
	}
