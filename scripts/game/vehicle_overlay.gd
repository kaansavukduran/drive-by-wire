extends Node2D
## Draws above the player Sprite2D and strictly below EnemyWarnings (z_index 1).
## Observes VehicleMotion state only; never modifies physics or gameplay RNG.
func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var game: Node2D = get_parent()
	if game == null or game.get("vehicle_motion") == null:
		return
	game.vehicle_motion.draw_overlay(self, Vector2(game.car_x, game.car_y), game.save.get("vehicle"), game.motion_enabled)
