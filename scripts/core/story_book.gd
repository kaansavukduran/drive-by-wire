extends RefCounted
## Local choice book. A combat failure is a retry, never one of the 13 endings.
const PATH := "res://data/story_book.json"
static var _data: Dictionary = {}
static func data() -> Dictionary:
 if _data.is_empty(): _data=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 return _data
static func defaults(unlocked: Array = []) -> Dictionary:
 return {"stage":0,"choices":[],"active":false,"unlocked":unlocked.duplicate(),"failures":0,"score":0,"goals_completed":0}
static func node_key(state: Dictionary) -> String:
 var prefix: Array=state["choices"].slice(0,int(state["stage"]))
 return "root" if prefix.is_empty() else "/".join(prefix)
static func node(state: Dictionary) -> Dictionary:
 return data()["nodes"].get(node_key(state),{})
static func sanitize(raw: Variant) -> Dictionary:
 var out:=defaults()
 if not raw is Dictionary: return out
 for field in ["stage","failures","score","goals_completed"]:
  var n: Variant=raw.get(field,0)
  if (n is float or n is int) and is_finite(float(n)): out[field]=int(clampf(float(n),0,2000000000))
 out["stage"]=mini(out["stage"],3)
 out["goals_completed"]=mini(out["goals_completed"],out["stage"])
 var prefix: Array=[]
 if raw.get("choices") is Array:
  for candidate in raw["choices"].slice(0,3):
   var key: String="root" if prefix.is_empty() else "/".join(prefix)
   var valid: bool=false
   for option in data()["nodes"].get(key,{}).get("choices",[]):
    if candidate is String and candidate==option["id"]: valid=true
   if not valid: break
   prefix.append(candidate)
 out["stage"]=mini(out["stage"],prefix.size())
 out["active"]=raw.get("active",false)==true and out["stage"]<3 and prefix.size()==out["stage"]+1
 out["choices"]=prefix.slice(0,out["stage"]+(1 if out["active"] else 0))
 if raw.get("unlocked") is Array:
  for ending in data()["endings"]:
   if ending["id"] in raw["unlocked"]: out["unlocked"].append(ending["id"])
 out["goals_completed"]=mini(out["goals_completed"],out["stage"])
 if out["stage"]==3 and not ending(out).is_empty() and not ending(out)["id"] in out["unlocked"]:
  out["unlocked"].append(ending(out)["id"])
 return out
static func choose(state: Dictionary,id: String) -> Dictionary:
 var out:=sanitize(state)
 if out["stage"]>=3: return out
 for option in node(out).get("choices",[]):
  if option["id"]==id:
   out["choices"]=out["choices"].slice(0,out["stage"])
   out["choices"].append(id)
   out["active"]=true
   return out
 return out
static func current(state: Dictionary) -> Dictionary:
 if not state["active"]: return {}
 for option in node(state).get("choices",[]):
  if option["id"]==state["choices"][-1]: return option
 return {}
static func complete(state: Dictionary,survived: bool,score: int,goal: bool) -> Dictionary:
 var out:=sanitize(state)
 if not out["active"]: return out
 out["active"]=false
 if survived:
  out["stage"]+=1
  out["score"]=mini(2000000000,out["score"]+maxi(0,score))
  if goal: out["goals_completed"]+=1
 else:
  out["failures"]+=1
  out["choices"]=out["choices"].slice(0,out["stage"])
 return sanitize(out)
static func ending(state: Dictionary) -> Dictionary:
 if int(state["stage"])!=3: return {}
 for item in data()["endings"]:
  if item["path"]==state["choices"]: return item
 return {}
static func path_labels(state: Dictionary) -> Array[String]:
 var labels: Array[String]=[]
 var prefix: Array=[]
 for id in state["choices"]:
  var key: String="root" if prefix.is_empty() else "/".join(prefix)
  for option in data()["nodes"].get(key,{}).get("choices",[]):
   if option["id"]==id: labels.append(str(option["name"]))
  prefix.append(id)
 return labels
