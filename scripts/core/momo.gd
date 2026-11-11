extends RefCounted
## MOMO, the car's fragile digital-pet AI. Pure logic: holds trust (0..100,
## persistent) and mood (in-run), reacts to events, interprets parsed commands.
## All numbers come from data/balance.json "momo"; lines from data/momo_lines.json.
## Randomness only through a caller-provided RandomNumberGenerator.

const DataLoader := preload("res://scripts/core/data_loader.gd")

const SCARED := "scared"
const CALM := "calm"
const EXCITED := "excited"
const SULKY := "sulky"
const MOODS: PackedStringArray = [SCARED, CALM, EXCITED, SULKY]
const MOOD_NAMES_TR := {SCARED: "korkmuş", CALM: "sakin", EXCITED: "heyecanlı", SULKY: "küskün"}

## Interpret actions.
const ACTION_EXECUTE := "execute"
const ACTION_DELAY := "delay"
const ACTION_REFUSE := "refuse"
const ACTION_NONE := "none"  # comfort / insult / unknown: nothing for the car to do

const EVENT_TYPES: PackedStringArray = [
	"damage", "near_miss", "insult", "comfort", "praise", "contradictory",
	"manoeuvre_success", "kill", "unknown_command",
]

var trust: float = 50.0
var mood: String = CALM
var cfg: Dictionary = {}
var lines: Dictionary = {}

var run_start_trust: float = 50.0
var comfort_gain_this_run: float = 0.0
## Counters for the current run, also returned by end_run().
var run_stats: Dictionary = {}

var _near_misses: int = 0
var _successes: int = 0
var _kills: int = 0
var _contradictions: int = 0
var _excited_commands: int = 0
var _last_move_intent: String = ""
var _last_move_time: float = -1000.0
var _last_line_index: Dictionary = {}


## `balance` is the whole balance.json dictionary (only "momo" is read),
## `momo_lines` the momo_lines.json dictionary. Empty -> default files.
## `initial_trust` < 0 uses momo.trust_default.
func _init(balance: Dictionary = {}, momo_lines: Dictionary = {}, initial_trust: float = -1.0) -> void:
	if balance.is_empty():
		balance = DataLoader.load_json(DataLoader.BALANCE_PATH)
	if momo_lines.is_empty():
		momo_lines = DataLoader.load_json(DataLoader.MOMO_LINES_PATH)
	var m: Variant = balance.get("momo", {})
	cfg = m if m is Dictionary else {}
	lines = momo_lines
	var start_mood := str(cfg.get("start_mood", CALM))
	mood = start_mood if MOODS.has(start_mood) else CALM
	trust = _num("trust_default", 50.0) if initial_trust < 0.0 else initial_trust
	trust = clampf(trust, _num("trust_min", 0.0), _num("trust_max", 100.0))
	_reset_run_counters()
	run_start_trust = trust


# ---------------------------------------------------------------------------
# Basic state
# ---------------------------------------------------------------------------

static func mood_name_tr(m: String) -> String:
	return str(MOOD_NAMES_TR.get(m, m))


## {"trust": float, "trust_int": int, "mood": String, "mood_tr": String}
func get_state() -> Dictionary:
	return {"trust": trust, "trust_int": int(round(trust)), "mood": mood, "mood_tr": mood_name_tr(mood)}


## Adds `delta` with clamping; returns the change actually applied.
func add_trust(delta: float) -> float:
	var before := trust
	trust = clampf(trust + delta, _num("trust_min", 0.0), _num("trust_max", 100.0))
	return trust - before


func set_trust(value: float) -> void:
	trust = clampf(value, _num("trust_min", 0.0), _num("trust_max", 100.0))


func set_mood(new_mood: String) -> void:
	if MOODS.has(new_mood) and new_mood != mood:
		mood = new_mood
		if mood == EXCITED:
			_excited_commands = 0


## Multiplier applied to refuse/delay probabilities: 1 at trust 50,
## (1 + trust_modulation) at trust 0, (1 - trust_modulation) at trust 100.
func trust_factor() -> float:
	var mod := _num("trust_modulation", 0.4)
	return maxf(0.0, 1.0 + mod * (50.0 - trust) / 50.0)


## Call when a run begins. Mood carries over from the garage (sulky stays
## sulky until comforted); very low trust starts the run scared.
func start_run() -> void:
	run_start_trust = trust
	_reset_run_counters()
	if mood != SULKY and trust < _num("start_scared_below_trust", 20.0):
		set_mood(SCARED)


