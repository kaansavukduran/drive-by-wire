extends RefCounted
## One authored rescue; timeline positions are deterministic, not gameplay physics.
const PATH="res://data/cliff_story.json"
const STEPS=["approach","impact","brake","exit","check","thanks","wreck","aion_exit","promise","complete"]
static var _data: Dictionary={}
static func data() -> Dictionary:
 if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 return _data
static func defaults() -> Dictionary:return {"step":"approach","reply":"","skip_dialogue":false}
static func sanitize(raw: Variant) -> Dictionary:
 var out:=defaults()
 if raw is Dictionary:
  out["skip_dialogue"]=raw.get("skip_dialogue",false)==true
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
 var aion_car:=Vector2(400,198)
 var kurt_car:=Vector2(355,198)
 var kurt_foot:=Vector2(421,219)
 var aion_foot:=Vector2(445,237)
 var actors:=step in ["exit","check","thanks","wreck","aion_exit","promise","complete"]
 var aion_visible:=step in ["promise","complete"] or (step=="aion_exit" and t>=.23)
 var door:=0.0
 var stride:=3
 match step:
  "approach":
   aion_car=Vector2(318,250).lerp(Vector2(318,168),t)
   kurt_car=Vector2(76,180).lerp(Vector2(273,168),t)
  "impact":
   var weight:=1.0-pow(1.0-t,2.0)
   aion_car=Vector2(318,168).lerp(Vector2(386,176),weight)
   kurt_car=Vector2(273,168).lerp(Vector2(341,176),weight)
  "brake":
   var weight:=1.0-pow(1.0-t,3.0)
   aion_car=Vector2(386,176).lerp(aion_car,weight)
   kurt_car=Vector2(341,176).lerp(kurt_car,weight)
  "exit":
   actors=t>=.16
   kurt_foot=Vector2(346,224).lerp(kurt_foot,smoothstep(.16,1.0,t))
   stride=int(time*7.0)%2 if not reduced and t<.92 else 2
  "check","thanks","wreck":
   stride=2 if step=="check" else 3
  "aion_exit":
   door=smoothstep(0.0,.3,t)
   aion_foot=Vector2(417,214).lerp(aion_foot,smoothstep(.23,.89,t))
   stride=2
  "promise","complete":
   door=1.0
 var aion_frame:=2 if reduced or step!="aion_exit" else clampi(int((t-.23)*6.0),0,2)
 return {"aion_car":aion_car,"kurt_car":kurt_car,"aion_foot":aion_foot,"kurt_foot":kurt_foot,
  "frame":stride,"aion_frame":aion_frame,"wrecked":step not in ["approach","impact"],"actors":actors,
  "aion_visible":aion_visible,"door":door,"settled":step!="brake" or t>=.96,"edge_y":108.0}
