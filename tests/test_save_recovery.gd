extends SceneTree
const Harness := preload("res://tests/harness.gd")
const Store := preload("res://scripts/core/save_store.gd")
class FailedRename extends "res://scripts/core/save_store.gd":
 func _replace(_source: String,_destination: String) -> Error:
  return ERR_CANT_CREATE
var h := Harness.new("save_recovery")
func write(path: String,value: String) -> void:
 var f := FileAccess.open(path,FileAccess.WRITE)
 f.store_string(value)
 f.close()
func _initialize() -> void:
 var path := "user://recovery-test.json"
 var store := Store.new(path)
 store.clear()
 var data: Dictionary = store.defaults()
 data["best_score"]=42
 h.check("initial record writes",store.save_data(data))
 data["best_score"]=84
 h.check("replacement writes",store.save_data(data))
 h.eq("primary is newest",store.load_data()["best_score"],84)
 write(path,"{broken")
 h.eq("corrupt primary recovers previous valid record",store.load_data()["best_score"],42)
 h.eq("recovery reason remains visible",store.last_error,"recovered_corrupt")
 data["best_score"]=99
 h.check("saving recovered record succeeds",store.save_data(data))
 var failed := FailedRename.new(path)
 data["best_score"]=200
 h.check("injected rename failure is reported",not failed.save_data(data) and failed.last_error=="cannot_rename")
 h.eq("failed replacement preserves current primary",store.load_data()["best_score"],99)
 DirAccess.remove_absolute(path)
 h.eq("missing primary recovers backup",store.load_data()["best_score"],99)
 write(path," ".repeat(Store.MAX_BYTES+1))
 h.eq("oversize record falls back to backup",store.load_data()["best_score"],99)
 h.eq("size limit is reported",store.last_error,"recovered_too_large")
 write(path,'{"version":999,"best_score":123}')
 h.check("future schema cannot be overwritten",not store.save_data(data) and store.last_error=="newer_version")
 h.check("future record is preserved byte for byte",FileAccess.get_file_as_string(path).contains('999'))
 h.check("confirmed reset removes primary backup and pending temp",store.clear() and not FileAccess.file_exists(path) and not FileAccess.file_exists(path+".bak") and not FileAccess.file_exists(path+".tmp"))
 var clean: Dictionary = store.sanitize({"trust":NAN,"best_score":INF,"memory":{"runs":INF},"settings":{"volume":NAN,"deadzone":INF,"bindings":{"drive_left":INF,"unknown":65},"pad_bindings":{"drive_fire":99}}})
 h.eq("non-finite trust defaults",clean["trust"],50.0)
 h.eq("non-finite score defaults",clean["best_score"],0)
 h.eq("non-finite volume defaults",clean["settings"]["volume"],0.7)
 h.eq("invalid key and button codes are discarded",[clean["settings"]["bindings"],clean["settings"]["pad_bindings"]],[{},{}])
 quit(h.finish())
