extends RefCounted
## Hands garage choices to the next run within one game session (not saved:
## dialogue effects are for the next run only; trust and memory live in the save).

static var next_run_modifiers: Array = []
static var came_from_run := false

static var next_route := "steady"