func _reset_run_counters() -> void:
	comfort_gain_this_run = 0.0
	_near_misses = 0
	_successes = 0
	_kills = 0
	_contradictions = 0
	_excited_commands = 0
	_last_move_intent = ""
	_last_move_time = -1000.0
	run_stats = {
		"insults": 0, "comforts": 0, "contradictions": 0, "damage_taken": 0.0,
		"near_misses": 0, "kills": 0, "manoeuvres": 0, "refusals": 0, "delays": 0,
		"extras": 0, "unknown": 0, "commands": 0,
	}


# ---------------------------------------------------------------------------
# Events
# ---------------------------------------------------------------------------

## event: "near_miss" or {"type": "damage", "amount": 30}. Types: damage,
## near_miss, insult, comfort (alias praise), contradictory,
## manoeuvre_success, kill, unknown_command.
## Returns {"type", "mood_before", "mood", "mood_changed", "trust_delta",
##          "trust", "line", "line_category"}. Unknown types change nothing.
func apply_event(event: Variant, rng: RandomNumberGenerator = null) -> Dictionary:
	var ev: Dictionary = event if event is Dictionary else {"type": str(event)}
	var type := str(ev.get("type", ""))
	var before := mood
	var delta := 0.0
	var category := ""
	match type:
		"damage":
			var amount := float(ev.get("amount", 0.0))
			run_stats["damage_taken"] = float(run_stats["damage_taken"]) + amount
			var heavy := amount >= _num("heavy_damage_amount", 25.0)
			delta = add_trust(_delta("heavy_damage" if heavy else "damage"))
			_successes = 0
			if mood != SULKY:
				set_mood(SCARED)
			category = "damage"
		"near_miss":
			run_stats["near_misses"] = int(run_stats["near_misses"]) + 1
			delta = add_trust(_delta("near_miss"))
			_near_misses += 1
			if mood == CALM and _near_misses >= int(_num("near_misses_to_scare", 2.0)):
				set_mood(SCARED)
				_near_misses = 0
			category = "near_miss"
		"insult":
			run_stats["insults"] = int(run_stats["insults"]) + 1
			delta = add_trust(_delta("insult"))
			set_mood(SULKY)
			category = "insult_received"
		"comfort", "praise":
			type = "comfort"
			run_stats["comforts"] = int(run_stats["comforts"]) + 1
			var gain := _delta("comfort")
			if gain > 0.0:
				var room := maxf(0.0, _num("comfort_trust_cap_per_run", 15.0) - comfort_gain_this_run)
				gain = minf(gain, room)
			delta = add_trust(gain)
			comfort_gain_this_run += maxf(0.0, delta)
			_contradictions = 0
			_near_misses = 0
			if mood == SULKY or mood == SCARED:
				set_mood(CALM)
			category = "comfort_received." + before
		"contradictory":
			run_stats["contradictions"] = int(run_stats["contradictions"]) + 1
			delta = add_trust(_delta("contradictory"))
			_contradictions += 1
			if _contradictions >= int(_num("contradictions_to_sulk", 2.0)):
				set_mood(SULKY)
				_contradictions = 0
			category = "contradictory"
		"manoeuvre_success":
			run_stats["manoeuvres"] = int(run_stats["manoeuvres"]) + 1
			delta = add_trust(_delta("manoeuvre_success"))
			_near_misses = 0
			if mood == SCARED:
				set_mood(CALM)
				_successes = 0
			elif mood == CALM:
				_successes += 1
				if _successes >= int(_num("successes_to_excite", 2.0)):
					set_mood(EXCITED)
					_successes = 0
			category = "manoeuvre"
		"kill":
			run_stats["kills"] = int(run_stats["kills"]) + 1
			delta = add_trust(_delta("kill"))
			if mood == SCARED:
				set_mood(CALM)
				_kills = 0
			elif mood == CALM:
				_kills += 1
				if _kills >= int(_num("kills_to_excite", 1.0)):
					set_mood(EXCITED)
					_kills = 0
			category = "kill"
		"unknown_command":
			run_stats["unknown"] = int(run_stats["unknown"]) + 1
			delta = add_trust(_delta("unknown_command"))
			category = "confused"
		_:
			type = ""
	var line := pick_line(category, rng) if category != "" else ""
	return {
		"type": type, "mood_before": before, "mood": mood, "mood_changed": before != mood,
		"trust_delta": delta, "trust": trust, "line": line, "line_category": category,
	}


