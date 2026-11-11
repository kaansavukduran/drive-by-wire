extends RefCounted
## Drive-By Wire command parser: typed text -> Array of command dictionaries.
##
## Pure, deterministic and data-driven (data/intents.json + data/balance.json
## "parser" section). Never raises: unknown text becomes an "unknown" command,
## empty text yields an empty Array. See scripts/core/README.md.

const DataLoader := preload("res://scripts/core/data_loader.gd")

const INTENTS: PackedStringArray = [
	"lane_left", "lane_right", "speed_up", "slow_down", "fire",
	"drop_mine", "dodge", "ram", "comfort", "insult",
]
const UNKNOWN := "unknown"
const TARGETED_INTENTS: PackedStringArray = ["fire", "ram"]

## Characters folded to plain ASCII after lowercasing.
const FOLD := {
	"ı": "i", "ş": "s", "ğ": "g", "ç": "c", "ö": "o", "ü": "u",
	"â": "a", "î": "i", "û": "u", "ä": "a", "é": "e", "è": "e", "ë": "e",
}
## Removed without leaving a gap, so "kamyon'a" reads as "kamyona".
const JOINERS := "'’‘`´"
## Punctuation kept as its own token so it can act as a chain separator.
const PUNCT_TOKENS := ",;.!?:"

var fuzzy_min_length: int = 4
var short_word_max_length: int = 6
var short_max_distance: int = 1
var long_max_distance: int = 2
var suffix_min_root_length: int = 3
var intent_suffix_min_root_length: int = 4
## When true, swapping two adjacent letters costs 1 (optimal string alignment).
var transposition_costs_one: bool = true

## Each entry: {kind: "intent"|"type"|"position"|"side"|"lane_side",
##              value: String, tokens: PackedStringArray, order: int}
var _entries: Array = []
var _separators: Array = []  # Array of PackedStringArray, longest first
var _suffixes: Dictionary = {}
var _blocklist: Dictionary = {}


## `intents` and `balance` are the parsed JSON dictionaries. Pass nothing to
## load the default files from res://data/.
func _init(intents: Dictionary = {}, balance: Dictionary = {}) -> void:
	if intents.is_empty():
		intents = DataLoader.load_json(DataLoader.INTENTS_PATH)
	if balance.is_empty():
		balance = DataLoader.load_json(DataLoader.BALANCE_PATH)
	_configure(balance)
	_build(intents)


func _configure(balance: Dictionary) -> void:
	fuzzy_min_length = int(DataLoader.num(balance, "parser.fuzzy_min_length", 4))
	short_word_max_length = int(DataLoader.num(balance, "parser.short_word_max_length", 6))
	short_max_distance = int(DataLoader.num(balance, "parser.short_max_distance", 1))
	long_max_distance = int(DataLoader.num(balance, "parser.long_max_distance", 2))
	suffix_min_root_length = int(DataLoader.num(balance, "parser.suffix_min_root_length", 3))
	intent_suffix_min_root_length = int(DataLoader.num(balance, "parser.intent_suffix_min_root_length", 4))
	transposition_costs_one = bool(DataLoader.dig(balance, "parser.transposition_costs_one", true))


func _build(data: Dictionary) -> void:
	var order := 0
	var intents: Variant = data.get("intents", {})
	if intents is Dictionary:
		for intent in intents:
			order = _add_phrases("intent", str(intent), intents[intent], order)
	var targets: Variant = data.get("targets", {})
	if targets is Dictionary:
		for kind in ["type", "position", "side"]:
			var group: Variant = targets.get(kind, {})
			if group is Dictionary:
				for value in group:
					order = _add_phrases(kind, str(value), group[value], order)
	var lane_sides: Variant = data.get("lane_side_words", {})
	if lane_sides is Dictionary:
		for value in lane_sides:
			order = _add_phrases("lane_side", str(value), lane_sides[value], order)
	for s in data.get("suffixes", []):
		var n := normalize(str(s)).replace(" ", "")
		if not n.is_empty():
			_suffixes[n] = true
	for w in data.get("fuzzy_blocklist", []):
		var n := normalize(str(w))
		if not n.is_empty():
			_blocklist[n] = true
	for sep in data.get("separators", []):
		var toks := tokenize(str(sep))
		if toks.size() > 0:
			_separators.append(toks)
	_separators.sort_custom(func(a: PackedStringArray, b: PackedStringArray) -> bool: return a.size() > b.size())


