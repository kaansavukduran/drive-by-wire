extends RefCounted
## Small helpers for reading the JSON data files. Never crashes: a missing or
## malformed file yields the fallback value.

const INTENTS_PATH := "res://data/intents.json"
const BALANCE_PATH := "res://data/balance.json"
const MOMO_LINES_PATH := "res://data/momo_lines.json"
const GARAGE_PATH := "res://data/garage.json"


## Reads `path` and returns the parsed Dictionary, or `fallback` when the file
## is missing, unreadable, malformed or not a JSON object.
static func load_json(path: String, fallback: Dictionary = {}) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback
	var text := FileAccess.get_file_as_string(path)
	return parse_json_text(text, fallback)


## Parses JSON text without printing engine errors on bad input.
static func parse_json_text(text: String, fallback: Dictionary = {}) -> Dictionary:
	if text.strip_edges().is_empty():
		return fallback
	var json := JSON.new()
	if json.parse(text) != OK:
		return fallback
	var data: Variant = json.data
	if data is Dictionary:
		return data
	return fallback


## Nested lookup: dig(balance, "momo.scared.delay_min", 0.6).
static func dig(data: Dictionary, path: String, default_value: Variant = null) -> Variant:
	var cur: Variant = data
	for key in path.split("."):
		if cur is Dictionary and (cur as Dictionary).has(key):
			cur = (cur as Dictionary)[key]
		else:
			return default_value
	return cur


## Nested numeric lookup that always returns a float.
static func num(data: Dictionary, path: String, default_value: float) -> float:
	var v: Variant = dig(data, path, default_value)
	if v is float or v is int:
		return float(v)
	return default_value
