extends SceneTree
## Headless parser tests: godot --headless --path . --script tests/test_parser.gd

const Harness := preload("res://tests/harness.gd")
const Parser := preload("res://scripts/core/command_parser.gd")

## [input, expected intents, optional {target fields}] (target checked on the first fire/ram).
const CASES := [
	# --- Turkish, with Turkish characters
	["sola geç", ["lane_left"]],
	["sağa geç", ["lane_right"]],
	["sola kay", ["lane_left"]],
	["sağ şeride geç", ["lane_right"]],
	["hızlan", ["speed_up"]],
	["gazla", ["speed_up"]],
	["bas gaza", ["speed_up"]],
	["yavaşla", ["slow_down"]],
	["fren", ["slow_down"]],
	["frene bas", ["slow_down"]],
	["ateş et", ["fire"], {"type": "", "position": "", "side": ""}],
	["vur", ["fire"]],
	["mayın bırak", ["drop_mine"]],
	["kaç", ["dodge"]],
	["sıyrıl", ["dodge"]],
	["çarp", ["ram"]],
	["aferin", ["comfort"]],
	["korkma", ["comfort"]],
	["iyi gidiyorsun", ["comfort"]],
	# --- without Turkish characters / caps
	["saga gec", ["lane_right"]],
	["SOLA GEÇ", ["lane_left"]],
	["YAVAŞLA", ["slow_down"]],
	["HIZLAN", ["speed_up"]],
	["ates et", ["fire"]],
	["mayin birak", ["drop_mine"]],
	["siyril", ["dodge"]],
	["İYİ GİDİYORSUN", ["comfort"]],
	# --- English
	["move left", ["lane_left"]],
	["go right", ["lane_right"]],
	["speed up", ["speed_up"]],
	["slow down", ["slow_down"]],
	["brake", ["slow_down"]],
	["fire", ["fire"]],
	["Shoot!", ["fire"]],
	["drop a mine", ["drop_mine"]],
	["dodge", ["dodge"]],
	["ram it", ["ram"]],
	["good job", ["comfort"]],
	["don't worry", ["comfort"]],
	# --- typos (fuzzy)
	["yavsla", ["slow_down"]],
	["hizlna", ["speed_up"]],
	["mayn bırak", ["drop_mine"]],
	["acceleate", ["speed_up"]],
	["sohot", ["fire"]],
	["rigth", ["lane_right"]],
	["aferni", ["comfort"]],
	# --- targeted fire / ram
	["kamyona ateş et", ["fire"], {"type": "truck"}],
	["kamyonete ateş et", ["fire"], {"type": "pickup"}],
	["kamyonet vur", ["fire"], {"type": "pickup"}],
	["kamyon'a ateş", ["fire"], {"type": "truck"}],
	["öndekine ateş", ["fire"], {"position": "front"}],
	["arkadakine ateş et", ["fire"], {"position": "behind"}],
	["en yakına ateş et", ["fire"], {"position": "nearest"}],
	["çarpan arabaya ateş et", ["fire"], {"type": "rammer"}],
	["sağdakine vur", ["fire"], {"side": "right"}],
	["soldaki kamyona ateş et", ["fire"], {"side": "left", "type": "truck"}],
	["sola ateş et", ["fire"], {"side": "left"}],
	["sağa ateş", ["fire"], {"side": "right"}],
	["shoot the truck", ["fire"], {"type": "truck"}],
	["shoot the pickup on the left", ["fire"], {"type": "pickup", "side": "left"}],
	["fire at the nearest", ["fire"], {"position": "nearest"}],
	["kamyona çarp", ["ram"], {"type": "truck"}],
	["ram the rammer", ["ram"], {"type": "rammer"}],
	# --- chained
	["sağa geç ve kamyona ateş et", ["lane_right", "fire"], {"type": "truck", "side": ""}],
	["sola geç sonra hızlan", ["lane_left", "speed_up"]],
	["hızlan, ateş et; mayın bırak", ["speed_up", "fire", "drop_mine"]],
	["slow down and then dodge", ["slow_down", "dodge"]],
	["sağa geç ve sola geç", ["lane_right", "lane_left"]],
	["sola geç. ateş et!", ["lane_left", "fire"]],
	["sola geç ateş et", ["lane_left", "fire"], {"side": ""}],
	["sağa ve ateş", ["lane_right", "fire"], {"side": ""}],
	["sola!", ["lane_left"]],
	# --- insults
	["aptal", ["insult"]],
	["salak araba", ["insult"]],
	["aptalsın", ["insult"]],
	["işe yaramaz hurda", ["insult"]],
	["you are useless", ["insult"]],
	["shut up", ["insult"]],
	# --- tricky pairs / false-positive guards
	["sağ ol", ["comfort"]],
	["kamyon", ["unknown"]],
	["I'm fine", ["unknown"]],
	["merhaba", ["unknown"]],
	["asdf qwerty", ["unknown"]],
	["bugün hava çok güneşli", ["unknown"]],
	["lorem ipsum dolor", ["unknown"]],
	["xyz", ["unknown"]],
	["sola geç ve blablabla", ["lane_left", "unknown"]],
	["123", ["unknown"]],
	["sakin ol", ["comfort"]],
	["hit the brakes", ["slow_down"]],
	["çarpana ateş", ["fire"], {"type": "rammer"}],
	# --- empty
	["", []],
	["   ", []],
	[",,, ;;", []],
]


