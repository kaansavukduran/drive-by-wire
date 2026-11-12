extends RefCounted
## One horizontal swipe = one lane. The owner must start inside the road.
const THRESHOLD := 30.0
const DOMINANCE := 1.35
var owner := -1
var start := Vector2.ZERO
var committed := false
func clear() -> void:
	owner = -1
	committed = false
func touch(index: int, point: Vector2, pressed: bool, area: Rect2, canceled := false) -> void:
	if canceled or not pressed:
		if index == owner: clear()
	elif owner == -1 and area.has_point(point):
		owner = index
		start = point
		committed = false
func drag(index: int, point: Vector2) -> int:
	if index != owner or committed: return 0
	var delta := point - start
	if absf(delta.y) >= THRESHOLD and absf(delta.y) > absf(delta.x)*DOMINANCE:
		committed = true
		return 0
	if absf(delta.x) >= THRESHOLD and absf(delta.x) > absf(delta.y)*DOMINANCE:
		committed = true
		return 1 if delta.x > 0 else -1
	return 0
