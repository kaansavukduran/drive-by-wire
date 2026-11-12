extends SceneTree
const Pilot := preload("res://tests/autopilot.gd")
const Harness := preload("res://tests/harness.gd")
var h := Harness.new("full_run")
const SaveStore := preload("res://scripts/core/save_store.gd")
var game: Node2D
var step := 0
func _initialize() -> void:
 game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
 root.add_child(game)
 game.set_physics_process(false)
func _process(_delta: float) -> bool:
 step += 1
 if step < 2: return false
 game.store = SaveStore.new("user://test_full_run.json")
 game.store.clear()
 game.rng.seed = 42
 for i in range(120 * 60):
  if game.over: break
  if i % 600 < 120: Input.action_press("drive_boost")
  else: Input.action_release("drive_boost")
  Pilot.drive(game)
  game._simulate(1.0 / 60.0)
 print(JSON.stringify({"seed":42,"seconds":game.game_time,"distance":game.distance,"hp":game.hp,"kills":game.kills,"score":game.arcade.score,"contracts":game.arcade.contract,"collected":game.arcade.collected,"outcome":game.end_result.get("outcome","unfinished")}))
 h.check("seeded run reaches victory within two simulated minutes", game.over and game.end_result.get("outcome") == "survived")
 h.check("full run collects supplies and advances contracts", game.arcade.collected > 0 and game.arcade.contract >= 3)
 h.check("full run actually fights traffic", game.kills > 0 and game.arcade.score > 500)
 h.eq("complete run saves its score", game.store.load_data()["best_score"], game.arcade.score)
 game.store.clear()
 quit(h.finish())
 return true
