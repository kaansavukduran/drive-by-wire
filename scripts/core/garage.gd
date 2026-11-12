extends RefCounted
## Garage logic: dialogue selection and choices, upgrades as balance modifiers,
## MOMO's memory (small persistent facts that alter greetings).
## Pure: functions return new dictionaries and never mutate their inputs,
## except that a passed MOMO instance receives trust/mood effects.

const DataLoader := preload("res://scripts/core/data_loader.gd")

var data: Dictionary = {}
var cfg: Dictionary = {}


## `garage_data` = data/garage.json, `balance` = data/balance.json (reads
## "garage"). Empty -> default files.
func _init(garage_data: Dictionary = {}, balance: Dictionary = {}) -> void:
	if garage_data.is_empty():
		garage_data = DataLoader.load_json(DataLoader.GARAGE_PATH)
	if balance.is_empty():
		balance = DataLoader.load_json(DataLoader.BALANCE_PATH)
	data = garage_data
	var g: Variant = balance.get("garage", {})
	cfg = g if g is Dictionary else {}


# ---------------------------------------------------------------------------
# Memory
# ---------------------------------------------------------------------------

## Default memory shape.
static func default_memory() -> Dictionary:
	return {
		"runs": 0,
		"chapter_clears": 0,
		"last_route": "",
		"last_route_goal": 0,
		"last_outcome": "",          # "", "destroyed", "survived"
		"best_distance": 0.0,
		"total_distance": 0.0,
		"total_kills": 0,
		"last_trust_delta": 0.0,
		"insults_total": 0,
		"comforts_total": 0,
		"choice_counts": {},         # tag -> count (feed/repair/talk/tease/insult)
		"last_dialogue_id": "",
	}


## Returns `memory` with missing/mistyped keys replaced by defaults.
static func sanitize_memory(memory: Variant) -> Dictionary:
	var out := default_memory()
	if not memory is Dictionary:
		return out
	var m: Dictionary = memory
	for key in out:
		if not m.has(key):
			continue
		var def: Variant = out[key]
		var v: Variant = m[key]
		if def is int and (v is int or v is float) and is_finite(float(v)):
			out[key] = int(clampf(float(v), 0, 2000000000))
		elif def is float and (v is int or v is float) and is_finite(float(v)):
			out[key] = clampf(float(v), -2000000000, 2000000000)
		elif def is String and v is String:
			out[key] = v.left(128)
		elif def is Dictionary and v is Dictionary:
			var counts := {}
			for k in v:
				if counts.size() >= 64:
					break
				if str(k).length() <= 64 and (v[k] is int or v[k] is float) and is_finite(float(v[k])):
					counts[str(k)] = int(clampf(float(v[k]), 0, 2000000000))
			out[key] = counts
	return out


## run: {"outcome": "destroyed"|"survived", "distance": float, "kills": int,
##       "trust_delta": float, "insults": int, "comforts": int}
## (MOMO.end_run() result works too: its "stats" are read for kills/insults/comforts.)
static func record_run(memory: Dictionary, run: Dictionary) -> Dictionary:
	var m := sanitize_memory(memory)
	var stats: Dictionary = run.get("stats", {}) if run.get("stats", {}) is Dictionary else {}
	var distance := float(run.get("distance", 0.0))
	m["runs"] = int(m["runs"]) + 1
	m["last_outcome"] = "destroyed" if str(run.get("outcome", "")) == "destroyed" else "survived"
	m["best_distance"] = maxf(float(m["best_distance"]), distance)
	m["total_distance"] = float(m["total_distance"]) + distance
	m["total_kills"] = int(m["total_kills"]) + int(run.get("kills", stats.get("kills", 0)))
	m["last_trust_delta"] = float(run.get("trust_delta", 0.0))
	m["insults_total"] = int(m["insults_total"]) + int(run.get("insults", stats.get("insults", 0)))
	m["comforts_total"] = int(m["comforts_total"]) + int(run.get("comforts", stats.get("comforts", 0)))
	return m


## Most chosen tag with count >= garage.favourite_min_count, else "".
func favourite_tag(memory: Dictionary) -> String:
	var counts: Dictionary = sanitize_memory(memory)["choice_counts"]
	var best := ""
	var best_n := int(DataLoader.num(cfg, "favourite_min_count", 3.0)) - 1
	var keys := counts.keys()
	keys.sort()
	for k in keys:
		if int(counts[k]) > best_n:
			best = str(k)
			best_n = int(counts[k])
	return best


## "low" | "mid" | "high" from garage.trust_bands.
func trust_band(trust: float) -> String:
	if trust < DataLoader.num(cfg, "trust_bands.low_below", 35.0):
		return "low"
	if trust >= DataLoader.num(cfg, "trust_bands.high_from", 70.0):
		return "high"
	return "mid"


