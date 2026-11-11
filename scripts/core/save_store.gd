extends RefCounted
## Local save of MOMO's persistent state: trust, memory and owned upgrades.
## Tolerant: a missing, empty, corrupt or wrong-typed file loads as defaults
## and never crashes. Writes go to "<path>.tmp" first, then replace the file.
##
## File shape (version 1):
##   {"version": 1, "trust": float, "memory": {...garage.default_memory()},
##    "upgrades": {upgrade_id: level}}

const Garage := preload("res://scripts/core/garage.gd")

const VERSION := 1
const DEFAULT_PATH := "user://save.json"

var path: String = DEFAULT_PATH
var default_trust: float = 50.0
## Human-readable reason for the last fallback or failure ("" when fine).
var last_error: String = ""


func _init(save_path: String = DEFAULT_PATH, trust_default: float = 50.0) -> void:
	path = save_path
	default_trust = trust_default


func defaults() -> Dictionary:
	return {"version": VERSION, "trust": default_trust, "memory": Garage.default_memory(), "upgrades": {}}


func exists() -> bool:
	return FileAccess.file_exists(path)


## Always returns a complete, valid save dictionary.
func load_data() -> Dictionary:
	last_error = ""
	if not FileAccess.file_exists(path):
		last_error = "missing"
		return defaults()
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		last_error = "unreadable"
		return defaults()
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if text.strip_edges().is_empty() or json.parse(text) != OK or not json.data is Dictionary:
		last_error = "corrupt"
		return defaults()
	return sanitize(json.data)


## Fills gaps and fixes types; clamps trust to 0..100. Unknown keys dropped.
func sanitize(raw: Dictionary) -> Dictionary:
	var out := defaults()
	var t: Variant = raw.get("trust", null)
	if t is float or t is int:
		out["trust"] = clampf(float(t), 0.0, 100.0)
	out["memory"] = Garage.sanitize_memory(raw.get("memory", {}))
	var ups: Variant = raw.get("upgrades", {})
	if ups is Dictionary:
		var clean := {}
		for k in ups:
			if ups[k] is int or ups[k] is float:
				clean[str(k)] = maxi(0, int(ups[k]))
		out["upgrades"] = clean
	var v: Variant = raw.get("version", VERSION)
	if (v is int or v is float) and int(v) > VERSION:
		last_error = "newer_version"
	return out


## Writes a sanitized copy. Returns true on success.
func save_data(state: Dictionary) -> bool:
	last_error = ""
	var clean := sanitize(state)
	clean["version"] = VERSION
	var text := JSON.stringify(clean, "  ")
	var tmp := path + ".tmp"
	var dir := path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		last_error = "cannot_write"
		return false
	f.store_string(text)
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if DirAccess.rename_absolute(tmp, path) != OK:
		last_error = "cannot_rename"
		return false
	return true


## Deletes the save (for "new game" / tests).
func clear() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
