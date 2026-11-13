extends RefCounted
const Art=preload("res://scripts/game/visual_art.gd")
## Cosmetic choice only: same hitbox, movement and weapon anchors on every car.
const IDS := ["roadster", "courier", "comet"]
const ITEMS := {
 "roadster":{"name":"Yol Arkadaşı","description":"Aion’un tanıdık açık kokpitli arabası.","texture":"res://assets/art/players.png"},
 "courier":{"name":"Postacı","description":"Anıları taşımak için geniş kasalı bir yol arabası.","texture":"res://assets/art/players.png"},
 "comet":{"name":"Kuyruklu Yıldız","description":"Dar burunlu, pembe bir gece yarışçısı.","texture":"res://assets/art/players.png"}
}
static func sanitize(value: Variant) -> String:
 return value if value is String and value in IDS else "roadster"
static func texture_for(value: Variant) -> Texture2D:
 return load(ITEMS[sanitize(value)]["texture"])
static func index(value: Variant) -> int:return IDS.find(sanitize(value))
static func configure(car: Sprite2D,value: Variant,zoom: float=1) -> void:Art.vehicle(car,index(value),zoom)
static func add_driver(_car: Sprite2D,_value: Variant) -> void:pass # Driver is authored into each registered body.