func _add_phrases(kind: String, value: String, phrases: Variant, order: int) -> int:
	if not phrases is Array:
		return order
	for p in phrases:
		var toks := tokenize(str(p))
		var clean := PackedStringArray()
		for t in toks:
			if not PUNCT_TOKENS.contains(t):
				clean.append(t)
		if clean.is_empty():
			continue
		_entries.append({"kind": kind, "value": value, "tokens": clean, "order": order})
		order += 1
	return order


# ---------------------------------------------------------------------------
# Normalization
# ---------------------------------------------------------------------------

## Lowercases (Turkish-aware for İ/I), folds Turkish letters to ASCII and
## splits into tokens. Separator punctuation (, ; . ! ? :) is kept as tokens,
## all other punctuation becomes whitespace.
static func tokenize(text: String) -> PackedStringArray:
	var t := text.replace("İ", "i").replace("I", "i").to_lower().replace("̇", "")
	var buf := ""
	for ch in t:
		var c: String = FOLD.get(ch, ch)
		if JOINERS.contains(c):
			continue
		if PUNCT_TOKENS.contains(c):
			buf += " " + c + " "
			continue
		var code := c.unicode_at(0)
		var is_ascii_alnum := (code >= 97 and code <= 122) or (code >= 48 and code <= 57)
		if is_ascii_alnum or (code > 127 and not "“”«»…–—•·°€£".contains(c)):
			buf += c
		else:
			buf += " "
	return buf.split(" ", false)


## Normalized text without punctuation: "Sağa GEÇ!" -> "saga gec".
static func normalize(text: String) -> String:
	var out := PackedStringArray()
	for tok in tokenize(text):
		if not PUNCT_TOKENS.contains(tok):
			out.append(tok)
	return " ".join(out)


