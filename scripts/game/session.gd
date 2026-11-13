extends RefCounted
## Hands garage choices to the next run within one game session (not saved:
## dialogue effects are for the next run only; trust and memory live in the save).

static var next_run_modifiers: Array = []
static var came_from_run := false

static var next_route := "steady"

static var story_mode := false
static var campaign_state: Dictionary = {}
static var campaign_save_failed := false
static var view_ending := ""

static func play_scene() -> String:
 return "res://scenes/road_story.tscn" if story_mode and int(campaign_state.get("stage",0))==1 else "res://scenes/main.tscn"
