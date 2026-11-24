extends GutTest

var saved_settings: Dictionary
var audio: Node

func before_each() -> void:
	saved_settings = GameState.settings.duplicate(true)
	GameState.settings = GameState.DEFAULT_SETTINGS.duplicate()
	audio = load("res://autoload/Audio.gd").new()
	add_child_autofree(audio)

func after_each() -> void:
	audio.stop_all()
	GameState.settings = saved_settings
	Audio.apply_settings()

func test_original_pcm_assets_have_signal_headroom_and_valid_loop_seams() -> void:
	var resources: Array[AudioStreamWAV] = []
	for key: String in audio.SOUNDS:
		resources.append(audio.SOUNDS[key])
	resources.append(audio.voices[0].stream)
	for stream: AudioStreamWAV in resources:
		assert_eq(stream.mix_rate, 22050)
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
		assert_false(stream.stereo)
		assert_gt(stream.get_length(), 0.05)
		var peak: float = 0
		var energy: float = 0
		for index: int in range(0, stream.data.size(), 2):
			var sample: float = stream.data.decode_s16(index) / 32768.0
			peak = maxf(peak, absf(sample))
			energy += sample * sample
		assert_gt(peak, 0.1)
		assert_lt(peak, 0.73)
		assert_gt(energy / (stream.data.size() / 2), 0.001)
		if stream.loop_mode == AudioStreamWAV.LOOP_FORWARD:
			var original: AudioStreamWAV = load("res://assets/audio/thrust_loop.wav")
			assert_eq(stream.loop_end, original.data.size() / 2, "Full original period retained")
			assert_lt(stream.loop_end, stream.data.size() / 2, "Loop endpoint remains within allocated PCM")
			assert_eq(stream.data.slice(0, original.data.size()), original.data, "Original samples stay unchanged")
			assert_eq(stream.data.slice(original.data.size()), original.data.slice(0, 2), "Guard frame repeats the loop start")
			assert_lt(absf(original.data.decode_s16(0) - original.data.decode_s16(original.data.size() - 2)) / 32768.0, 0.04)

func test_music_is_a_looping_ogg_and_effects_are_wav() -> void:
	# Lab PDF p. 4: ".ogg for music, .wav for short effects".
	assert_true(audio.music.stream is AudioStreamOggVorbis)
	assert_true((audio.music.stream as AudioStreamOggVorbis).loop)
	assert_almost_eq(audio.music.stream.get_length(), 8.0, 0.02)
	for key: String in audio.SOUNDS:
		assert_true(audio.SOUNDS[key] is AudioStreamWAV, "%s is a .wav effect" % key)

func test_music_mixes_across_multiple_full_length_wraps() -> void:
	var playback: AudioStreamPlayback = audio.music.stream.instantiate_playback()
	playback.start()
	var frames: int = int(AudioServer.get_mix_rate() * 17)
	var mixed: PackedVector2Array = playback.mix_audio(1.0, frames)
	assert_eq(mixed.size(), frames)
	assert_true(playback.is_playing(), "Music remains active beyond two eight-second loops")
	# The cursor must have wrapped twice and reached the first second of the third period.
	assert_almost_eq(playback.get_playback_position(), 1.0, 0.05)
	var peak: float = 0.0
	var finite: bool = true
	for index: int in range(0, mixed.size(), 127):
		finite = finite and mixed[index].is_finite()
		peak = maxf(peak, absf(mixed[index].x))
	assert_true(finite, "Samples remain finite across both loop boundaries")
	assert_gt(peak, 0.1)
	playback.stop()

func test_four_sustained_voices_start_once_and_release_to_silence() -> void:
	for seat: int in range(4):
		audio.set_thrust(seat, true)
		audio.set_thrust(seat, true)
	assert_eq(audio.starts, [1, 1, 1, 1])
	audio._process(0.1)
	for seat: int in range(4):
		assert_true(audio.voices[seat].playing)
		assert_eq(audio.gains[seat], 1.0)
		audio.set_thrust(seat, false)
	audio._process(0.15)
	assert_eq(audio.releases, [1, 1, 1, 1])
	for voice: AudioStreamPlayer in audio.voices:
		assert_false(voice.playing)
	audio.set_thrust(-1, true)
	audio.set_thrust(4, true)
	assert_eq(audio.starts, [1, 1, 1, 1])

func test_mute_volume_and_focus_stop_all_playback_without_stale_thrust() -> void:
	audio.play_music()
	audio.set_thrust(2, true)
	audio.play_sfx("impact")
	GameState.settings.sound = false
	audio.apply_settings()
	assert_false(audio.music.playing)
	assert_eq(audio.targets, [false, false, false, false])
	for effect: AudioStreamPlayer in audio.effects:
		assert_false(effect.playing)
	audio.set_thrust(2, true)
	assert_false(audio.targets[2])
	GameState.settings.sound = true
	GameState.settings.music_volume = 0.2
	audio.apply_settings()
	assert_true(audio.music.playing)
	assert_almost_eq(audio.music.volume_db, linear_to_db(0.2) - 14, 0.001)
	audio._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(audio.music.playing)
	assert_false(audio.targets[2])
	audio._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	assert_true(audio.music.playing)
	assert_false(audio.targets[2])
	GameState.settings.music_volume = 0.0
	audio.apply_settings()
	assert_false(audio.music.playing)
