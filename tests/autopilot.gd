extends RefCounted
## Deterministic test driver: real steering interpolation, ammo and dodge cooldowns.
## No teleport, health override, time skip or scene setters from browser QA.
static func drive(game: Node) -> void:
	game._fire({})
	if game.comfort_cooldown<=0: game._direct_action("drive_comfort")
	var best: int=game.lane
	var best_cost:=INF
	for candidate in 3:
		var cost:=absf(game._lane_x(candidate)-game.car_x)*0.04
		for enemy in game.enemies:
			var gap: float=absf(enemy["pos"].y-game.car_y)
			if int(enemy["lane"])==candidate and gap<165: cost+=(165-gap)*2.0
		for obstacle in game.obstacles:
			if game._lane_of(obstacle["pos"].x)==candidate and absf(obstacle["pos"].y-game.car_y)<150: cost+=250.0
		for pickup in game.pickups:
			if game._lane_of(pickup["pos"].x)==candidate and pickup["pos"].y>130 and pickup["pos"].y<game.car_y: cost-=30.0
		if cost<best_cost:
			best_cost=cost
			best=candidate
	for enemy in game.enemies:
		var gap: float=enemy["pos"].y-game.car_y
		if absf(enemy["pos"].x-game.car_x)<24 and gap>25 and gap<140 and game.mines_left>0:
			if game.mines.is_empty(): game._execute({"intent":"drop_mine"})
		if absf(enemy["pos"].x-game.car_x)<28 and absf(gap)<65 and game.dodge_cooldown<=0:
			game._direct_action("drive_dodge")
	game._change_lane(best)
