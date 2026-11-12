extends Node
## Select a readable Godot content size; no replacement renderer or input framework.
var _queued := false
func _ready() -> void:
	get_tree().root.size_changed.connect(_queue_fit)
	_fit()
func _queue_fit() -> void:
	if not _queued:
		_queued = true
		call_deferred("_fit")
func _fit() -> void:
	_queued = false
	var window := get_tree().root
	window.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	var portrait := window.size.y > window.size.x
	var target := Vector2i(360,640) if portrait else Vector2i(640,360)
	if window.content_scale_size != target:
		window.content_scale_size = target
