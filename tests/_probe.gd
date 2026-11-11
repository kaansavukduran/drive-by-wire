extends SceneTree
const P := preload("res://scripts/core/command_parser.gd")
func _initialize() -> void:
	var p = P.new()
	for t in ["Sağa geç ve kamyona ateş et", "kamyonete ates", "sağdakine vur", "sola ateş et", "sola!", "sağ ol", "I'm fine", "asdf qwerty", "", "  ,, ", "hızlan sonra fren", "ÖNDEKİNE ATEŞ", "aptalsın", "gazla", "yavsla", "mayın bırak", "çarpan arabaya çarp", "KAÇ", "sıyrıl", "sola geç ateş et", "fire at the truck", "shoot the pickup on the left", "rigth", "kamyna ateş"]:
		print(t, " => ", p.parse(t))
	quit(0)
