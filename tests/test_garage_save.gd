extends SceneTree
## Headless garage + save tests: godot --headless --path . --script tests/test_garage_save.gd

const Harness := preload("res://tests/harness.gd")
const Garage := preload("res://scripts/core/garage.gd")
const Momo := preload("res://scripts/core/momo.gd")
const SaveStore := preload("res://scripts/core/save_store.gd")
const DataLoader := preload("res://scripts/core/data_loader.gd")

const TEST_PATH := "user://test_save_tmp/save.json"


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _initialize() -> void:
	var h := Harness.new("garage_save")
	var balance := DataLoader.load_json(DataLoader.BALANCE_PATH)
	var lines := DataLoader.load_json(DataLoader.MOMO_LINES_PATH)
	var g: RefCounted = Garage.new()
	h.check("garage data loaded", (g.data.get("dialogues", []) as Array).size() >= 3 and (g.data.get("upgrades", []) as Array).size() >= 4)
	for d in g.data["dialogues"]:
		var n := (d["options"] as Array).size()
		h.check("dialogue %s has 3-4 options" % d["id"], n >= 3 and n <= 4)

	# --- memory
	var mem: Dictionary = Garage.default_memory()
	h.eq("default memory runs", mem["runs"], 0)
	h.eq("sanitize junk memory", Garage.sanitize_memory("junk"), Garage.default_memory())
	var fixed: Dictionary = Garage.sanitize_memory({"runs": -4, "last_outcome": 7, "choice_counts": {"feed": 2.0, "bad": "x"}})
	h.check("sanitize fixes types", fixed["runs"] == 0 and fixed["last_outcome"] == "" and fixed["choice_counts"] == {"feed": 2})
	var m2: Dictionary = Garage.record_run(mem, {"outcome": "destroyed", "distance": 420.0, "kills": 3, "trust_delta": -4.0, "insults": 2, "comforts": 1})
	h.check("record_run updates facts", m2["runs"] == 1 and m2["last_outcome"] == "destroyed" and m2["best_distance"] == 420.0 and m2["total_kills"] == 3 and m2["insults_total"] == 2)
	h.eq("record_run does not mutate input", mem["runs"], 0)
	var momo: RefCounted = Momo.new(balance, lines, 50.0)
	momo.start_run()
	momo.apply_event("kill")
	var end: Dictionary = momo.end_run("survived")
	var m3: Dictionary = Garage.record_run(m2, end)
	h.check("record_run accepts momo.end_run()", m3["runs"] == 2 and m3["last_outcome"] == "survived" and m3["total_kills"] == 4)

	# --- greetings
	h.eq("trust band low", g.trust_band(10.0), "low")
	h.eq("trust band mid", g.trust_band(50.0), "mid")
	h.eq("trust band high", g.trust_band(90.0), "high")
	h.eq("first visit memory key", g.greeting(momo, mem, _rng(1))["memory_key"], "first_visit")
	h.eq("after destroyed memory key (no rng)", g.greeting(momo, m2)["memory_key"], "after_destroyed")
	var fav_mem: Dictionary = m2.duplicate(true)
	fav_mem["choice_counts"] = {"feed": 4, "talk": 1}
	h.eq("favourite tag", g.favourite_tag(fav_mem), "feed")
	h.check("favourite in memory keys", g.memory_keys(fav_mem, 50.0).has("favourite_feed"))
	var vet: Dictionary = m2.duplicate(true)
	vet["runs"] = 9
	h.check("veteran in memory keys", g.memory_keys(vet, 50.0).has("veteran"))
	var rude: Dictionary = m2.duplicate(true)
	rude["insults_total"] = 8
	h.eq("insults remembered at low trust", g.memory_keys(rude, 10.0)[0], "many_insults")
	var gr: Dictionary = g.greeting(momo, m2, _rng(3))
	h.check("greeting text non-empty", str(gr["text"]).length() > 0)

	# --- dialogue
	var d0: Dictionary = g.pick_dialogue(50.0, mem, _rng(1))
	h.check("pick_dialogue returns dialogue", d0.has("id") and d0.has("options"))
	var ids := {}
	for d in g.eligible_dialogues(50.0, mem):
		ids[d["id"]] = true
	h.check("memory_talk needs runs", not ids.has("memory_talk"))
	h.check("after_crash needs destroyed", not ids.has("after_crash"))
	h.check("after_crash eligible after crash", g.eligible_dialogues(50.0, m2).any(func(x: Dictionary) -> bool: return x["id"] == "after_crash"))
	h.check("music needs trust >= 30", not g.eligible_dialogues(10.0, mem).any(func(x: Dictionary) -> bool: return x["id"] == "music"))
	var last_mem: Dictionary = mem.duplicate(true)
	last_mem["last_dialogue_id"] = "hungry"
	var rng := _rng(77)
	var avoided := true
	for i in range(50):
		if g.pick_dialogue(50.0, last_mem, rng)["id"] == "hungry":
			avoided = false
	h.check("pick_dialogue avoids last dialogue", avoided)
	var hungry: Dictionary = g.find_dialogue("hungry")
	var mm: RefCounted = Momo.new(balance, lines, 50.0)
	var res: Dictionary = g.apply_choice(hungry, "feed_parts", mm, mem)
	h.check("apply_choice ok", res["ok"] and res["reply"] != "" and res["tag"] == "feed")
	h.eq("choice trust applied", mm.trust, 53.0)
	h.eq("choice mood applied", mm.mood, "calm")
	h.eq("choice counted in memory", res["memory"]["choice_counts"]["feed"], 1)
	h.eq("choice remembers dialogue", res["memory"]["last_dialogue_id"], "hungry")
	h.eq("choice next-run modifiers", (res["next_run_modifiers"] as Array).size(), 1)
	h.eq("apply_choice does not mutate memory", mem["choice_counts"], {})
	var tease: Dictionary = g.apply_choice(hungry, "feed_tease", mm, res["memory"])
	h.eq("tease makes sulky", mm.mood, "sulky")
	h.eq("bad option id -> not ok", g.apply_choice(hungry, "nope", mm, mem)["ok"], false)
	var scratch: Dictionary = g.find_dialogue("scratches")
	var ins: Dictionary = g.apply_choice(scratch, "scratch_ugly", null, tease["memory"])
	h.check("insult option counted, works without momo", ins["ok"] and ins["memory"]["insults_total"] == 1)

	# --- upgrades
	var owned := {}
	var offer: Array = g.offer_upgrades(owned, _rng(4))
	h.eq("offer count", offer.size(), int(balance["garage"]["upgrade_offer_count"]))
	var offered_ids := {}
	for u in offer:
		offered_ids[u["id"]] = true
	h.eq("offer has no duplicates", offered_ids.size(), offer.size())
	h.eq("offer next_level 1", offer[0]["next_level"], 1)
	owned = g.apply_upgrade(owned, "armor")
	owned = g.apply_upgrade(owned, "armor")
	h.eq("armor level 2", owned["armor"], 2)
	for i in range(5):
		owned = g.apply_upgrade(owned, "armor")
	h.eq("armor capped at max", owned["armor"], 3)
	h.eq("unknown upgrade ignored", g.apply_upgrade(owned, "laser"), owned)
	var all_ids: Array = []
	for u in g.offer_upgrades(owned, null, 99):
		all_ids.append(u["id"])
	h.check("maxed upgrade not offered", not all_ids.has("armor") and not all_ids.has("turbo") and not all_ids.has("bull_bar") and all_ids.has("quick_trigger"))
	owned = g.apply_upgrade(owned, "quick_trigger")
	owned = g.apply_upgrade(owned, "calm_core")
	owned = g.apply_upgrade(owned, "extra_mine")
	var eff: Dictionary = g.effective_balance(balance, owned, res["next_run_modifiers"])
	h.eq("armor +60 hp", float(eff["run"]["player"]["max_hp"]), float(balance["run"]["player"]["max_hp"]) + 60.0)
	h.near("cooldown x0.85", float(eff["run"]["weapon"]["cooldown"]), float(balance["run"]["weapon"]["cooldown"]) * 0.85, 0.0001)
	h.eq("mine +1 upgrade +1 feed", float(eff["run"]["mine"]["count"]), float(balance["run"]["mine"]["count"]) + 2.0)
	h.near("calm core lowers scared refuse", float(eff["momo"]["scared"]["attack_refuse_probability"]), float(balance["momo"]["scared"]["attack_refuse_probability"]) * 0.75, 0.0001)
	h.eq("effective_balance does not mutate base", float(balance["run"]["player"]["max_hp"]), 100.0)
	var odd: Dictionary = Garage.apply_modifiers({"a": {"b": 1}}, [{"path": "x.y", "op": "add", "value": 1}, {"path": "a.b", "op": "mul", "value": 3}, "junk", {"path": "a.c", "op": "set", "value": 5}])
	h.eq("apply_modifiers skips unknown paths", odd, {"a": {"b": 3.0, "c": 5}})
	var calm_momo: RefCounted = Momo.new(eff, lines, 50.0)
	h.near("momo reads upgraded balance", calm_momo._num("scared.attack_refuse_probability", 0.0), 0.225, 0.0001)

	# --- save store
	var store: RefCounted = SaveStore.new(TEST_PATH)
	store.clear()
	var missing: Dictionary = store.load_data()
	h.check("missing file -> defaults", missing == store.defaults() and store.last_error == "missing")
	var state := {"version": 1, "trust": 73.5, "memory": m3, "upgrades": owned}
	h.check("save ok", store.save_data(state) and store.exists())
	var back: Dictionary = store.load_data()
	h.eq("round-trip trust", back["trust"], 73.5)
	h.eq("round-trip memory runs", back["memory"]["runs"], 2)
	h.eq("round-trip memory outcome", back["memory"]["last_outcome"], "survived")
	h.eq("round-trip upgrades", back["upgrades"], {"armor": 3, "quick_trigger": 1, "calm_core": 1, "extra_mine": 1})
	h.eq("round-trip version", back["version"], SaveStore.VERSION)
	h.eq("no error after good load", store.last_error, "")
	h.check("tmp file removed", not FileAccess.file_exists(TEST_PATH + ".tmp"))
	for bad in ["{not json", "", "[1,2,3]", "\u0000\u0001garbage", "null"]:
		_write(TEST_PATH, bad)
		var got: Dictionary = store.load_data()
		h.check("corrupt file %s -> defaults" % JSON.stringify(bad), got == store.defaults() and store.last_error == "corrupt")
	_write(TEST_PATH, "{\"trust\": 999, \"memory\": \"x\", \"upgrades\": {\"armor\": \"lots\", \"turbo\": 2}}")
	var partial: Dictionary = store.load_data()
	h.check("wrong types sanitized", partial["trust"] == 100.0 and partial["memory"] == Garage.default_memory() and partial["upgrades"] == {"turbo": 2})
	_write(TEST_PATH, "{\"version\": 7, \"trust\": 40}")
	var newer: Dictionary = store.load_data()
	h.check("newer version loads tolerantly", newer["trust"] == 40.0 and store.last_error == "newer_version")
	var momo_load: RefCounted = Momo.new(balance, lines)
	momo_load.load_save(back)
	h.eq("momo trust from save", momo_load.trust, 73.5)
	store.clear()
	h.check("clear removes file", not store.exists())
	h.eq("default store path", SaveStore.new().path, "user://save.json")

	quit(h.finish())
