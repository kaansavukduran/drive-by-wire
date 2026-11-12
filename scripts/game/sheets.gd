extends RefCounted
## Reads assets/MANIFEST.json and draws sprite-sheet frames on any CanvasItem.
## anim time `t` is in seconds; non-looping animations hold their last frame.

var manifest: Dictionary = {}
var _tex: Dictionary = {}


func _init() -> void:
	var f := FileAccess.open("res://assets/MANIFEST.json", FileAccess.READ)
	if f:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			manifest = parsed


func sheet(name: String) -> Dictionary:
	return manifest.get("sheets", {}).get(name, {})


func image(name: String) -> Dictionary:
	return manifest.get("images", {}).get(name, {})


func texture(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load("res://" + path) if ResourceLoader.exists("res://" + path) else null
	return _tex[path]


func anim_length(name: String, anim: String) -> float:
	var a: Dictionary = sheet(name).get("animations", {}).get(anim, {})
	var fps := maxf(float(a.get("fps", 1)), 0.001)
	return (a.get("frames", [0]) as Array).size() / fps


func frame_at(name: String, anim: String, t: float, loop_override := -1) -> int:
	var a: Dictionary = sheet(name).get("animations", {}).get(anim, {})
	var frames: Array = a.get("frames", [0])
	if frames.is_empty():
		return 0
	var fps := float(a.get("fps", 0))
	var i := int(t * fps) if fps > 0.0 else 0
	var loop: bool = bool(a.get("loop", true)) if loop_override < 0 else loop_override == 1
	i = i % frames.size() if loop else mini(i, frames.size() - 1)
	return int(frames[i])


## Draws frame `index` of sheet `name` so that the sheet's anchor lands on `pos`.
func draw_frame(ci: CanvasItem, name: String, index: int, pos: Vector2, modulate := Color.WHITE, flip_h := false) -> bool:
	var s := sheet(name)
	var tex := texture(str(s.get("path", "")))
	if tex == null:
		return false
	var fw := float(s.get("frame_width", 16))
	var fh := float(s.get("frame_height", 16))
	var cols := int(s.get("columns", 1))
	var anchor: Array = s.get("anchor", [fw / 2, fh / 2])
	var src := Rect2((index % cols) * fw, (index / cols) * fh, fw, fh)
	var dst := Rect2((pos - Vector2(float(anchor[0]), float(anchor[1]))).round(), Vector2(fw, fh))
	if flip_h:
		dst.size.x = -dst.size.x  # Godot mirrors in place for a negative width
	ci.draw_texture_rect_region(tex, dst, src, modulate)
	return true


func draw_anim(ci: CanvasItem, name: String, anim: String, t: float, pos: Vector2, modulate := Color.WHITE, flip_h := false) -> bool:
	return draw_frame(ci, name, frame_at(name, anim, t), pos, modulate, flip_h)