func _initialize() -> void:
	var h := Harness.new("parser")
	var p := Parser.new()

	for case in CASES:
		var text: String = case[0]
		var expected: Array = case[1]
		var cmds: Array = p.parse(text)
		var got: Array = []
		for c in cmds:
			got.append(c["intent"])
		var ok := got == expected
		var detail := "intents %s" % [str(got)]
		if ok and case.size() > 2:
			var want: Dictionary = case[2]
			var target := {}
			for c in cmds:
				if c.has("target"):
					target = c["target"]
					break
			for k in want:
				if str(target.get(k, "<missing>")) != str(want[k]):
					ok = false
					detail = "target %s, wanted %s" % [str(target), str(want)]
		h.check("parse %-36s -> %s" % ["\"" + text + "\"", str(expected)], ok, detail)

	# Normalization
	h.eq("normalize turkish dotted capital", Parser.normalize("İSTANBUL'a GİT"), "istanbula git")
	h.eq("normalize dotless capital", Parser.normalize("IŞIK ÇOK ĞÜÖ"), "isik cok guo")
	h.eq("normalize punctuation", Parser.normalize("  sağa!!  geç...  "), "saga gec")
	# Levenshtein
	h.eq("levenshtein kitten/sitting", Parser.levenshtein("kitten", "sitting"), 3)
	h.eq("levenshtein early exit", Parser.levenshtein("abcdefgh", "zzzzzzzz", 2), 3)
	h.eq("levenshtein transposition", Parser.levenshtein("rigth", "right", -1, true), 1)
	# Shape checks
	var c0: Dictionary = p.parse("kamyona ateş et")[0]
	h.check("fire command has target dict", c0.has("target") and c0["target"] is Dictionary)
	h.check("fire command has index/text/fuzzy", c0.has("index") and c0.has("text") and c0.has("fuzzy"))
	var lane: Dictionary = p.parse("sola geç")[0]
	h.check("lane command has no target", not lane.has("target"))
	h.eq("exact match is not fuzzy", lane["fuzzy"], false)
	h.eq("typo match is fuzzy", p.parse("yavsla")[0]["fuzzy"], true)
	h.eq("chain indices", [p.parse("sola geç ve ateş")[0]["index"], p.parse("sola geç ve ateş")[1]["index"]], [0, 1])
	# Determinism
	var a := str(p.parse("sağa geç ve kamyonete ateş et, sonra yavaşla"))
	var b := str(Parser.new().parse("sağa geç ve kamyonete ateş et, sonra yavaşla"))
	h.eq("deterministic across instances", a, b)
	# Owner can extend vocabulary through data only
	var custom := {"intents": {"fire": ["pıtırdat"]}, "separators": ["ve"]}
	var p2 := Parser.new(custom, {"parser": {}})
	h.eq("custom data word", p2.parse_intents("PITIRDAT"), PackedStringArray(["fire"]))
	# Robustness against weird input
	var weird := p.parse("🙂🙂 ☃ \t\n ¿¡")
	h.check("emoji-only input never crashes", weird.size() <= 1)
	var long_text := ""
	for i in range(200):
		long_text += "ateş et ve "
	h.eq("long chained input", p.parse(long_text).size(), 200)

	quit(h.finish())