## Levenshtein distance. With max_distance >= 0 it stops early and returns
## max_distance + 1 once the distance is known to exceed it. With
## `transpositions` an adjacent swap ("rigth") counts as one edit.
static func levenshtein(a: String, b: String, max_distance: int = -1, transpositions: bool = false) -> int:
	var la := a.length()
	var lb := b.length()
	if max_distance >= 0 and absi(la - lb) > max_distance:
		return max_distance + 1
	if la == 0:
		return lb
	if lb == 0:
		return la
	var prev2 := PackedInt32Array()
	var prev := PackedInt32Array()
	var cur := PackedInt32Array()
	prev2.resize(lb + 1)
	prev.resize(lb + 1)
	cur.resize(lb + 1)
	for j in range(lb + 1):
		prev[j] = j
	for i in range(1, la + 1):
		cur[0] = i
		var row_min := i
		for j in range(1, lb + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			cur[j] = mini(mini(prev[j] + 1, cur[j - 1] + 1), prev[j - 1] + cost)
			if transpositions and i > 1 and j > 1 and a[i - 1] == b[j - 2] and a[i - 2] == b[j - 1]:
				cur[j] = mini(cur[j], prev2[j - 2] + 1)
			row_min = mini(row_min, cur[j])
		if max_distance >= 0 and row_min > max_distance:
			return max_distance + 1
		var tmp := prev2
		prev2 = prev
		prev = cur
		cur = tmp
	return prev[lb]


# ---------------------------------------------------------------------------
# Parsing
# ---------------------------------------------------------------------------

## Parses typed text into an ordered Array of command dictionaries:
##   {"intent": String, "text": String, "fuzzy": bool, "index": int}
##   fire/ram also carry "target": {"type": String, "position": String, "side": String}
##   ("" when not given). Unrecognized segments give {"intent": "unknown", ...}.
func parse(text: String) -> Array:
	var tokens := tokenize(text)
	var commands: Array = []
	for segment in _split_segments(tokens):
		_parse_segment(segment, commands)
	for i in range(commands.size()):
		commands[i]["index"] = i
	return commands


## Convenience: just the intent names, e.g. ["lane_right", "fire"].
func parse_intents(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	for c in parse(text):
		out.append(c["intent"])
	return out


func _split_segments(tokens: PackedStringArray) -> Array:
	var segments: Array = []
	var cur := PackedStringArray()
	var i := 0
	while i < tokens.size():
		var sep_len := _separator_at(tokens, i)
		if sep_len > 0:
			if not cur.is_empty():
				segments.append(cur)
			cur = PackedStringArray()
			i += sep_len
			continue
		if not PUNCT_TOKENS.contains(tokens[i]):
			cur.append(tokens[i])
		i += 1
	if not cur.is_empty():
		segments.append(cur)
	return segments


func _separator_at(tokens: PackedStringArray, i: int) -> int:
	for sep in _separators:
		var n: int = sep.size()
		if i + n > tokens.size():
			continue
		var ok := true
		for k in range(n):
			if tokens[i + k] != sep[k]:
				ok = false
				break
		if ok:
			return n
	return 0


func _parse_segment(tokens: PackedStringArray, out: Array) -> void:
	var matches: Array = []  # {kind, value, cost}
	var i := 0
	while i < tokens.size():
		var best := _best_match_at(tokens, i)
		if best.is_empty():
			i += 1
			continue
		matches.append(best)
		i += int(best["length"])
	var has_attack := false
	var has_intent := false
	for m in matches:
		if m["kind"] == "intent":
			has_intent = true
			if TARGETED_INTENTS.has(m["value"]):
				has_attack = true
	var text := " ".join(tokens)
	if not has_intent:
		# Bare side words ("sola!", "right") become lane changes.
		for m in matches:
			if m["kind"] == "lane_side":
				has_intent = true
		if not has_intent:
			out.append({"intent": UNKNOWN, "text": text, "fuzzy": false})
			return
	var target := {"type": "", "position": "", "side": ""}
	for m in matches:
		var kind: String = m["kind"]
		if kind == "type" or kind == "position" or kind == "side":
			if target[kind] == "":
				target[kind] = m["value"]
		elif kind == "lane_side" and has_attack and target["side"] == "":
			target["side"] = m["value"]
	for m in matches:
		var kind: String = m["kind"]
		var fuzzy: bool = int(m["cost"]) > 0
		if kind == "intent":
			var cmd := {"intent": m["value"], "text": text, "fuzzy": fuzzy}
			if TARGETED_INTENTS.has(m["value"]):
				cmd["target"] = target.duplicate()
			out.append(cmd)
		elif kind == "lane_side" and not has_attack:
			out.append({"intent": "lane_left" if m["value"] == "left" else "lane_right", "text": text, "fuzzy": fuzzy})


## Best phrase starting at token i: longest first, then lowest edit cost,
## then data order. Returns {} when nothing matches.
func _best_match_at(tokens: PackedStringArray, i: int) -> Dictionary:
	var best := {}
	var best_len := 0
	var best_cost := 1 << 20
	var best_order := 1 << 20
	for e in _entries:
		var etoks: PackedStringArray = e["tokens"]
		var n := etoks.size()
		if n < best_len or i + n > tokens.size():
			continue
		var is_intent: bool = e["kind"] == "intent"
		var total := 0
		var ok := true
		for k in range(n):
			var c := _word_cost(tokens[i + k], etoks[k], k == n - 1, is_intent)
			if c < 0:
				ok = false
				break
			total += c
		if not ok:
			continue
		var better := false
		if n > best_len:
			better = true
		elif total < best_cost or (total == best_cost and int(e["order"]) < best_order):
			better = true
		if better:
			best_len = n
			best_cost = total
			best_order = int(e["order"])
			best = {"kind": e["kind"], "value": e["value"], "cost": total, "length": n}
	return best


## 0 = exact (or root + known suffix), >0 = fuzzy edit distance, -1 = no match.
func _word_cost(token: String, word: String, allow_suffix: bool, is_intent: bool) -> int:
	if token == word:
		return 0
	var min_root := intent_suffix_min_root_length if is_intent else suffix_min_root_length
	if allow_suffix and word.length() >= min_root and token.length() > word.length() and token.begins_with(word):
		if _suffixes.has(token.substr(word.length())):
			return 0
	if _blocklist.has(token):
		return -1
	if word.length() < fuzzy_min_length or token.length() < fuzzy_min_length:
		return -1
	var max_d := short_max_distance if word.length() <= short_word_max_length else long_max_distance
	var d := levenshtein(token, word, max_d, transposition_costs_one)
	return d if d <= max_d else -1
