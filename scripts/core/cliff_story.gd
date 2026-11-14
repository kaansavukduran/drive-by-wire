extends RefCounted
## One authored rescue; timeline positions are deterministic, not gameplay physics.
const PATH="res://data/cliff_story.json"
const STEPS=["approach","impact","brake","exit","check","thanks","wreck","promise","complete"]
static var _data: Dictionary={}
static func data() -> Dictionary:
 if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 return _data
static func defaults() -> Dictionary:return {"step":"approach","reply":""}
static func sanitize(raw: Variant) -> Dictionary:
 var out:=defaults()
 if raw is Dictionary:
  if raw.get("step") in STEPS:out["step"]=raw["step"]
  if raw.get("reply") in ["shaken","joke"]:out["reply"]=raw["reply"]
 return out
static func advance(raw: Dictionary) -> Dictionary:
 var out:=sanitize(raw);out["step"]=STEPS[mini(STEPS.find(out["step"])+1,STEPS.size()-1)];return out
static func choose(raw: Dictionary,id: String) -> Dictionary:
 var out:=sanitize(raw)
 if out["step"]=="check" and id in ["shaken","joke"]:out["reply"]=id;out["step"]="thanks"
 return out
static func duration(step: String) -> float:return float(data()["nodes"][step].get("duration",0))
static func poses(step: String,time: float,reduced: bool=false) -> Dictionary:
 var t:=clampf(time/maxf(.01,duration(step)),0,1)
 var a:=Vector2(318,250);var k:=Vector2(76,180)
 var index:=STEPS.find(step)
 if index==0:
  a=a.lerp(Vector2(318,168),t);k=k.lerp(Vector2(273,168),t)
 elif index==1:
  a=Vector2(318,168).lerp(Vector2(386,176),t);k=Vector2(273,168).lerp(Vector2(341,176),t)
 else:a=Vector2(400,198);k=Vector2(355,198)
 if index==2:
  a=Vector2(386,176).lerp(a,t);k=Vector2(341,176).lerp(k,t)
 var kurt_foot:=Vector2(365,238);var aion_foot:=Vector2(432,237)
 if index==3:kurt_foot=Vector2(346,232).lerp(kurt_foot,t)
 var frame:=0 if index<4 and reduced else (int(time*7)%2 if index==3 else (2 if step=="check" else 3))
 return {"aion_car":a,"kurt_car":k,"aion_foot":aion_foot,"kurt_foot":kurt_foot,"frame":frame,"wrecked":index>=2,"actors":index>=3,"edge_y":108.0}
