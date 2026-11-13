extends RefCounted
## Cosmetic choice only: same hitbox, movement and weapon anchors on every car.
const IDS := ["roadster", "courier", "comet"]
const ITEMS := {
 "roadster":{"name":"Yol Arkadaşı","description":"Aion’un tanıdık açık kokpitli arabası.","texture":"res://assets/sprites/aion_roadster.png"},
 "courier":{"name":"Postacı","description":"Anıları taşımak için geniş kasalı bir yol arabası.","texture":"res://assets/sprites/courier_body.png"},
 "comet":{"name":"Kuyruklu Yıldız","description":"Dar burunlu, pembe bir gece yarışçısı.","texture":"res://assets/sprites/comet_body.png"}
}
static func sanitize(value: Variant) -> String:
 return value if value is String and value in IDS else "roadster"
static func texture_for(value: Variant) -> Texture2D:
 return load(ITEMS[sanitize(value)]["texture"])
static func add_driver(car: Sprite2D,value: Variant) -> void:
 if sanitize(value)=="roadster": return
 var atlas:=AtlasTexture.new()
 atlas.atlas=preload("res://assets/sprites/aion_roadster.png")
 atlas.region=Rect2(16,30,32,30)
 var driver:=Sprite2D.new()
 driver.texture=atlas;driver.centered=false;driver.position=Vector2(-16,-13.5)
 car.add_child(driver)
