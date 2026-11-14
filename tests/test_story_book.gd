extends SceneTree
const H=preload("res://tests/harness.gd")
const Book=preload("res://scripts/core/story_book.gd")
const Cliff=preload("res://scripts/core/cliff_story.gd")
const Store=preload("res://scripts/core/save_store.gd")
var h:=H.new("story_book")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 h.eq("13 stages planned, only two available",[int(Book.data()["planned_stages"]),int(Book.data()["available_stages"])],[13,2])
 h.eq("no branching ending claim",Book.data()["endings"],[])
 for first in ["listen","together"]:
  for second in ["listen","together"]:
   var s:=Book.defaults()
   for i in 2:
    h.eq("linear node independent from replies",Book.node_key(s),"chapter_%02d" % (i+1))
    s=Book.answer(s,first if i==0 else second)
    var a:=Book.choose(s,"depart")
    h.eq("one route has same stats after either response",Book.current(a),Book.node(s)["choices"][0])
    h.eq("repeated answer is inert",Book.answer(s,"listen"),s)
    var failed:=Book.complete(a,false,900,true)
    h.eq("failure stays at the same stage",[failed["stage"],failed["phase"],failed["score"]],[i,"briefing",s["score"]])
    s=Book.complete(a,true,100,true)
    h.eq("success enters interlude before next combat",[s["stage"],s["phase"]],[i,"interlude"])
    h.eq("combat completion cannot apply twice",Book.complete(s,true,100,true),s)
    s=Book.finish_interlude(s)
    h.eq("interlude completion cannot apply twice",Book.finish_interlude(s),s)
   h.eq("same continued state for every response pair",[s["stage"],s["phase"],s["score"],s["unlocked"]],[2,"continued",200,[]])
   h.eq("no third playable stage",Book.choose(s,"depart"),s)
 var old={"stage":3,"choices":["archive","seal","identity"],"unlocked":["e04"],"score":850,"bonds":{"emre":2}}
 var migrated:=Book.sanitize(old)
 h.eq("legacy completed book resumes at new second combat",[migrated["stage"],migrated["phase"]],[1,"briefing"])
 h.eq("legacy path retained in archive",migrated["legacy"]["choices"],old["choices"])
 h.eq("legacy score and earned record retained",[migrated["score"],migrated["unlocked"]],[850,["e04"]])
 h.eq("migration idempotent",Book.sanitize(migrated),migrated)
 var store:=Store.new("user://linear-test.json");var saved:=store.defaults();saved["campaign"]=migrated;saved["vehicle"]="comet";saved["settings"]["volume"]=.35
 h.check("migration saves",store.save_data(saved));h.eq("archive survives reopen",store.load_data()["campaign"],migrated);h.eq("vehicle/settings unchanged",[store.load_data()["vehicle"],store.load_data()["settings"]["volume"]],["comet",.35]);store.clear()
 for bad in [null,[],5,{"stage":INF,"phase":"invented"}]:h.eq("malformed input cannot open unbuilt stages",Book.sanitize(bad)["stage"],0)
 for reply in ["shaken","joke"]:
  var s:=Cliff.defaults()
  for step in ["approach","impact","brake","exit"]:s=Cliff.advance(s)
  s=Cliff.choose(s,reply);h.eq("both cliff replies rejoin at thanks",s["step"],"thanks")
  for i in 4:s=Cliff.advance(s)
  h.eq("both cliff replies reach same end",s["step"],"complete")
 quit(h.finish())
