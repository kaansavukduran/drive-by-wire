extends RefCounted
## Boss visual rendering: grounded shadow, telegraph barrel charge, firing recoil,
## open punish-window cooling vents, and Phase 2 reactor surge.
const Art=preload("res://scripts/game/visual_art.gd")
const FRAMES := {"entering":0,"telegraph":2,"firing":3,"recover":4,"phase_shift":5,"defeated":6}
const ACCENTS: Array[Color]=[Color("ffce70"),Color("79d4ff"),Color("f4a8c5")]

static func _ellipse(canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := i * TAU / 16.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	canvas.draw_colored_polygon(pts, color)

static func draw(canvas: CanvasItem, pivot: Vector2, kind: int, time: float = 0.0, flash: bool = false, scale_factor: float = 1.0, charging: bool = false, act_state: String = "recover", warning_progress: float = 0.0, fire_recoil: float = 0.0, phase: int = 1, phase_burst: float = 0.0, motion_enabled: bool = true) -> void:
	var accent: Color = ACCENTS[clampi(kind, 0, ACCENTS.size() - 1)]
	var hover := sin(time * 4.2) * 1.6 if motion_enabled else 0.0
	var recoil_y := -fire_recoil * 16.0 if motion_enabled else 0.0
	var visual_pivot := pivot + Vector2(0.0, hover + recoil_y)
	# Grounded asphalt shadow stays anchored under the chassis while body hovers/recoils.
	_ellipse(canvas, pivot + Vector2(0.0, 27.0 * scale_factor), Vector2(44.0, 11.0) * scale_factor, Color(0.03, 0.04, 0.07, 0.34))
	_ellipse(canvas, pivot + Vector2(0.0, 25.0 * scale_factor), Vector2(31.0, 7.0) * scale_factor, Color(0.02, 0.03, 0.05, 0.48))
	if phase >= 2:
		var heat_alpha := 0.24 + (0.10 * sin(time * 7.0) if motion_enabled else 0.04)
		canvas.draw_arc(visual_pivot, 44.0 * scale_factor, 0.0, TAU, 28, Color(accent.r, accent.g, accent.b, heat_alpha), 1.8)
	if phase_burst > 0.0:
		var burst_ratio := 1.0 - clampf(phase_burst / 0.75, 0.0, 1.0)
		var ring_r := (22.0 + burst_ratio * 26.0) * scale_factor if motion_enabled else 42.0 * scale_factor
		canvas.draw_arc(pivot, ring_r, 0.0, TAU, 32, Color(accent.r, accent.g, accent.b, clampf(phase_burst / 0.75, 0.0, 0.85)), 2.4)
	var frame := kind + (3 if charging else 0)
	var tint := Color(1.32, 1.32, 1.32) if flash else Color.WHITE
	Art.at(canvas, "robots", frame, visual_pivot, Vector2(100, 76) * scale_factor, tint)
	# Telegraph charge glow on twin front barrels synced with warning_progress.
	if charging or warning_progress > 0.0:
		var p := clampf(warning_progress, 0.2, 1.0)
		var muzzle_r := (3.5 + p * 5.0) * scale_factor
		for side in [-1.0, 1.0]:
			var muzzle := visual_pivot + Vector2(side * 19.0, 20.0) * scale_factor
			canvas.draw_circle(muzzle, muzzle_r * 1.45, Color(accent.r, accent.g, accent.b, 0.24 + p * 0.28))
			canvas.draw_circle(muzzle, muzzle_r * 0.72, Color(1.0, 0.96, 0.84, 0.55 + p * 0.4))
		canvas.draw_arc(visual_pivot + Vector2(0.0, 4.0 * scale_factor), (20.0 + (1.0 - p) * 14.0) * scale_factor, 0.0, TAU, 24, Color(accent.r, accent.g, accent.b, 0.35 + p * 0.45), 1.6)
	# Firing flash kick at muzzle exit.
	if fire_recoil > 0.14:
		var kick_alpha := clampf((fire_recoil - 0.14) / 0.14, 0.0, 1.0)
		for side in [-1.0, 1.0]:
			var muzzle := visual_pivot + Vector2(side * 19.0, 23.0) * scale_factor
			canvas.draw_circle(muzzle, 8.0 * scale_factor, Color(1.0, 0.92, 0.65, kick_alpha * 0.75))
	# Recover / punish window: exposed cool-down core glow + flanking steam vents.
	if act_state == "recover":
		var pulse := 0.55 + (0.2 * sin(time * 5.5) if motion_enabled else 0.0)
		canvas.draw_circle(visual_pivot + Vector2(0.0, 2.0 * scale_factor), 7.5 * scale_factor, Color(0.58, 0.92, 0.84, 0.26 * pulse))
		canvas.draw_arc(visual_pivot + Vector2(0.0, 2.0 * scale_factor), 9.0 * scale_factor, 0.0, TAU, 16, Color(0.62, 0.96, 0.86, 0.48 * pulse), 1.4)
		for side in [-1.0, 1.0]:
			var lift := fposmod(time * 18.0 + (0.5 if side > 0.0 else 0.0), 10.0) if motion_enabled else 4.0
			var vent := visual_pivot + Vector2(side * 24.0, -8.0 - lift) * scale_factor
			canvas.draw_circle(vent, 2.6 * scale_factor, Color(0.84, 0.94, 0.96, 0.28 * (1.0 - lift / 12.0)))

static func draw_encounter(canvas: CanvasItem, boss: RefCounted, motion: bool, clip_top: float) -> void:
	var scale_factor: float = boss.SCALE[boss.stage]
	if boss.stage > 1:
		draw(canvas, boss.position, boss.stage, boss.clock, boss.flash>0, scale_factor)
		return
	var position: Vector2 = boss.position
	var offset := Vector2.ZERO
	if motion:
		offset.y = sin(boss.clock*4.2)*1.6 + (1.0 if boss.rear else -1.0)*boss.fire_recoil*12.0
	var frame: int = FRAMES.get(boss.act_state,1)
	var shadow := Color(.02,.03,.05,.44)
	var extent := Vector2(100,76)*scale_factor
	var shadow_origin := position+Vector2(0,24)*scale_factor
	if shadow_origin.y-9.0*scale_factor>=clip_top:
		_ellipse(canvas,shadow_origin,Vector2(43,9)*scale_factor,shadow)
	var tint := Color(1.3,1.3,1.3) if boss.flash>0 else Color.WHITE
	var box := Rect2(position+offset-extent*.5,extent)
	if box.end.y<=clip_top:
		return
	var source := Art.region("boss_frames",boss.stage*7+frame)
	if boss.rear:
		box.size.y = -extent.y
	elif box.position.y<clip_top:
		var hidden := clip_top-box.position.y
		source.position.y+=source.size.y*hidden/extent.y
		source.size.y*=1.0-hidden/extent.y
		box.position.y=clip_top
		box.size.y-=hidden
	canvas.draw_texture_rect_region(Art.texture("boss_frames"),box,source,tint)
	if boss.vulnerable():
		canvas.draw_arc(position,12.0*scale_factor,0,TAU,16,Color("8cf0d3"),1.5)
	elif boss.warning_left>0:
		for i in 2:
			canvas.draw_circle(boss.muzzle(i),3.0+boss.warning_progress()*4.0,ACCENTS[boss.stage])
	if boss.phase_burst>0:
		canvas.draw_arc(position,40.0+12.0*(1.0-boss.phase_burst/.75),0,TAU,24,
			Color(ACCENTS[boss.stage],boss.phase_burst),2)
