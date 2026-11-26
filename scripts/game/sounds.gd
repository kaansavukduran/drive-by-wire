extends Node
## Original procedural synth SFX and seamless looping music beds, generated locally.
## Music resources are local, and audio never consumes the combat RNG.

const SAMPLE_RATE := 22050
const BED_SAMPLE_RATE := 11025
const VOICE_COUNT := 8
const CUE_NAMES: Array[String] = [
	"fire", "bullet_hit", "mine", "mine_boom", "hit", "shield_block",
	"kill", "pickup", "truck_hatch", "boss_warn", "boss_fire",
	"boss_phase", "boss_defeat", "finish", "pulse",
]
const BED_NAMES: Array[String] = ["road", "boss", "aftermath"]
const MUSIC_TRACKS := {
 "ice":"res://assets/music/icyadventure-loopable.ogg",
 "boss":"res://assets/music/retrobossfight-loopable.ogg",
 "cliff":"res://assets/music/eeriechoir.ogg",
}
const FALLBACK_BEDS := {"ice":"road","cliff":"aftermath"}

static var _cached_streams: Dictionary = {}
static var _cached_beds: Dictionary = {}
static var _music: Dictionary = {}

var enabled := true
var volume := 0.7
var paused := false
var active_bed := ""
var streams: Dictionary = {}
var bed_streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var bed_player: AudioStreamPlayer = null
var fading_player: AudioStreamPlayer = null
var fade: Tween
var last_bed := ""
var next := 0

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		enabled = false
		return
	for i in range(VOICE_COUNT):
		var player := AudioStreamPlayer.new()
		player.volume_db = -17.0
		add_child(player)
		players.append(player)
	bed_player = AudioStreamPlayer.new()
	bed_player.volume_db = -24.0
	add_child(bed_player)
	fading_player = AudioStreamPlayer.new()
	add_child(fading_player)
	if _cached_streams.is_empty():
		for name in CUE_NAMES:
			_cached_streams[name] = build_tone(name)
	streams = _cached_streams
	bed_streams = _cached_beds
	if not active_bed.is_empty():
		_sync_bed()

func _exit_tree() -> void:
	stop_all()

func apply_settings(is_enabled: bool, vol: float) -> void:
	enabled = is_enabled
	volume = clampf(vol, 0.0, 1.0)
	if not enabled or volume <= 0.0:
		stop_all()
		return
	_sync_bed()

func set_paused(value: bool) -> void:
	paused = value
	if bed_player == null:
		return
	bed_player.stream_paused = paused
	fading_player.stream_paused = paused
	if fade and fade.is_valid():
		if paused: fade.pause()
		else: fade.play()
	if not paused:
		_sync_bed()

func prepare_track(name: String) -> void:
	if not MUSIC_TRACKS.has(name) or _music.has(name) or DisplayServer.get_name()=="headless":
		return
	var stream := load(MUSIC_TRACKS[name]) as AudioStreamOggVorbis
	if stream:
		stream.loop = name!="cliff"
	_music[name] = stream

func set_bed(name: String) -> void:
	if not name.is_empty() and not (name in BED_NAMES or MUSIC_TRACKS.has(name)):
		return
	active_bed = name
	_sync_bed()

