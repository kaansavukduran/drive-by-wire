extends RefCounted
## A small chapter-specific state machine, not a replacement game framework.
const PATH := "res://data/road_story.json"
const STEPS := ["arrival","memory","invite","race","trap","aftermath","eren","plea","reveal","promise","rescue","witness","handoff","complete"]
static var _data: Dictionary={}
static func data() -> Dictionary:
 if _data.is_empty():_data=JSON.parse_string(FileAccess.get_file_as_string(PATH))
 return _data
static func defaults() -> Dictionary:return {"step":"arrival","pace":"","vow":"","record":""}
static func sanitize(raw: Variant) -> Dictionary:
 var out:=defaults()
 if not raw is Dictionary:return out
 if raw.get("pace") in ["race","together"]:out["pace"]=raw["pace"]
 if raw.get("vow") in ["avenge","rescue"]:out["vow"]=raw["vow"]
 if raw.get("step") in STEPS:out["step"]=raw["step"]
 if raw.get("record") in ["sealed","shared"]:out["record"]=raw["record"]
 if not out["step"] in ["arrival","memory","invite"] and out["pace"]=="":out=defaults()
 if out["step"] in ["promise","rescue","witness","handoff","complete"] and out["vow"]=="":out["step"]="reveal"
 if out["step"]=="promise" and out["vow"]!="avenge":out["step"]="rescue"
 if out["step"]=="rescue" and out["vow"]!="rescue":out["step"]="promise"
 return out
static func choose(raw: Dictionary,id: String) -> Dictionary:
 var out:=sanitize(raw)
 if out["step"]=="invite" and id in ["race","together"]:
  out["pace"]=id;out["step"]="race"
 elif out["step"]=="reveal" and id in ["avenge","rescue"]:
  out["vow"]=id;out["step"]="promise" if id=="avenge" else "rescue"
 elif out["step"]=="witness" and id in ["sealed","shared"]:
  out["record"]=id;out["step"]="handoff"
 return out
static func advance(raw: Dictionary) -> Dictionary:
 var out:=sanitize(raw)
 match out["step"]:
  "race":out["step"]="trap"
  "trap":out["step"]="aftermath"
  _:
   var next: String=str(data()["nodes"][out["step"]].get("next",""))
   if next!="" and next!="complete":out["step"]=next
   elif next=="complete":out["step"]="complete"
 return out
static func epilogue(state: Dictionary) -> String:
 var chapter: Dictionary=state.get("chapter2",{})
 var vow: String=chapter.get("vow","")
 var prose:=""
 if vow=="avenge":prose="Emre’ye verdiğin söz: Kurt sinyalin kaynağını aradı. Emre iyileşirken boş bardağı geri verdin. Hesap kapanmış olsa da o yolun bedelini bir düşman sayısına çevirmedin."
 elif vow=="rescue":prose="Emre’ye verdiğin söz: Önce onu hayatta tuttun. Kuzu’nun ışıkları söndüğünde arabada iki dolu bardak vardı. Emre bir daha yarışıp yarışmayacağınızı sordu. Bu kez karar vermek için acele etmediniz."
 if chapter.get("record")=="sealed":prose+="\n\nEren mühürlü kaydı sakladı. Emre kendi sesini paylaşmaya hazır olduğunda mührü beraber açabileceğinizi söyledi. Beklemeyi bir kez olsun başarabilmiştiniz."
 elif chapter.get("record")=="shared":prose+="\n\nEren yalnız sinyal izini Kurt’la çözdü; Emre’nin konuşması onların arasında kaldı. Sonra defterine üçünüzün adını yazdı. Bu kez tutulan kayıt birini eksiltmiyordu."
 return prose
