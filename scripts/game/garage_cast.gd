extends Control
## Garage actors stand on two fixed floor marks. No idle pose cycling or tweens.
## Keep the source artwork intact; a Sprite2D region uses a shared foot pivot.
const Art=preload("res://scripts/game/visual_art.gd")
const SHEET := preload("res://assets/characters/characters_standing.png")
var slots: Array[Control]=[]
var actors: Array[Sprite2D]=[]
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 clip_contents=true
 for row in [0,1]:
  var slot:=Control.new()
  slot.mouse_filter=Control.MOUSE_FILTER_IGNORE
  slot.clip_contents=true
  add_child(slot)
  slots.append(slot)
  var actor:=Sprite2D.new()
  Art.standing(actor,"aion" if row==0 else "omer")
  actor.flip_h=row==1
  slot.add_child(actor)
  actors.append(actor)
 resized.connect(_layout)
 _layout()
func _layout() -> void:
 var half:=floorf(size.x/2)
 for i in actors.size():
  slots[i].position=Vector2(i*half,0)
  slots[i].size=Vector2(half,size.y)
  actors[i].position=Vector2(floorf(half/2),size.y-4)
func snapshot() -> Dictionary:
 var entries: Array=[]
 for i in actors.size():
  var actor:=actors[i]
  var rect: Rect2=actor.get_global_transform()*actor.get_rect()
  var area:=slots[i].get_global_rect()
  entries.append({"id":["aion","omer"][i],"slot":[area.position.x,area.position.y,area.size.x,area.size.y],"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"feet":[actor.global_position.x,actor.global_position.y],"region":[actor.region_rect.position.x,actor.region_rect.position.y,actor.region_rect.size.x,actor.region_rect.size.y],"flip_h":actor.flip_h})
 var area:=get_global_rect()
 return {"area":[area.position.x,area.position.y,area.size.x,area.size.y],"actors":entries}
