extends RefCounted
## A small local episode layered over the existing arcade loop.
const DATA_PATH := "res://data/journey.json"
var data: Dictionary
var route := "steady"
var next_beat := 0
var observed_distance:=0.0
var log_lines: Array[String] = []
func _init(selected := "steady") -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	route = selected if data["routes"].has(selected) else "steady"
	log_lines.append(str(data["chapter"]))
	log_lines.append(str(data["premise"]))
	log_lines.append(str(spec()["name"])+" · "+str(spec()["effect"]))
	log_lines.append(str(data["routes"][route]["opening"]))
func spec() -> Dictionary:
	return data["routes"][route]
func advance(distance: float) -> Array[String]:
	observed_distance=distance
	var fresh: Array[String] = []
	while next_beat < data["beats"].size() and distance >= float(data["beats"][next_beat]["distance"]):
		var line: String = data["beats"][next_beat]["line"]
		fresh.append(line)
		log_lines.append(line)
		next_beat += 1
	return fresh
func goal_met(comforts: int, collected: int) -> bool:
	return observed_distance>=400 if route=="survive" else (comforts>0 if route=="steady" else collected>=2)
func goal_text(comforts: int, collected: int) -> String:
	if route=="survive":return "Yolu aç · %d / 400 m" % mini(400,int(observed_distance))
	return "%s · %d/%d" % [spec()["objective"],mini(comforts,1) if route=="steady" else mini(collected,2),1 if route=="steady" else 2]
func ending(survived: bool, comforts: int, collected: int) -> String:
	if not survived: return str(data["failure"])
	return str(spec()["success"] if goal_met(comforts,collected) else spec()["partial"])

func configure_book(state: Dictionary) -> void:
	const Book = preload("res://scripts/core/story_book.gd")
	var selected: Dictionary=Book.current(state)
	if selected.is_empty(): return
	route=str(selected["goal"])
	var stage: int=state["stage"]
	var chapter: String=Book.node(state)["title"]
	data={"chapter":chapter,"premise":Book.node(state)["text"],"routes":{route:selected},"beats":[],"failure":"Bu etap tamamlanmadı. Önceki kararların korunuyor; bu ayrımdan yeniden deneyebiliriz."}
	var lines: Array=Book.node(state)["beats"]
	for i in 3:
		data["beats"].append({"distance":[100,220,340][i],"line":lines[i]})
	data["routes"][route]=selected.duplicate(true)
	data["routes"][route]["success"]="Yol açık. Arkadaşlarının sesini dinle; ara sahneye geçelim."
	data["routes"][route]["partial"]="Geçide ulaştık. İkmal hedefi eksik kaldı; hikâyeye devam edebiliriz."
	log_lines.clear()
	next_beat=0
	log_lines.assign([chapter,"Kararların: "+" → ".join(Book.path_labels(state)),str(data["premise"]),str(selected["name"]),str(selected["effect"])])
	for line in Book.node(state).get("conversation",[]):
		log_lines.append(str(Book.data().get("speakers",{}).get(line["speaker"],line["speaker"]))+": "+str(line["line"]))
	var reply: Dictionary=Book.radio_reply(state)
	if not reply.is_empty():
		log_lines.append("Aion: "+str(reply["text"]))
		log_lines.append(str(reply["reply"]))
