extends Control
## MOMO'nun küçük CRT yüzü. Ruh haline göre göz/ağız; konuşurken ağız oynar.
## Çizim kodda; assets/ altında MOMO yüz sheet'i gelince bu düğüm onu kullanacak.

var mood := "calm"
var talking := 0.0
var hurt := 0.0
var confused := 0.0
var _t := 0.0

const SCREEN := Color("10202a")
const GLOW := {"calm": Color("7fe7ff"), "scared": Color("b8c4ff"), "excited": Color("ffd84a"), "sulky": Color("ff8fb1")}


func _ready() -> void:
	custom_minimum_size = Vector2(48, 44)
	size = Vector2(48, 44)


func _process(delta: float) -> void:
	_t += delta / maxf(Engine.time_scale, 0.01)
	talking = maxf(0.0, talking - delta / maxf(Engine.time_scale, 0.01))
	hurt = maxf(0.0, hurt - delta / maxf(Engine.time_scale, 0.01))
	confused = maxf(0.0, confused - delta / maxf(Engine.time_scale, 0.01))
	queue_redraw()


func px(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, y, w, h), c)


const Sheets := preload("res://scripts/game/sheets.gd")
static var _sheets: RefCounted


func _draw() -> void:
	if _sheets == null:
		_sheets = Sheets.new()
	if not _sheets.sheet("momo_face").is_empty():
		var anim := mood + ("_talk" if talking > 0.0 else "_idle")
		if hurt > 0.0:
			anim = "hurt"
		elif confused > 0.0:
			anim = "confused_talk" if talking > 0.0 else "confused_idle"
		if _sheets.draw_anim(self, "momo_face", anim, _t, Vector2.ZERO):
			var bezel: Texture2D = _sheets.texture("assets/ui/momo_bezel.png")
			if bezel:
				draw_texture(bezel, Vector2.ZERO)
			return
	_draw_code_face()


func _draw_code_face() -> void:
	# casing and screen
	px(0, 0, 48, 44, Color("101018"))
	px(1, 1, 46, 42, Color("4a4f63"))
	px(2, 2, 44, 3, Color("6b7190"))
	px(4, 5, 40, 32, Color("101018"))
	px(5, 6, 38, 30, SCREEN if hurt <= 0.0 else Color("5a1a24"))
	px(20, 38, 8, 3, Color("2a2c3a"))
	px(40, 39, 3, 2, Color("7fe7ff") if int(_t * 2) % 2 == 0 else Color("2a6a7a"))
	var g: Color = GLOW.get(mood, GLOW["calm"])
	if hurt > 0.0:
		g = Color("ff5a5a")
	# scanline flicker
	for y in range(7, 36, 3):
		px(5, y, 38, 1, Color(1, 1, 1, 0.04))
	var blink := fmod(_t, 3.2) > 3.05
	var bob := 1.0 if int(_t * 3) % 2 == 0 and mood == "excited" else 0.0
	var shiver := (1.0 if int(_t * 18) % 2 == 0 else -1.0) if mood == "scared" else 0.0
	var ex := 14.0 + shiver
	var ey := 14.0 - bob
	if confused > 0.0:
		_eye_ring(ex, ey, g)
		px(30 + shiver, ey + 2, 6, 2, g)
		px(20, 27, 3, 2, g); px(24, 28, 3, 2, g); px(28, 27, 3, 2, g)
		px(38, 8, 2, 2, g); px(39, 6, 2, 2, g)  # little "?" spark
		return
	match mood:
		"scared":
			if blink:
				px(ex, ey + 3, 6, 1, g); px(ex + 14, ey + 3, 6, 1, g)
			else:
				px(ex + 1, ey, 4, 6, g); px(ex + 15, ey, 4, 6, g)
				px(ex + 2, ey + 1, 2, 2, SCREEN); px(ex + 16, ey + 1, 2, 2, SCREEN)
			px(ex - 1, ey - 3, 6, 1, g); px(ex + 15, ey - 3, 6, 1, g)  # worried brows
			_mouth(19 + shiver, 27, g, "wobble")
		"excited":
			# ^ ^ eyes
			px(ex, ey + 3, 2, 2, g); px(ex + 2, ey + 1, 2, 2, g); px(ex + 4, ey + 3, 2, 2, g)
			px(ex + 14, ey + 3, 2, 2, g); px(ex + 16, ey + 1, 2, 2, g); px(ex + 18, ey + 3, 2, 2, g)
			px(9, 21, 4, 2, Color("ff8fb1")); px(35, 21, 4, 2, Color("ff8fb1"))
			_mouth(18, 26 - bob, g, "big")
		"sulky":
			if blink:
				px(ex, ey + 3, 6, 1, g); px(ex + 14, ey + 3, 6, 1, g)
			else:
				px(ex, ey + 2, 6, 3, g); px(ex + 14, ey + 2, 6, 3, g)
				px(ex, ey + 2, 6, 1, SCREEN); px(ex + 14, ey + 2, 6, 1, SCREEN)
			px(ex, ey - 1, 6, 1, g); px(ex + 15, ey - 2, 5, 1, g)
			_mouth(20, 28, g, "pout")
		_:
			if blink:
				px(ex, ey + 3, 6, 1, g); px(ex + 14, ey + 3, 6, 1, g)
			else:
				px(ex + 1, ey, 4, 6, g); px(ex + 15, ey, 4, 6, g)
				px(ex + 2, ey + 1, 1, 1, Color.WHITE); px(ex + 16, ey + 1, 1, 1, Color.WHITE)
			_mouth(19, 27, g, "smile")


func _eye_ring(ex: float, ey: float, g: Color) -> void:
	px(ex, ey, 6, 6, g)
	px(ex + 1, ey + 1, 4, 4, SCREEN)
	px(ex + 2, ey + 2, 2, 2, g)


func _mouth(x: float, y: float, g: Color, kind: String) -> void:
	var open := talking > 0.0 and int(_t * 10) % 2 == 0
	match kind:
		"big":
			px(x, y, 12, 2, g)
			px(x + 1, y + 2, 10, 2 if not open else 4, g)
			px(x + 3, y + 2, 6, 1, SCREEN)
		"pout":
			px(x + 1, y, 6, 1, g)
			px(x, y + 1, 2, 1, g); px(x + 6, y + 1, 2, 1, g)
			if open:
				px(x + 2, y + 1, 4, 2, g)
		"wobble":
			for i in range(5):
				px(x + i * 2, y + (i % 2), 2, 1, g)
			if open:
				px(x + 2, y + 2, 6, 2, g)
		_:
			px(x, y, 2, 1, g); px(x + 8, y, 2, 1, g)
			px(x + 2, y + 1, 6, 1, g)
			if open:
				px(x + 3, y + 2, 4, 2, g)