## Contradiction detection: true when `intent` is the opposite of the last
## movement intent (pairs in momo.contradictory_pairs) within
## momo.contradiction_window_seconds. Does not apply the event by itself.
func note_command(intent: String, now_sec: float) -> bool:
	var opposite := _opposite_of(intent)
	if opposite == "":
		return false
	var window := _num("contradiction_window_seconds", 2.5)
	var contradictory := _last_move_intent == opposite and (now_sec - _last_move_time) <= window and now_sec >= _last_move_time
	_last_move_intent = intent
	_last_move_time = now_sec
	return contradictory


func _opposite_of(intent: String) -> String:
	for pair in cfg.get("contradictory_pairs", []):
		if pair is Array and pair.size() == 2:
			if str(pair[0]) == intent:
				return str(pair[1])
			if str(pair[1]) == intent:
				return str(pair[0])
	return ""


# ---------------------------------------------------------------------------
# Command interpretation
# ---------------------------------------------------------------------------

## Decides what MOMO actually does with one parsed command.
## `now_sec` (game time, >= 0) enables contradiction detection; pass -1 to skip.
## Returns:
##  {"action": "execute"|"delay"|"refuse"|"none", "command": Dictionary,
##   "delay": float seconds before executing (delay only), "speed": float
##   manoeuvre speed multiplier, "extra": Array of extra command dicts
##   (each has "extra": true), "line": String ("" = stay silent),
##   "line_category": String, "mood_before", "mood", "mood_changed": bool,
##   "trust": float, "trust_delta": float, "contradictory": bool}
func interpret(command: Dictionary, rng: RandomNumberGenerator, now_sec: float = -1.0) -> Dictionary:
	var intent := str(command.get("intent", "unknown"))
	var before := mood
	var trust_before := trust
	var res := {
		"action": ACTION_EXECUTE, "command": command, "delay": 0.0, "speed": 1.0, "extra": [],
		"line": "", "line_category": "", "mood_before": before, "mood": mood,
		"mood_changed": false, "trust": trust, "trust_delta": 0.0, "contradictory": false,
	}
	run_stats["commands"] = int(run_stats["commands"]) + 1
	if intent == "comfort" or intent == "insult" or intent == "unknown" or intent == "":
		var ev := apply_event("unknown_command" if intent == "" or intent == "unknown" else intent, rng)
		res["action"] = ACTION_NONE
		res["line"] = ev["line"]
		res["line_category"] = ev["line_category"]
		return _finish(res, before, trust_before)

	if now_sec >= 0.0 and note_command(intent, now_sec):
		var cev := apply_event("contradictory", rng)
		res["contradictory"] = true
		res["line"] = cev["line"]
		res["line_category"] = cev["line_category"]

	var attack: bool = (cfg.get("attack_intents", ["fire", "ram", "drop_mine"]) as Array).has(intent)
	var escape: bool = (cfg.get("escape_intents", ["dodge", "lane_left", "lane_right"]) as Array).has(intent)
	var tf := trust_factor()
	match mood:
		SCARED:
			if attack:
				var p_refuse := clampf(_num("scared.attack_refuse_probability", 0.3) * tf, 0.0, 1.0)
				var p_delay := clampf(_num("scared.attack_delay_probability", 0.3) * tf, 0.0, 1.0 - p_refuse)
				var r := rng.randf()
				if r < p_refuse:
					res["action"] = ACTION_REFUSE
				elif r < p_refuse + p_delay:
					res["action"] = ACTION_DELAY
					res["delay"] = rng.randf_range(_num("scared.delay_min", 0.6), _num("scared.delay_max", 1.2))
				res["speed"] = _num("scared.other_speed", 1.0)
			elif escape:
				res["speed"] = _num("scared.escape_speed", 1.5)
			else:
				res["speed"] = _num("scared.other_speed", 1.0)
		EXCITED:
			res["speed"] = _num("excited.speed", 1.3)
			if rng.randf() < clampf(_num("excited.extra_probability", 0.25), 0.0, 1.0):
				res["extra"] = [_extra_for(command, rng)]
			_excited_commands += 1
		SULKY:
			var p_refuse := clampf(_num("sulky.refuse_probability", 0.2) * tf, 0.0, 1.0)
			var p_delay := clampf(_num("sulky.delay_probability", 0.55) * tf, 0.0, 1.0 - p_refuse)
			var r := rng.randf()
			if r < p_refuse:
				res["action"] = ACTION_REFUSE
			elif r < p_refuse + p_delay:
				res["action"] = ACTION_DELAY
				res["delay"] = rng.randf_range(_num("sulky.delay_min", 0.8), _num("sulky.delay_max", 1.6))
			res["speed"] = _num("sulky.speed", 0.8)
		_:
			res["speed"] = _num("calm.speed", 1.0)

	match str(res["action"]):
		ACTION_REFUSE:
			run_stats["refusals"] = int(run_stats["refusals"]) + 1
		ACTION_DELAY:
			run_stats["delays"] = int(run_stats["delays"]) + 1
	if not (res["extra"] as Array).is_empty():
		run_stats["extras"] = int(run_stats["extras"]) + 1

	if res["line_category"] == "":
		var category := ""
		var speak := true
		if res["action"] == ACTION_REFUSE:
			category = "refuse." + mood
		elif res["action"] == ACTION_DELAY:
			category = "delay." + mood
		elif not (res["extra"] as Array).is_empty():
			category = "extra_action"
		else:
			category = "ack." + mood
			if mood == SULKY:
				speak = rng.randf() < clampf(_num("sulky.snark_probability", 0.6), 0.0, 1.0)
		if speak:
			res["line"] = pick_line(category, rng)
			res["line_category"] = category

	if mood == EXCITED and _excited_commands >= int(_num("excited_max_commands", 6.0)):
		set_mood(CALM)
	return _finish(res, before, trust_before)