func _stop_beds() -> void:
	if fade and fade.is_valid(): fade.kill()
	for player in [bed_player, fading_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			player.stream_paused = false
	last_bed = ""

func stop_all() -> void:
	for player in players:
		if is_instance_valid(player):
			player.stop()
	_stop_beds()

func _sync_bed() -> void:
	if not is_instance_valid(bed_player):
		return
	if active_bed.is_empty() or not enabled or volume <= 0.0:
		_stop_beds()
		return
	if paused:
		return
	var target: AudioStream = _music.get(active_bed)
	var fallback: String = FALLBACK_BEDS.get(active_bed,active_bed)
	if target == null:
		prepare_track(active_bed)
		target = _music.get(active_bed)
	if target == null:
		if not _cached_beds.has(fallback):
			_cached_beds[fallback] = build_bed(fallback)
		bed_streams = _cached_beds
		target = _cached_beds[fallback]
	if target == null:
		return
	if last_bed == active_bed and bed_player.stream == target:
		if not fade or not fade.is_running(): bed_player.volume_db = _bed_db(active_bed)
		return
	if fade and fade.is_valid(): fade.kill()
	fading_player.stop()
	if bed_player.playing:
		var outgoing := bed_player
		bed_player = fading_player
		fading_player = outgoing
	else:
		fading_player.stream = null
	bed_player.stream = target
	bed_player.stream_paused = false
	bed_player.volume_db = -52.0 if fading_player.playing else _bed_db(active_bed)
	bed_player.play()
	last_bed = active_bed
	if fading_player.playing:
		fade = create_tween()
		fade.set_parallel()
		fade.tween_property(bed_player,"volume_db",_bed_db(active_bed),.36)
		fade.tween_property(fading_player,"volume_db",-52.0,.36)
		fade.chain().tween_callback(_finish_fade)

func _finish_fade() -> void:
	fading_player.stop()
	fading_player.stream = null
	bed_player.volume_db = _bed_db(active_bed)

func _bed_db(name: String) -> float:
	var base: float = {"road":-24.5,"ice":-24.5,"boss":-23.0,"cliff":-25.0,"aftermath":-26.0}.get(name,-26.0)
	return base + linear_to_db(maxf(volume,0.001))

func music_snapshot() -> Dictionary:
	return {
		"bed":active_bed,
		"track":bed_player.stream.resource_path if bed_player and bed_player.stream else "",
		"playing":bed_player.playing if bed_player else false,
		"muted":not enabled or volume<=0.0,
	}

func cue(name: String) -> void:
	if not enabled or volume <= 0.0 or not streams.has(name) or players.is_empty():
		return
	var player := players[next % players.size()]
	next += 1
	var offset_db: float = {
		"fire": -1.5,
		"bullet_hit": -4.0,
		"mine": -1.0,
		"mine_boom": 1.0,
		"hit": 0.5,
		"shield_block": 0.0,
		"kill": 0.5,
		"pickup": -1.0,
		"truck_hatch": -2.5,
		"boss_warn": -1.0,
		"boss_fire": 0.5,
		"boss_phase": 1.5,
		"boss_defeat": 2.0,
		"finish": 0.5,
	}.get(name, 0.0)
	player.volume_db = -17.0 + offset_db + linear_to_db(maxf(volume, 0.001))
	player.stream = streams[name]
	player.play()

static func _hash_noise(index: int) -> float:
	var x := (index * 1103515245 + 12345) & 0x7fffffff
	x = (x ^ (x >> 13)) & 0x7fffffff
	return (float(x % 20001) / 10000.0) - 1.0

static func build_tone(name: String) -> AudioStreamWAV:
	var duration: float = {
		"fire": 0.075,
		"bullet_hit": 0.055,
		"mine": 0.14,
		"mine_boom": 0.34,
		"hit": 0.20,
		"shield_block": 0.22,
		"kill": 0.24,
		"pickup": 0.24,
		"truck_hatch": 0.16,
		"boss_warn": 0.30,
		"boss_fire": 0.22,
		"boss_phase": 0.45,
		"boss_defeat": 0.65,
		"finish": 0.60,
		"pulse": 0.28,
	}.get(name, 0.15)
	var count := int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var phase2 := 0.0
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var p := t / duration
		var freq := 400.0
		var freq2 := 0.0
		var noise_mix := 0.0
		var env := minf(t * 260.0, 1.0) * pow(1.0 - p, 1.15)
		match name:
			"fire":
				freq = lerpf(1080.0, 240.0, p)
				noise_mix = 0.18 * (1.0 - p)
			"bullet_hit":
				freq = lerpf(1500.0, 620.0, p)
				noise_mix = 0.25 * (1.0 - p)
				env = minf(t * 400.0, 1.0) * pow(1.0 - p, 1.6)
			"mine":
				freq = lerpf(280.0, 110.0, p) if p < 0.55 else 540.0
				env = minf(t * 280.0, 1.0) * (1.0 - p * 0.85)
			"mine_boom":
				freq = lerpf(155.0, 38.0, pow(p, 0.65))
				freq2 = lerpf(310.0, 65.0, p)
				noise_mix = 0.58 * pow(1.0 - p, 0.85)
				env = minf(t * 320.0, 1.0) * pow(1.0 - p, 0.9)
			"hit":
				freq = lerpf(170.0, 46.0, p)
				noise_mix = 0.32 * (1.0 - p)
			"shield_block":
				freq = lerpf(520.0, 880.0, p)
				freq2 = lerpf(780.0, 1320.0, p)
				env = minf(t * 260.0, 1.0) * pow(1.0 - p, 1.2)
			"kill":
				freq = lerpf(260.0, 62.0, p)
				noise_mix = 0.42 * (1.0 - p)
			"pickup":
				freq = 660.0 if p < 0.45 else 880.0
				freq2 = 990.0 if p < 0.45 else 1320.0
			"truck_hatch":
				freq = lerpf(210.0, 125.0, p)
				noise_mix = 0.22 * (1.0 - p)
			"boss_warn":
				var pulse_wave := 1.0 if int(p * 4.0) % 2 == 0 else 0.35
				freq = lerpf(420.0, 680.0, p)
				freq2 = freq * 1.5
				env = minf(t * 200.0, 1.0) * (1.0 - p * 0.6) * pulse_wave
			"boss_fire":
				freq = lerpf(360.0, 95.0, p)
				freq2 = lerpf(720.0, 140.0, p)
				noise_mix = 0.34 * (1.0 - p)
			"boss_phase":
				freq = lerpf(180.0, 540.0, p)
				freq2 = lerpf(270.0, 810.0, p)
				noise_mix = 0.20 * sin(p * PI)
				env = minf(t * 140.0, 1.0) * (1.0 - p * 0.75)
			"boss_defeat":
				var notes: Array[float] = [196.0, 146.83, 110.0, 73.42]
				freq = notes[mini(3, int(p * 4.0))]
				freq2 = lerpf(440.0, 82.0, p)
				noise_mix = 0.48 * pow(1.0 - p, 0.75)
				env = minf(t * 240.0, 1.0) * pow(1.0 - p, 0.85)
			"pulse":
				freq = lerpf(1200.0, 420.0, p)
			"finish":
				var chord: Array[float] = [523.25, 659.25, 783.99, 1046.5]
				freq = chord[mini(3, int(p * 4.0))]
				freq2 = freq * 0.5
				env = minf(t * 160.0, 1.0) * (1.0 - p * 0.85)
		phase += TAU * freq / SAMPLE_RATE
		var sample := sin(phase) + sin(phase * 2.0) * 0.22
		if freq2 > 0.0:
			phase2 += TAU * freq2 / SAMPLE_RATE
			sample = sample * 0.68 + sin(phase2) * 0.32
		if noise_mix > 0.0:
			sample = sample * (1.0 - noise_mix * 0.55) + _hash_noise(i) * noise_mix
		var encoded := clampi(int(sample * env * 13500.0), -28000, 28000)
		bytes.encode_s16(i * 2, encoded)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	return stream

static func build_bed(name: String) -> AudioStreamWAV:
	# Exact 2.0-second seamless loop at 11025 Hz; fast WASM synth + click-free edge fades.
	var duration := 2.0
	var count := int(duration * BED_SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var fade_samples := 220
	for i in range(count):
		var t := float(i) / BED_SAMPLE_RATE
		var sample := 0.0
		match name:
			"road":
				# Driving night-highway synth pulse + low engine hum (Cam Ormanı).
				var step := int(floor(t * 4.0)) % 8
				var bass_notes: Array[float] = [55.0, 55.0, 65.5, 55.0, 73.5, 73.5, 65.5, 61.75]
				var root := bass_notes[step]
				var sub_t := fposmod(t * 4.0, 1.0)
				var pluck := exp(-sub_t * 4.2)
				var rumble := sin(TAU * 42.0 * t) * 0.26 + sin(TAU * 84.0 * t) * 0.10
				var bass := (sin(TAU * root * t) * 0.45 + sin(TAU * root * 2.0 * t) * 0.16) * (0.45 + 0.55 * pluck)
				var shimmer := sin(TAU * 220.0 * t) * 0.07 * (0.5 + 0.5 * sin(TAU * 0.5 * t))
				sample = rumble + bass + shimmer
			"boss":
				# Intensified Mühür-01 mechanical pulse: tight sixth/eighth drive + fifth tension.
				var step := int(floor(t * 6.0)) % 12
				var notes: Array[float] = [55.0, 55.0, 82.5, 55.0, 65.5, 55.0, 55.0, 82.5, 73.5, 65.5, 61.75, 55.0]
				var root := notes[step]
				var sub_t := fposmod(t * 6.0, 1.0)
				var gate := exp(-sub_t * 5.0)
				var drive := (sin(TAU * root * t) * 0.50 + sin(TAU * root * 1.5 * t) * 0.22 + sin(TAU * root * 3.0 * t) * 0.10) * (0.35 + 0.65 * gate)
				var alarm := sin(TAU * 330.0 * t) * 0.06 * (0.5 + 0.5 * sin(TAU * 2.0 * t))
				sample = drive + alarm
			_:
				# Warm sparse "Yan yana" roadside pad (A minor / C major9 gentle breath).
				var breath := 0.68 + 0.32 * sin(TAU * 0.5 * t)
				var pad := sin(TAU * 110.0 * t) * 0.30 + sin(TAU * 165.0 * t) * 0.22 + sin(TAU * 247.0 * t) * 0.14 + sin(TAU * 329.5 * t) * 0.08
				sample = pad * breath
		var loop_env := 1.0
		if i < fade_samples:
			loop_env = float(i) / float(fade_samples)
		elif i >= count - fade_samples:
			loop_env = float(count - 1 - i) / float(fade_samples)
		var encoded := clampi(int(sample * loop_env * 12000.0), -26000, 26000)
		bytes.encode_s16(i * 2, encoded)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = BED_SAMPLE_RATE
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	stream.data = bytes
	return stream
