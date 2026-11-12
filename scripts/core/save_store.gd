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
const MAX_BYTES := 512 * 1024

var path: String = DEFAULT_PATH
var default_trust: float = 50.0
## Human-readable reason for the last fallback or failure ("" when fine).
var last_error: String = ""


func _init(save_path: String = DEFAULT_PATH, trust_default: float = 50.0) -> void:
	path = save_path
	default_trust = trust_default


func defaults() -> Dictionary:
	return {"version": VERSION, "trust": default_trust, "memory": Garage.default_memory(), "upgrades": {}, "best_score": 0, "settings": {"effects": true, "sound": true, "motion": true, "volume": 0.7, "auto_fire": false, "low_power": false, "bindings": {}, "pad_bindings": {}, "deadzone": 0.35, "vibration": false}}


func exists() -> bool:
	return FileAccess.file_exists(path)


## Always returns a complete, valid save dictionary.
func load_data() -> Dictionary:
	last_error = ""
	var result := _read(path)
	if not bool(result["ok"]):
		var backup := _read(path + ".bak")
		if bool(backup["ok"]):
			var data := sanitize(backup["data"])
			last_error = "recovered_" + str(result["error"])
			return data
		last_error = str(result["error"])
		return defaults()
	return sanitize(result["data"])


func _read(candidate: String) -> Dictionary:
	if not FileAccess.file_exists(candidate):
		return {"ok": false, "error": "missing"}
	var f := FileAccess.open(candidate, FileAccess.READ)
	if f == null:
		return {"ok": false, "error": "unreadable"}
	if f.get_length() > MAX_BYTES:
		f.close()
		return {"ok": false, "error": "too_large"}
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if text.strip_edges().is_empty() or json.parse(text) != OK or not json.data is Dictionary:
		return {"ok": false, "error": "corrupt"}
	return {"ok": true, "data": json.data}


## Fills gaps and fixes types; clamps trust to 0..100. Unknown keys dropped.
func sanitize(raw: Dictionary) -> Dictionary:
	var out := defaults()
	var t: Variant = raw.get("trust", null)
	if (t is float or t is int) and is_finite(float(t)):
		out["trust"] = clampf(float(t), 0.0, 100.0)
	out["memory"] = Garage.sanitize_memory(raw.get("memory", {}))
	var score: Variant = raw.get("best_score", 0)
	if (score is float or score is int) and is_finite(float(score)):
		out["best_score"] = int(clampf(float(score), 0, 2000000000))
	var settings: Variant = raw.get("settings", {})
	if settings is Dictionary and settings.get("effects") is bool:
		out["settings"]["effects"] = settings["effects"]
	if settings is Dictionary and settings.get("sound") is bool:
		out["settings"]["sound"] = settings["sound"]
	if settings is Dictionary and settings.get("motion") is bool:
		out["settings"]["motion"] = settings["motion"]
	for key in ["auto_fire", "low_power", "vibration"]:
		if settings is Dictionary and settings.get(key) is bool:
			out["settings"][key] = settings[key]
	if settings is Dictionary and (settings.get("volume") is float or settings.get("volume") is int) and is_finite(float(settings["volume"])):
		out["settings"]["volume"] = clampf(float(settings["volume"]), 0.0, 1.0)
	if settings is Dictionary and settings.get("bindings") is Dictionary:
		const ACTIONS := ["drive_left", "drive_right", "drive_up", "drive_down", "drive_fire", "drive_mine", "drive_dodge", "drive_comfort"]
		for action in ACTIONS:
			var code: Variant = settings["bindings"].get(action)
			if (code is int or code is float) and is_finite(float(code)) and int(code) > 0 and int(code) < (1 << 25):
				out["settings"]["bindings"][action] = int(code)
	if settings is Dictionary and settings.get("pad_bindings") is Dictionary:
		for action in ["drive_left", "drive_right", "drive_up", "drive_down", "drive_fire", "drive_mine", "drive_dodge", "drive_comfort"]:
			var button: Variant = settings["pad_bindings"].get(action)
			if (button is int or button is float) and is_finite(float(button)) and int(button) >= 0 and int(button) <= 14:
				out["settings"]["pad_bindings"][action] = int(button)
	if settings is Dictionary and (settings.get("deadzone") is float or settings.get("deadzone") is int) and is_finite(float(settings["deadzone"])):
		out["settings"]["deadzone"] = clampf(float(settings["deadzone"]), 0.2, 0.6)
	var ups: Variant = raw.get("upgrades", {})
	if ups is Dictionary:
		var clean := {}
		for k in ups:
			if clean.size() >= 32:
				break
			if str(k).length() <= 64 and (ups[k] is int or ups[k] is float) and is_finite(float(ups[k])):
				clean[str(k)] = int(clampf(float(ups[k]), 0, 99))
		out["upgrades"] = clean
	var v: Variant = raw.get("version", VERSION)
	if (v is int or v is float) and int(v) > VERSION:
		last_error = "newer_version"
	return out


## Writes a sanitized copy. Returns true on success.
func save_data(state: Dictionary) -> bool:
	last_error = ""
	var previous := _read(path)
	var protected := previous if bool(previous["ok"]) else _read(path + ".bak")
	var existing_version: Variant = protected.get("data", {}).get("version", VERSION)
	if (existing_version is int or existing_version is float) and float(existing_version) > VERSION:
		last_error = "newer_version"
		return false
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
	f.flush()
	var write_error := f.get_error()
	f.close()
	if write_error != OK:
		last_error = "cannot_write"
		return false
	if bool(previous["ok"]) and DirAccess.copy_absolute(path, path + ".bak") != OK:
		last_error = "cannot_backup"
		return false
	# Same-directory replacement: never delete the current record before rename.
	if _replace(tmp, path) != OK:
		last_error = "cannot_rename"
		return false
	return true


func _replace(source: String, destination: String) -> Error:
	return DirAccess.rename_absolute(source, destination)


## Deletes the save (for "new game" / tests).
func clear() -> bool:
	var ok := true
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			if DirAccess.remove_absolute(path + suffix) != OK:
				ok = false
	last_error = "" if ok else "cannot_delete"
	return ok