func _finish(res: Dictionary, before: String, trust_before: float) -> Dictionary:
	res["mood"] = mood
	res["mood_changed"] = before != mood
	res["trust"] = trust
	res["trust_delta"] = trust - trust_before
	return res


func _extra_for(command: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var intent := str(command.get("intent", ""))
	var extra: Dictionary
	if (cfg.get("excited", {}).get("double_fire_intents", ["fire"]) as Array).has(intent):
		extra = command.duplicate(true)
	elif intent == "lane_left" or intent == "lane_right":
		extra = {"intent": intent}
	else:
		extra = {"intent": "lane_left" if rng.randf() < 0.5 else "lane_right"}
	extra["extra"] = true
	return extra


# ---------------------------------------------------------------------------
# Lines
# ---------------------------------------------------------------------------

## Picks a line from a dotted category ("ack.calm", "run_end.destroyed.up").
## Never returns the same line twice in a row for a category. Without rng it
## cycles in order. Missing or empty category -> "".
func pick_line(category: String, rng: RandomNumberGenerator = null) -> String:
	var list: Variant = DataLoader.dig(lines, category, null)
	if not list is Array or (list as Array).is_empty():
		return ""
	var arr: Array = list
	var n := arr.size()
	var last := int(_last_line_index.get(category, -1))
	var idx := 0
	if n == 1:
		idx = 0
	elif rng == null:
		idx = (last + 1) % n
	elif last < 0 or last >= n:
		idx = rng.randi_range(0, n - 1)
	else:
		idx = rng.randi_range(0, n - 2)
		if idx >= last:
			idx += 1
	_last_line_index[category] = idx
	return str(arr[idx])


# ---------------------------------------------------------------------------
# Run summary and persistence
# ---------------------------------------------------------------------------

## Trust change since start_run().
func run_trust_delta() -> float:
	return trust - run_start_trust


## Ends the run: applies run_survived / run_destroyed trust delta and returns
## {"outcome", "trust_before", "trust", "trust_delta", "band": "up"|"flat"|"down",
##  "comment": String, "stats": Dictionary}. outcome: "destroyed" or "survived".
func end_run(outcome: String, rng: RandomNumberGenerator = null) -> Dictionary:
	var o := "destroyed" if outcome == "destroyed" else "survived"
	add_trust(_delta("run_" + o))
	var d := run_trust_delta()
	var flat := _num("run_end_flat_band", 2.0)
	var band := "flat"
	if d > flat:
		band = "up"
	elif d < -flat:
		band = "down"
	return {
		"outcome": o, "trust_before": run_start_trust, "trust": trust, "trust_delta": d,
		"band": band, "comment": pick_line("run_end.%s.%s" % [o, band], rng),
		"stats": run_stats.duplicate(),
	}


## Persistent part of MOMO (trust only; mood is per session).
func to_save() -> Dictionary:
	return {"trust": trust}


func load_save(data: Dictionary) -> void:
	var t: Variant = data.get("trust", null)
	if t is float or t is int:
		set_trust(float(t))
	run_start_trust = trust


func _num(path: String, default_value: float) -> float:
	return DataLoader.num(cfg, path, default_value)


func _delta(key: String) -> float:
	return DataLoader.num(cfg, "trust_deltas." + key, 0.0)
