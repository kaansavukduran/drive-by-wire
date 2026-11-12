extends RefCounted
## Per-run score and short contracts. No scene, input, save or global RNG access.

var cfg: Dictionary
var score := 0
var chain := 0
var best_chain := 0
var chain_left := 0.0
var collected := 0
var near_misses := 0
var contract := 0
var contract_start := 0.0
var contract_kills := 0
var contract_pickups := 0

func _init(config: Dictionary = {}) -> void:
	cfg = config

func tick(delta: float) -> void:
	chain_left = maxf(0.0, chain_left - delta)
	if chain_left <= 0.0:
		chain = 0

func award(base: int) -> int:
	chain += 1
	best_chain = maxi(best_chain, chain)
	chain_left = float(cfg.get("chain_seconds", 5.0))
	var multiplier := mini(1 + int((chain - 1) / 3), int(cfg.get("max_multiplier", 4)))
	var points := base * multiplier
	score += points
	return points

func break_chain() -> void:
	chain = 0
	chain_left = 0.0

func contract_progress(distance: float, kills: int) -> Vector2:
	match contract % 3:
		0: return Vector2(distance - contract_start, float(cfg.get("contract_distance", 250)))
		1: return Vector2(kills - contract_kills, float(cfg.get("contract_kills", 3)))
		_: return Vector2(collected - contract_pickups, float(cfg.get("contract_pickups", 3)))

func contract_title() -> String:
	return ["Yolu aç · mesafe", "Takibi kır · düşman", "İkmal yap · kapsül"][contract % 3]

func complete_contract(distance: float, kills: int) -> bool:
	var progress := contract_progress(distance, kills)
	if progress.x < progress.y:
		return false
	score += int(cfg.get("contract_reward", 200))
	contract += 1
	contract_start = distance
	contract_kills = kills
	contract_pickups = collected
	return true