## Memory facts that apply, in priority order (keys of momo_lines garage_memory).
func memory_keys(memory: Dictionary, trust: float) -> PackedStringArray:
	var m := sanitize_memory(memory)
	var keys := PackedStringArray()
	if int(m["runs"]) == 0:
		keys.append("first_visit")
		return keys
	if int(m["insults_total"]) >= 5 and trust_band(trust) == "low":
		keys.append("many_insults")
	if m["last_outcome"] != "":
		keys.append("after_" + str(m["last_outcome"]))
	var fav := favourite_tag(m)
	if fav != "" and fav != "insult":
		keys.append("favourite_" + fav)
	if int(m["runs"]) >= int(DataLoader.num(cfg, "veteran_runs", 5.0)):
		keys.append("veteran")
	return keys


## Garage greeting: trust-band line + one memory line.
## Returns {"text": String, "band": String, "memory_key": String}.
## `momo` is a momo.gd instance (its line picker avoids repeats).
func greeting(momo: RefCounted, memory: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	var trust: float = momo.trust
	var band := trust_band(trust)
	var base: String = momo.pick_line("garage_greeting." + band, rng)
	var keys := memory_keys(memory, trust)
	var key := ""
	if not keys.is_empty():
		key = keys[0] if rng == null or keys[0] == "first_visit" else keys[rng.randi_range(0, keys.size() - 1)]
	var mem_line: String = momo.pick_line("garage_memory." + key, rng) if key != "" else ""
	var text := base if mem_line == "" else (mem_line if base == "" else base + " " + mem_line)
	return {"text": text, "band": band, "memory_key": key}


# ---------------------------------------------------------------------------
# Dialogue
# ---------------------------------------------------------------------------

## Dialogues allowed for this trust/memory (copies).
func eligible_dialogues(trust: float, memory: Dictionary) -> Array:
	var m := sanitize_memory(memory)
	var out: Array = []
	for d in data.get("dialogues", []):
		if not d is Dictionary:
			continue
		if trust < float(d.get("min_trust", 0)) or trust > float(d.get("max_trust", 100)):
			continue
		var req: Dictionary = d.get("requires", {}) if d.get("requires", {}) is Dictionary else {}
		if req.has("min_runs") and int(m["runs"]) < int(req["min_runs"]):
			continue
		if req.has("last_outcome") and str(m["last_outcome"]) != str(req["last_outcome"]):
			continue
		out.append(d.duplicate(true))
	return out


## Picks one dialogue, avoiding memory.last_dialogue_id when possible.
## Returns {} if none is eligible.
func pick_dialogue(trust: float, memory: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	var all := eligible_dialogues(trust, memory)
	if all.is_empty():
		return {}
	var last := str(sanitize_memory(memory)["last_dialogue_id"])
	var fresh: Array = all.filter(func(d: Dictionary) -> bool: return str(d.get("id", "")) != last)
	var pool: Array = fresh if not fresh.is_empty() else all
	return pool[0] if rng == null else pool[rng.randi_range(0, pool.size() - 1)]


func find_dialogue(dialogue_id: String) -> Dictionary:
	for d in data.get("dialogues", []):
		if d is Dictionary and str(d.get("id", "")) == dialogue_id:
			return d.duplicate(true)
	return {}


## Applies a dialogue choice. If `momo` (momo.gd instance) is given, its trust
## and mood change. Returns {"ok": bool, "reply": String, "tag": String,
## "trust_delta": float (applied), "mood": String ("" = unchanged),
## "next_run_modifiers": Array of {path, op, value}, "memory": Dictionary (updated copy)}.
func apply_choice(dialogue: Dictionary, option_id: String, momo: RefCounted, memory: Dictionary) -> Dictionary:
	var m := sanitize_memory(memory)
	var res := {"ok": false, "reply": "", "tag": "", "trust_delta": 0.0, "mood": "", "next_run_modifiers": [], "memory": m}
	var option := {}
	for o in dialogue.get("options", []):
		if o is Dictionary and str(o.get("id", "")) == option_id:
			option = o
			break
	if option.is_empty():
		return res
	var effects: Dictionary = option.get("effects", {}) if option.get("effects", {}) is Dictionary else {}
	var delta := float(effects.get("trust", 0.0))
	var new_mood := str(effects.get("mood", ""))
	if momo != null:
		delta = momo.add_trust(delta)
		if new_mood != "":
			momo.set_mood(new_mood)
	var tag := str(option.get("tag", "talk"))
	var counts: Dictionary = m["choice_counts"]
	counts[tag] = int(counts.get(tag, 0)) + 1
	m["last_dialogue_id"] = str(dialogue.get("id", ""))
	if tag == "insult":
		m["insults_total"] = int(m["insults_total"]) + 1
	res["ok"] = true
	res["reply"] = str(option.get("reply", ""))
	res["tag"] = tag
	res["trust_delta"] = delta
	res["mood"] = new_mood
	var mods: Variant = effects.get("next_run", [])
	res["next_run_modifiers"] = (mods as Array).duplicate(true) if mods is Array else []
	res["memory"] = m
	return res


# ---------------------------------------------------------------------------
# Upgrades
# ---------------------------------------------------------------------------

func all_upgrades() -> Array:
	return (data.get("upgrades", []) as Array).duplicate(true)


func find_upgrade(upgrade_id: String) -> Dictionary:
	for u in data.get("upgrades", []):
		if u is Dictionary and str(u.get("id", "")) == upgrade_id:
			return u.duplicate(true)
	return {}


## owned: {upgrade_id: level}. Returns up to `count` (default
## garage.upgrade_offer_count) upgrade dicts not yet at max level, each with
## "next_level" (1-based). Deterministic data order when rng is null.
func offer_upgrades(owned: Dictionary, rng: RandomNumberGenerator = null, count: int = -1) -> Array:
	if count < 0:
		count = int(DataLoader.num(cfg, "upgrade_offer_count", 3.0))
	var pool: Array = []
	for u in data.get("upgrades", []):
		if not u is Dictionary:
			continue
		var lvl := int(owned.get(u.get("id", ""), 0))
		if lvl < int(u.get("max_level", 1)):
			var copy: Dictionary = u.duplicate(true)
			copy["next_level"] = lvl + 1
			pool.append(copy)
	var out: Array = []
	while not pool.is_empty() and out.size() < count:
		var idx := 0 if rng == null else rng.randi_range(0, pool.size() - 1)
		out.append(pool[idx])
		pool.remove_at(idx)
	return out


## Returns a new owned dict with the upgrade's level +1 (unchanged if unknown or maxed).
func apply_upgrade(owned: Dictionary, upgrade_id: String) -> Dictionary:
	var out := owned.duplicate(true)
	var u := find_upgrade(upgrade_id)
	if u.is_empty():
		return out
	var lvl := int(out.get(upgrade_id, 0))
	if lvl < int(u.get("max_level", 1)):
		out[upgrade_id] = lvl + 1
	return out


## All modifiers from owned upgrades, in data order.
func modifiers_for(owned: Dictionary) -> Array:
	var mods: Array = []
	for u in data.get("upgrades", []):
		if not u is Dictionary:
			continue
		var lvl := int(owned.get(u.get("id", ""), 0))
		var levels: Array = u.get("levels", []) if u.get("levels", []) is Array else []
		for i in range(mini(lvl, levels.size())):
			if levels[i] is Array:
				mods.append_array(levels[i])
	return mods


## Deep copy of `balance` with owned upgrades and `extra_modifiers`
## (e.g. apply_choice()["next_run_modifiers"]) applied. Feed the result to
## momo.gd and to the run simulation.
func effective_balance(balance: Dictionary, owned: Dictionary, extra_modifiers: Array = []) -> Dictionary:
	var mods := modifiers_for(owned)
	mods.append_array(extra_modifiers)
	return apply_modifiers(balance, mods)


## Applies [{path, op: add|mul|set, value}] to a deep copy of `balance`.
## Unknown paths or non-numeric targets are skipped (except op "set").
static func apply_modifiers(balance: Dictionary, modifiers: Array) -> Dictionary:
	var out := balance.duplicate(true)
	for mod in modifiers:
		if not mod is Dictionary:
			continue
		var parts := str(mod.get("path", "")).split(".")
		if parts.is_empty() or parts[0] == "":
			continue
		var node: Variant = out
		var ok := true
		for i in range(parts.size() - 1):
			if node is Dictionary and (node as Dictionary).get(parts[i]) is Dictionary:
				node = (node as Dictionary)[parts[i]]
			else:
				ok = false
				break
		if not ok:
			continue
		var d: Dictionary = node
		var key := parts[parts.size() - 1]
		var op := str(mod.get("op", "add"))
		var value: Variant = mod.get("value", 0)
		if op == "set":
			d[key] = value
			continue
		var cur: Variant = d.get(key)
		if not (cur is float or cur is int) or not (value is float or value is int):
			continue
		if op == "add":
			d[key] = float(cur) + float(value)
		elif op == "mul":
			d[key] = float(cur) * float(value)
	return out
