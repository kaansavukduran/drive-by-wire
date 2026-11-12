extends Node
## Original short synth cues, generated locally. No samples or network services.

var enabled := true
var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var next := 0

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		enabled = false
		return
	for i in range(4):
		var player := AudioStreamPlayer.new()
		player.volume_db = -17
		add_child(player)
		players.append(player)
	for name in ["fire", "hit", "pickup", "kill", "finish"]:
		streams[name] = _make_tone(name)

func cue(name: String) -> void:
	if not enabled or not streams.has(name):
		return
	var player := players[next % players.size()]
	next += 1
	player.stream = streams[name]
	player.play()

func _make_tone(name: String) -> AudioStreamWAV:
	var sample_rate := 22050
	var duration: float = {"fire": 0.07, "hit": 0.18, "pickup": 0.24, "kill": 0.18, "finish": 0.6}[name]
	var count := int(duration * sample_rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	for i in range(count):
		var t := float(i) / sample_rate
		var progress := t / duration
		var frequency := 400.0
		match name:
			"fire": frequency = lerpf(1000, 250, progress)
			"hit": frequency = lerpf(160, 45, progress)
			"kill": frequency = lerpf(280, 70, progress)
			"pickup": frequency = 660.0 if progress < 0.5 else 880.0
			"finish": frequency = [523.25, 659.25, 783.99, 1046.5][mini(3, int(progress * 4))]
		phase += TAU * frequency / sample_rate
		var wave := sin(phase) + sin(phase * 2.0) * 0.25
		var envelope := minf(t * 250.0, 1.0) * (1.0 - progress)
		bytes.encode_s16(i * 2, int(wave * envelope * 16000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = bytes
	return stream
