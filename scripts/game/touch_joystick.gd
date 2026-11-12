extends Control
const UiSkin := preload("res://scripts/game/ui_skin.gd")
## Fixed origin, one owning finger, and a radial dead zone. CanvasLayer coordinates.
var value := Vector2.ZERO
var pointer := -1
var enabled := false
var deadzone := 0.13

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func fit(rect: Rect2) -> void:
	reset()
	position=rect.position.round()
	size=rect.size.round()
	queue_redraw()

func reset() -> void:
	pointer=-1
	value=Vector2.ZERO
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not enabled: return
	if event is InputEventScreenTouch:
		if event.index==pointer and (not event.pressed or event.canceled):
			reset()
		elif event.pressed and pointer==-1 and get_global_rect().has_point(event.position):
			pointer=event.index
			_update_value(event.position)
	elif event is InputEventScreenDrag and event.index==pointer:
		_update_value(event.position)

func _update_value(point: Vector2) -> void:
	var radius := minf(size.x,size.y)/2.0-10.0
	var delta := (point-get_global_rect().get_center())/maxf(radius,1.0)
	var strength := clampf((delta.length()-deadzone)/(1.0-deadzone),0,1)
	value=delta.normalized()*strength if strength>0 else Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	var center := size/2.0
	var radius := minf(size.x,size.y)/2.0-10.0
	var ring := PackedVector2Array()
	for i in 9:
		var angle := TAU*i/8.0
		ring.append((center+Vector2(cos(angle),sin(angle))*radius).round())
	var surface:=UiSkin.color("surface")
	surface.a=0.9
	draw_colored_polygon(ring,surface)
	draw_polyline(ring,UiSkin.color("accent"),2,false)
	for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		draw_line(center+direction*(radius-8),center+direction*(radius-2),UiSkin.color("muted"),2,false)
	var knob := (center+value*radius*0.65).round()
	draw_rect(Rect2(knob-Vector2(13,13),Vector2(26,26)),UiSkin.color("hover" if value.length()>0 else "control"))
	draw_rect(Rect2(knob-Vector2(13,13),Vector2(26,26)),UiSkin.color("accent"),false,2)
