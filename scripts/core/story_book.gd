extends RefCounted
## A linear campaign. Dialogue changes replies, never the route or ending.
const RoadStory=preload("res://scripts/core/road_story.gd")
const CliffStory=preload("res://scripts/core/cliff_story.gd")
const PATH="res://data/story_book.json"
const FORMAT="linear-v1"
const AVAILABLE=2
const PLANNED=13
static var _data: Dictionary={}
static func data() -> Dictionary:
 if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 return _data
static func defaults(unlocked: Array=[]) -> Dictionary:
 return {"format":FORMAT,"stage":0,"phase":"briefing","choices":[],"active":false,"unlocked":unlocked.duplicate(),"failures":0,"score":0,"goals_completed":0,"radio":{},"bonds":{},"chapter2":RoadStory.defaults(),"cliff":CliffStory.defaults(),"legacy":{}}
static func node_key(state: Dictionary) -> String:return "chapter_%02d" % (mini(int(state.get("stage",0)),AVAILABLE-1)+1)
static func node(state: Dictionary) -> Dictionary:return data()["nodes"][node_key(state)]
static func _number(value: Variant,maximum: int=2000000000) -> int:
 return clampi(int(value),0,maximum) if (value is int or value is float) and is_finite(float(value)) else 0
static func sanitize(raw: Variant) -> Dictionary:
 var out:=defaults()
 if not raw is Dictionary:return out
 for field in ["failures","score","goals_completed"]:out[field]=_number(raw.get(field))
 out["chapter2"]=RoadStory.sanitize(raw.get("chapter2",{}));out["cliff"]=CliffStory.sanitize(raw.get("cliff",{}))
 for id in raw.get("unlocked",[]) if raw.get("unlocked") is Array else []:
  if id is String and id in ["e01","e02","e03","e04","e05","e06","e07","e08","e09","e10","e11","e12","e13"] and not id in out["unlocked"]:out["unlocked"].append(id)
 if raw.get("bonds") is Dictionary:
  for who in ["aion","omega","kurt","kuzu","omer","emre","eren"]:
   if raw["bonds"].has(who):out["bonds"][who]=_number(raw["bonds"][who],3)
 if raw.get("format")==FORMAT:
  out["stage"]=_number(raw.get("stage"),AVAILABLE)
  out["phase"]=str(raw.get("phase","briefing")) if raw.get("phase") in ["briefing","combat","interlude","continued"] else "briefing"
  if out["stage"]==AVAILABLE:out["phase"]="continued"
  elif out["phase"]=="continued":out["phase"]="briefing"
  if raw.get("legacy") is Dictionary:out["legacy"]=_legacy(raw["legacy"])
  if raw.get("radio") is Dictionary:
   for key in data()["nodes"]:
    for reply in data()["nodes"][key]["responses"]:
     if raw["radio"].get(key)==reply["id"]:out["radio"][key]=reply["id"]
 else:
  # Retain old branching results as an archive; never silently erase progress.
  out["legacy"]=_legacy(raw)
  var old_stage:=_number(raw.get("stage"),3)
  if old_stage>=2:out["stage"]=1
  elif old_stage==1:out["phase"]="interlude"
  elif raw.get("active")==true:out["phase"]="combat"
 out["active"]=out["phase"]=="combat"
 out["choices"]=["depart"] if out["active"] else []
 out["goals_completed"]=mini(out["goals_completed"],AVAILABLE)
 return out
static func _legacy(raw: Dictionary) -> Dictionary:
 var out: Dictionary={}
 for key in ["stage","score","failures","goals_completed"]:
  if raw.has(key):out[key]=_number(raw[key])
 for key in ["choices","unlocked"]:
  if raw.get(key) is Array:out[key]=raw[key].filter(func(v):return v is String and v.length()<=40).slice(0,13)
 if raw.get("active") is bool:out["active"]=raw["active"]
 return out
static func answer(state: Dictionary,id: String) -> Dictionary:
 var out:=sanitize(state);var key:=node_key(out)
 if out["phase"]!="briefing" or out["radio"].has(key):return out
 for reply in node(out)["responses"]:
  if reply["id"]==id:out["radio"][key]=id
 return out
static func radio_reply(state: Dictionary) -> Dictionary:
 var id: String=state.get("radio",{}).get(node_key(state),"")
 for reply in node(state)["responses"]:
  if reply["id"]==id:return reply
 return {}
static func choose(state: Dictionary,id: String) -> Dictionary:
 var out:=sanitize(state)
 if id!="depart" or out["stage"]>=AVAILABLE or out["phase"] not in ["briefing","combat"]:return out
 out["phase"]="combat";out["active"]=true;out["choices"]=["depart"]
 return out
static func current(state: Dictionary) -> Dictionary:return node(state)["choices"][0] if state.get("active",false) else {}
static func complete(state: Dictionary,survived: bool,score: int,goal: bool) -> Dictionary:
 var out:=sanitize(state)
 if not out["active"]:return out
 out["active"]=false;out["choices"]=[]
 if survived:
  out["phase"]="interlude";out["score"]=mini(2000000000,out["score"]+maxi(0,score))
  if goal:out["goals_completed"]=mini(AVAILABLE,out["goals_completed"]+1)
 else:out["phase"]="briefing";out["failures"]+=1
 return out
static func finish_interlude(state: Dictionary) -> Dictionary:
 var out:=sanitize(state)
 if out["phase"]!="interlude":return out
 out["stage"]+=1;out["phase"]="continued" if out["stage"]==AVAILABLE else "briefing"
 return out
static func ending(_state: Dictionary) -> Dictionary:return {} # No branching ending claims in this edition.
static func path_labels(state: Dictionary) -> Array[String]:
 var out: Array[String]=[]
 for i in mini(int(state.get("stage",0))+1,AVAILABLE):out.append(str(data()["nodes"]["chapter_%02d"%(i+1)]["title"]))
 return out
