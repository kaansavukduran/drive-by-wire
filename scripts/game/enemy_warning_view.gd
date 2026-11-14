extends Node2D
## Vital attack feedback sits above vehicles and below the existing CanvasLayer UI.
## It observes simulation state only; no timers, randomness or collision changes.
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	var game: Node2D=get_parent()
	for warning in game._enemy_warnings():
		_draw_warning(warning)

func _draw_warning(warning: Dictionary) -> void:
	var amber := Color("ffd18a")
	var ink := Color("101622")
	var target: Vector2 = warning["target"]
	var origin: Vector2 = warning["origin"]
	match warning["kind"]:
		"rear":
			draw_colored_polygon(PackedVector2Array([target+Vector2(-9,8),target+Vector2(9,8),target+Vector2(0,-6)]),ink)
			draw_colored_polygon(PackedVector2Array([target+Vector2(-6,6),target+Vector2(6,6),target+Vector2(0,-3)]),amber)
		"shot":
			draw_dashed_line(origin,target,amber,1,6)
			draw_arc(target,9,0,TAU,16,ink,3)
			draw_arc(target,9,0,TAU,16,amber,1)
		"drop":
			draw_rect(Rect2(target-Vector2(10,10),Vector2(20,20)),ink,false,3)
			draw_rect(Rect2(target-Vector2(10,10),Vector2(20,20)),amber,false,1)
			draw_rect(Rect2(target+Vector2(-1,-6),Vector2(2,7)),amber)
			draw_rect(Rect2(target+Vector2(-1,3),Vector2(2,2)),amber)
		"ram":
			draw_dashed_line(origin,target,amber,1,4)
			draw_rect(Rect2(target-Vector2(3,3),Vector2(6,6)),amber,false,1)
	if warning["kind"] in ["shot","drop"]:
		var bar := Rect2(origin+Vector2(-12,-14),Vector2(24,4))
		draw_rect(bar,ink)
		bar.size.x=roundf(24*float(warning["progress"]))
		draw_rect(bar,amber)
