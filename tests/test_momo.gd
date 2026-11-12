extends SceneTree
## Headless MOMO tests: godot --headless --path . --script tests/test_momo.gd

const Harness := preload("res://tests/harness.gd")
const Momo := preload("res://scripts/core/momo.gd")
const DataLoader := preload("res://scripts/core/data_loader.gd")

var balance: Dictionary
var lines: Dictionary


func _rng(seed_value: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _momo(mood: String, trust: float = 50.0) -> RefCounted:
	var m: RefCounted = Momo.new(balance, lines, trust)
	m.set_mood(mood)
	m.start_run()
	return m


## Fraction of actions over n seeded draws for `intent` in `mood`.
func _rates(mood: String, intent: String, trust: float, n: int) -> Dictionary:
	var counts := {"execute": 0, "delay": 0, "refuse": 0, "extra": 0}
	var rng := _rng(12345)
	for i in range(n):
		var m: RefCounted = _momo(mood, trust)
		var r: Dictionary = m.interpret({"intent": intent}, rng)
		counts[r["action"]] = int(counts.get(r["action"], 0)) + 1
		if not (r["extra"] as Array).is_empty():
			counts["extra"] = int(counts["extra"]) + 1
	var out := {}
	for k in counts:
		out[k] = float(counts[k]) / float(n)
	return out


func _initialize() -> void:
	var h := Harness.new("momo")
	balance = DataLoader.load_json(DataLoader.BALANCE_PATH)
	lines = DataLoader.load_json(DataLoader.MOMO_LINES_PATH)
	var cfg: Dictionary = balance["momo"]
	h.check("balance loaded", not balance.is_empty() and not lines.is_empty())

	# --- defaults and clamping
	var m: RefCounted = Momo.new(balance, lines)
	h.eq("default trust", m.trust, 50.0)
	h.eq("default mood", m.mood, "calm")
	h.eq("turkish names", [Momo.mood_name_tr("scared"), Momo.mood_name_tr("calm"), Momo.mood_name_tr("excited"), Momo.mood_name_tr("sulky")], ["korkmuş", "sakin", "heyecanlı", "küskün"])
	m.add_trust(500.0)
	h.eq("trust clamps at 100", m.trust, 100.0)
	m.add_trust(-1000.0)
	h.eq("trust clamps at 0", m.trust, 0.0)
	m.set_trust(150.0)
	h.eq("set_trust clamps", m.trust, 100.0)
	var low: RefCounted = Momo.new(balance, lines, 2.0)
	for i in range(5):
		low.apply_event("insult")
	h.eq("insults never go below 0", low.trust, 0.0)
	h.eq("trust_factor at 50", Momo.new(balance, lines, 50.0).trust_factor(), 1.0)
	h.check("trust_factor higher at low trust", Momo.new(balance, lines, 0.0).trust_factor() > Momo.new(balance, lines, 100.0).trust_factor())

	# --- mood transitions
	m = _momo("calm")
	m.apply_event({"type": "damage", "amount": 10})
	h.eq("calm + damage -> scared", m.mood, "scared")
	m = _momo("excited")
	m.apply_event({"type": "damage", "amount": 10})
	h.eq("excited + damage -> scared", m.mood, "scared")
	m = _momo("sulky")
	m.apply_event({"type": "damage", "amount": 10})
	h.eq("sulky + damage stays sulky", m.mood, "sulky")
	m = _momo("calm")
	m.apply_event("near_miss")
	h.eq("one near miss keeps calm", m.mood, "calm")
	m.apply_event("near_miss")
	h.eq("two near misses -> scared", m.mood, "scared")
	m = _momo("excited")
	m.apply_event("near_miss")
	m.apply_event("near_miss")
	h.eq("excited ignores near misses", m.mood, "excited")
	for mood in ["calm", "scared", "excited"]:
		m = _momo(mood)
		m.apply_event("insult")
		h.eq("%s + insult -> sulky" % mood, m.mood, "sulky")
	m = _momo("sulky")
	m.apply_event("comfort")
	h.eq("sulky + comfort -> calm", m.mood, "calm")
	m = _momo("scared")
	m.apply_event("praise")
	h.eq("scared + praise -> calm", m.mood, "calm")
	m = _momo("excited")
	m.apply_event("comfort")
	h.eq("excited + comfort stays excited", m.mood, "excited")
	m = _momo("sulky")
	for ev in ["manoeuvre_success", "manoeuvre_success", "kill", "kill", "near_miss"]:
		m.apply_event(ev)
	h.eq("sulky only leaves via comfort", m.mood, "sulky")
	m = _momo("scared")
	m.apply_event("manoeuvre_success")
	h.eq("scared + manoeuvre -> calm", m.mood, "calm")
	m = _momo("calm")
	m.apply_event("manoeuvre_success")
	h.eq("calm + 1 manoeuvre stays calm", m.mood, "calm")
	m.apply_event("manoeuvre_success")
	h.eq("calm + 2 manoeuvres -> excited", m.mood, "excited")
	m = _momo("scared")
	m.apply_event("kill")
	h.eq("scared + kill -> calm", m.mood, "calm")
	m = _momo("calm")
	m.apply_event("kill")
	h.eq("calm + kill -> excited", m.mood, "excited")
	m = _momo("calm")
	m.apply_event("contradictory")
	h.eq("one contradiction keeps calm", m.mood, "calm")
	m.apply_event("contradictory")
	h.eq("two contradictions -> sulky", m.mood, "sulky")
	m = _momo("excited")
	var rng := _rng(7)
	for i in range(int(cfg["excited_max_commands"])):
		m.interpret({"intent": "speed_up"}, rng)
	h.eq("excited cools to calm after N commands", m.mood, "calm")
	var start_low: RefCounted = Momo.new(balance, lines, 10.0)
	start_low.start_run()
	h.eq("very low trust starts run scared", start_low.mood, "scared")
	var ev: Dictionary = _momo("calm").apply_event("bogus_event")
	h.check("unknown event changes nothing", ev["type"] == "" and not ev["mood_changed"] and ev["trust_delta"] == 0.0)

	# --- trust deltas
	m = _momo("calm")
	var d: Dictionary = m.apply_event("insult")
	h.eq("insult trust delta", d["trust_delta"], float(cfg["trust_deltas"]["insult"]))
	d = m.apply_event({"type": "damage", "amount": 50})
	h.eq("heavy damage trust delta", d["trust_delta"], float(cfg["trust_deltas"]["heavy_damage"]))
	m = _momo("calm")
	var total := 0.0
	for i in range(20):
		total += float(m.apply_event("comfort")["trust_delta"])
	h.eq("comfort trust gain capped per run", total, float(cfg["comfort_trust_cap_per_run"]))
	h.check("event returns a line", str(_momo("calm").apply_event("kill", _rng(1))["line"]) != "")

	# --- contradiction detection
	m = _momo("calm")
	h.eq("first lane command not contradictory", m.note_command("lane_left", 1.0), false)
	h.eq("lane_left then lane_right in window", m.note_command("lane_right", 2.0), true)
	m = _momo("calm")
	m.note_command("speed_up", 0.0)
	h.eq("speed_up then slow_down in window", m.note_command("slow_down", 1.0), true)
	m = _momo("calm")
	m.note_command("lane_left", 0.0)
	h.eq("outside window not contradictory", m.note_command("lane_right", 10.0), false)
	m = _momo("calm")
	m.note_command("lane_left", 0.0)
	h.eq("same direction not contradictory", m.note_command("lane_left", 0.5), false)
	m = _momo("calm")
	m.note_command("lane_left", 0.0)
	h.eq("unrelated intent not contradictory", m.note_command("fire", 0.5), false)
	m = _momo("calm")
	rng = _rng(3)
	m.interpret({"intent": "lane_left"}, rng, 0.0)
	var r1: Dictionary = m.interpret({"intent": "lane_right"}, rng, 0.5)
	h.check("interpret flags contradiction", r1["contradictory"] and r1["line_category"] == "contradictory")
	m.interpret({"intent": "lane_left"}, rng, 1.0)
	h.eq("repeated contradictions in interpret -> sulky", m.mood, "sulky")

	# --- interpret per mood (statistical, seeded)
	var n := 4000
	var sc: Dictionary = _rates("scared", "fire", 50.0, n)
	var p_ref := float(cfg["scared"]["attack_refuse_probability"])
	var p_del := float(cfg["scared"]["attack_delay_probability"])
	h.near("scared refuses attack ~p", sc["refuse"], p_ref, 0.03)
	h.near("scared delays attack ~p", sc["delay"], p_del, 0.03)
	var sc_low: Dictionary = _rates("scared", "fire", 0.0, n)
	var sc_high: Dictionary = _rates("scared", "fire", 100.0, n)
	h.check("low trust refuses more than high trust", sc_low["refuse"] > sc["refuse"] and sc["refuse"] > sc_high["refuse"], "%s / %s / %s" % [sc_low["refuse"], sc["refuse"], sc_high["refuse"]])
	h.near("trust 0 refuse scaled by 1+mod", sc_low["refuse"], p_ref * (1.0 + float(cfg["trust_modulation"])), 0.03)
	var sc_esc: Dictionary = _rates("scared", "dodge", 50.0, 500)
	h.eq("scared always executes escapes", sc_esc["execute"], 1.0)
	var esc: Dictionary = _momo("scared").interpret({"intent": "dodge"}, _rng(1))
	h.eq("scared escape is fast", esc["speed"], float(cfg["scared"]["escape_speed"]))
	var del_r: Dictionary = {}
	rng = _rng(99)
	for i in range(200):
		var rr: Dictionary = _momo("scared").interpret({"intent": "fire"}, rng)
		if rr["action"] == "delay":
			del_r = rr
			break
	h.check("scared delay within configured range", not del_r.is_empty() and del_r["delay"] >= float(cfg["scared"]["delay_min"]) and del_r["delay"] <= float(cfg["scared"]["delay_max"]))
	var calm: Dictionary = _rates("calm", "fire", 50.0, 1000)
	h.eq("calm executes everything", calm["execute"], 1.0)
	h.eq("calm adds no extras", calm["extra"], 0.0)
	var calm_r: Dictionary = _momo("calm").interpret({"intent": "fire", "target": {"type": "truck"}}, _rng(1))
	h.check("calm keeps command as is", calm_r["command"]["target"]["type"] == "truck" and calm_r["speed"] == 1.0 and calm_r["delay"] == 0.0)
	var ex: Dictionary = _rates("excited", "fire", 50.0, n)
	h.eq("excited always executes", ex["execute"], 1.0)
	h.near("excited extra ~p", ex["extra"], float(cfg["excited"]["extra_probability"]), 0.03)
	var ex_r: Dictionary = {}
	rng = _rng(5)
	for i in range(100):
		var rr: Dictionary = _momo("excited").interpret({"intent": "fire"}, rng)
		if not (rr["extra"] as Array).is_empty():
			ex_r = rr
			break
	h.check("excited double fire", not ex_r.is_empty() and ex_r["extra"][0]["intent"] == "fire" and ex_r["extra"][0]["extra"] == true)
	ex_r = {}
	for i in range(100):
		var rr: Dictionary = _momo("excited").interpret({"intent": "speed_up"}, rng)
		if not (rr["extra"] as Array).is_empty():
			ex_r = rr
			break
	h.check("excited needless lane change", not ex_r.is_empty() and str(ex_r["extra"][0]["intent"]).begins_with("lane_"))
	h.eq("excited is fast", _momo("excited").interpret({"intent": "dodge"}, _rng(1))["speed"], float(cfg["excited"]["speed"]))
	var su: Dictionary = _rates("sulky", "lane_left", 50.0, n)
	h.near("sulky refuses ~p", su["refuse"], float(cfg["sulky"]["refuse_probability"]), 0.03)
	h.near("sulky delays ~p", su["delay"], float(cfg["sulky"]["delay_probability"]), 0.03)
	h.eq("sulky is slow", _momo("sulky").interpret({"intent": "dodge"}, _rng(1))["speed"], float(cfg["sulky"]["speed"]))
	var ur: Dictionary = _momo("calm").interpret({"intent": "unknown", "text": "asdf"}, _rng(1))
	h.check("unknown -> none + confused line", ur["action"] == "none" and ur["line_category"] == "confused" and ur["line"] != "")
	m = _momo("sulky")
	var cr: Dictionary = m.interpret({"intent": "comfort"}, _rng(1))
	h.check("comfort command un-sulks", cr["action"] == "none" and cr["mood"] == "calm" and cr["mood_changed"])
	m = _momo("calm")
	var ir: Dictionary = m.interpret({"intent": "insult"}, _rng(1))
	h.check("insult command -> sulky, trust down", ir["mood"] == "sulky" and ir["trust_delta"] < 0.0)
	h.check("refuse line from mood category", _first_line_category("scared", "refuse") == "refuse.scared")
	h.check("delay line from mood category", _first_line_category("sulky", "delay") == "delay.sulky")
	# determinism: same seed, same outcomes
	var s1 := ""
	var s2 := ""
	for seed_value in [11, 11]:
		var mm: RefCounted = _momo("scared")
		var rg := _rng(seed_value)
		var acc := ""
		for i in range(30):
			var rr: Dictionary = mm.interpret({"intent": "fire"}, rg)
			acc += str(rr["action"]) + str(rr["line"])
		if s1 == "":
			s1 = acc
		else:
			s2 = acc
	h.eq("seeded interpret is deterministic", s1, s2)

	# --- no-repeat lines
	m = _momo("calm")
	rng = _rng(2024)
	for cat in ["ack.scared", "ack.calm", "ack.excited", "ack.sulky", "confused", "damage", "run_end.destroyed.up"]:
		var prev := ""
		var repeats := 0
		var seen := {}
		for i in range(300):
			var line: String = m.pick_line(cat, rng)
			if line == prev:
				repeats += 1
			prev = line
			seen[line] = true
		h.check("no repeat in a row: " + cat, repeats == 0 and seen.size() > 1, "repeats=%d distinct=%d" % [repeats, seen.size()])
	var prev2 := ""
	var rep2 := 0
	for i in range(20):
		var line: String = m.pick_line("kill")
		if line == prev2:
			rep2 += 1
		prev2 = line
	h.eq("no repeat without rng", rep2, 0)
	h.eq("missing category -> empty", m.pick_line("no.such.category", rng), "")
	for mood in ["scared", "calm", "excited", "sulky"]:
		h.check("at least 6 ack lines for " + mood, (lines["ack"][mood] as Array).size() >= 6)

	# --- run summary
	m = Momo.new(balance, lines, 50.0)
	m.start_run()
	for i in range(3):
		m.apply_event("kill")
	var end_up: Dictionary = m.end_run("survived", _rng(1))
	h.eq("run end band up", end_up["band"], "up")
	h.near("run trust delta", end_up["trust_delta"], 3.0 * float(cfg["trust_deltas"]["kill"]) + float(cfg["trust_deltas"]["run_survived"]), 0.001)
	h.check("run end comment present", str(end_up["comment"]) != "" and (lines["run_end"]["survived"]["up"] as Array).has(end_up["comment"]))
	h.eq("run stats kills", end_up["stats"]["kills"], 3)
	m.start_run()
	m.apply_event("insult")
	var end_down: Dictionary = m.end_run("destroyed", _rng(1))
	h.check("run end destroyed + down", end_down["band"] == "down" and (lines["run_end"]["destroyed"]["down"] as Array).has(end_down["comment"]))
	m.start_run()
	h.eq("run end flat", m.end_run("survived")["band"], "flat")
	var saved: Dictionary = m.to_save()
	var m2: RefCounted = Momo.new(balance, lines)
	m2.load_save(saved)
	h.eq("save/load trust", m2.trust, m.trust)

	quit(h.finish())


func _first_line_category(mood: String, action: String) -> String:
	var rng := _rng(42)
	for i in range(500):
		var r: Dictionary = _momo(mood).interpret({"intent": "fire"}, rng)
		if r["action"] == action:
			return str(r["line_category"])
	return ""
