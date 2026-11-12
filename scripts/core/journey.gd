extends RefCounted
## A small local episode layered over the existing arcade loop.
const DATA_PATH := "res://data/journey.json"
var data: Dictionary
var route := "steady"
var next_beat := 0
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
	var fresh: Array[String] = []
	while next_beat < data["beats"].size() and distance >= float(data["beats"][next_beat]["distance"]):
		var line: String = data["beats"][next_beat]["line"]
		fresh.append(line)
		log_lines.append(line)
		next_beat += 1
	return fresh
func goal_met(comforts: int, collected: int) -> bool:
	return comforts > 0 if route == "steady" else collected >= 2
func goal_text(comforts: int, collected: int) -> String:
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
	for i in 3:
		data["beats"].append({"distance":[100,220,340][i],"line":Book.data()["beats"][stage][i]})
	data["routes"][route]=selected.duplicate(true)
	data["routes"][route]["success"]="Kararımızın yolunu açtık. Bir sonraki ayrımı birlikte seçelim."
	data["routes"][route]["partial"]="Geçide ulaştık. Yol hedefini kaçırdık; seçimimiz ve hikâyemiz yine de ilerliyor."
	log_lines.clear()
	next_beat=0
	log_lines.assign([chapter,"Kararların: "+" → ".join(Book.path_labels(state)),str(data["premise"]),str(selected["name"]),str(selected["effect"])])
