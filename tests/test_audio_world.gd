extends SceneTree
## Verifies original procedural SFX & looping audio bed synthesis, anti-clipping bounds,
## click-free loop boundaries, pause/mute/settings lifecycle, and clean multi-retry teardown.
const H = preload("res://tests/harness.gd")
const Sounds = preload("res://scripts/game/sounds.gd")
const Session = preload("res://scripts/game/session.gd")
const Book = preload("res://scripts/core/story_book.gd")
const Store = preload("res://scripts/core/save_store.gd")

var h = H.new("audio_world")

func _initialize() -> void:
	call_deferred("run")

func _peak_amplitude(wav: AudioStreamWAV) -> int:
	var data := wav.data
	var peak := 0
	var count := data.size() / 2
	for i in range(0, count, 7):
		var s := absi(data.decode_s16(i * 2))
		if s > peak:
			peak = s
	return peak

func run() -> void:
	# 1. All 15 procedural SFX cues synthesize valid non-silent 16-bit PCM without clipping.
	h.eq("sounds defines all 15 expected SFX cues", Sounds.CUE_NAMES.size(), 15)
	for cue_name in Sounds.CUE_NAMES:
		var wav := Sounds.build_tone(cue_name)
		var peak := _peak_amplitude(wav)
		h.check("cue %s builds non-empty unclipped 16-bit WAV" % cue_name, wav.format == AudioStreamWAV.FORMAT_16_BITS and wav.mix_rate == Sounds.SAMPLE_RATE and wav.data.size() > 400 and peak > 100 and peak <= 28000)

	# 2. All 3 seamless looping beds synthesize click-free boundary fades and LOOP_FORWARD.
	h.eq("sounds defines all 3 expected music beds", Sounds.BED_NAMES.size(), 3)
	for bed_name in Sounds.BED_NAMES:
		var bed := Sounds.build_bed(bed_name)
		var peak := _peak_amplitude(bed)
		var first_sample := absi(bed.data.decode_s16(0))
		var last_sample := absi(bed.data.decode_s16(bed.data.size() - 2))
		h.check("bed %s loops forward with unclipped audio" % bed_name, bed.loop_mode == AudioStreamWAV.LOOP_FORWARD and bed.loop_end == bed.data.size() / 2 and peak > 500 and peak <= 26000)
		h.check("bed %s has click-free zero-crossing loop edges" % bed_name, first_sample <= 40 and last_sample <= 40)

	# 3. Audio controller state lifecycle (beds, pause, mute, volume, invalid bed ignored).
	var ctrl := Sounds.new()
	root.add_child(ctrl)
	await process_frame
	ctrl.set_bed("road")
	h.eq("set_bed sets active_bed to road", ctrl.active_bed, "road")
	ctrl.set_bed("boss")
	h.eq("set_bed switches active_bed cleanly to boss", ctrl.active_bed, "boss")
	ctrl.set_bed("not_a_real_bed")
	h.eq("unknown bed name is ignored safely", ctrl.active_bed, "boss")
	ctrl.set_paused(true)
	h.eq("set_paused tracks pause state", ctrl.paused, true)
	ctrl.set_paused(false)
	h.eq("set_paused resumes cleanly", ctrl.paused, false)
	ctrl.apply_settings(false, 0.4)
	h.check("apply_settings updates enabled and clamped volume", not ctrl.enabled and is_equal_approx(ctrl.volume, 0.4))
	ctrl.apply_settings(true, 1.5)
	h.check("apply_settings clamps volume upper bound to 1.0", ctrl.enabled and is_equal_approx(ctrl.volume, 1.0))
	ctrl.set_bed("")
	h.eq("clearing bed resets active_bed", ctrl.active_bed, "")
	ctrl.queue_free()
	await process_frame

	# 4. Five consecutive run scene lifecycles leave zero orphan audio state & switch beds properly.
	root.size = Vector2i(640, 360)
	root.content_scale_size = Vector2i(640, 360)
	await process_frame
	for retry_i in 5:
		Session.story_mode = true
		Session.campaign_state = Book.choose(Book.defaults(), "depart")
		var game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		await process_frame
		game.set_physics_process(false)
		game.set_process(false)
		game.store = Store.new("user://audio-retry-fixture.json")
		h.eq("retry %d starts on road bed" % retry_i, game.sounds.active_bed, "road")
		game.distance = 285.0
		game._update_encounter(0.02)
		h.eq("retry %d switches to boss bed on Mühür-01 entry" % retry_i, game.sounds.active_bed, "boss")
		game._set_paused(true)
		h.eq("retry %d pauses audio controller" % retry_i, game.sounds.paused, true)
		game._set_paused(false)
		game._hurt_boss(9999.0)
		h.eq("retry %d returns to road bed after boss defeat" % retry_i, game.sounds.active_bed, "road")
		game._end_run("destroyed")
		h.eq("retry %d stops music bed on run end" % retry_i, game.sounds.active_bed, "")
		game.store.clear()
		game.queue_free()
		await process_frame

	# 5. Interlude 1 ("Yan yana") switches from road bed (race) to aftermath bed (ground scene).
	Session.story_mode = true
	var c := Book.choose(Book.defaults(), "depart")
	c["phase"] = "interlude"
	c["stage"] = 0
	Session.campaign_state = c
	var story = load("res://scenes/road_story.tscn").instantiate()
	root.add_child(story)
	await process_frame
	story.set_process(false)
	h.eq("interlude 1 arrival starts on road bed", story.sounds.active_bed, "road")
	story.chapter["step"] = "aftermath"
	story._sync_audio()
	h.eq("interlude 1 aftermath switches to aftermath bed", story.sounds.active_bed, "aftermath")
	story._pause(true)
	h.eq("interlude 1 pause pauses audio controller", story.sounds.paused, true)
	story._pause(false)
	story.queue_free()
	await process_frame

	Session.story_mode = false
	Session.campaign_state = {}
	quit(h.finish())
