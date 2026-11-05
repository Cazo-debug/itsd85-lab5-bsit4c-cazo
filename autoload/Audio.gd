extends Node

const SOUND_FILES: Dictionary = {"attack": "thrust_attack", "release": "thrust_release", "impact": "impact",
	"fall": "fall", "bean": "pickup", "ui": "ui", "checkpoint": "checkpoint", "win": "win", "timeout": "timeout"}
var SOUNDS: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var effects: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var targets: Array[bool] = [false, false, false, false]
var gains: Array[float] = [0.0, 0.0, 0.0, 0.0]
var enabled: bool = true
var focused: bool = true
var music_requested: bool = false
var last_settings: String = ""
var event_times: Dictionary = {}
var starts: Array[int] = [0, 0, 0, 0]
var releases: Array[int] = [0, 0, 0, 0]

func _ready() -> void:
	# Runtime loading lets a clean editor import the WAVs before autoload playback.
	for key: String in SOUND_FILES:
		SOUNDS[key] = load("res://assets/audio/%s.wav" % SOUND_FILES[key])
	for seat: int in range(4):
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.name = "RiderLoop%d" % seat
		voice.stream = looping(load("res://assets/audio/thrust_loop.wav") as AudioStreamWAV)
		voice.pitch_scale = 0.91 + seat * 0.07
		voice.volume_db = -80
		add_child(voice)
		voices.append(voice)
	for index: int in range(6):
		var effect: AudioStreamPlayer = AudioStreamPlayer.new()
		effect.name = "Effect%d" % index
		effect.volume_db = -16
		add_child(effect)
		effects.append(effect)
	music = AudioStreamPlayer.new()
	music.name = "SkyTheme"
	music.stream = looping(load("res://assets/audio/sky_theme.wav") as AudioStreamWAV)
	add_child(music)
	apply_settings()

func looping(source: AudioStreamWAV) -> AudioStreamWAV:
	var stream: AudioStreamWAV = source.duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	return stream

func apply_settings() -> void:
	enabled = GameState.settings.get("sound", true)
	var volume: float = float(GameState.settings.get("music_volume", 0.7))
	music.volume_db = linear_to_db(maxf(0.0001, volume)) - 14
	if not enabled or not focused:
		stop_all()
	elif music_requested and volume > 0 and not music.playing:
		music.play()
	if volume <= 0:
		music.stop()
	last_settings = str(GameState.settings)

func play_sfx(sound_name: String, pitch: float = 1.0) -> void:
	if not enabled or not focused or not GameState.settings.get("sound", true) or not SOUNDS.has(sound_name) or not is_finite(pitch):
		return
	var now: int = Time.get_ticks_msec()
	var delay: int = 160 if sound_name == "impact" else 25
	if now - int(event_times.get(sound_name, -1000)) < delay:
		return
	for effect: AudioStreamPlayer in effects:
		if not effect.playing:
			effect.stream = SOUNDS[sound_name]
			effect.pitch_scale = clampf(pitch, 0.6, 1.6)
			effect.play()
			event_times[sound_name] = now
			return

func play_music() -> void:
	music_requested = true
	apply_settings()

func set_thrust(seat: int, firing: bool) -> void:
	if seat < 0 or seat >= 4:
		return
	var active: bool = firing and enabled and focused and GameState.settings.get("sound", true)
	if targets[seat] == active:
		return
	targets[seat] = active
	if active:
		starts[seat] += 1
		voices[seat].play()
		play_sfx("attack", voices[seat].pitch_scale)
	else:
		releases[seat] += 1
		play_sfx("release", voices[seat].pitch_scale)

func stop_thrust(immediate: bool = false) -> void:
	for seat: int in range(4):
		set_thrust(seat, false)
		if immediate:
			gains[seat] = 0
			voices[seat].stop()

func stop_all() -> void:
	targets.fill(false)
	gains.fill(0.0)
	for voice: AudioStreamPlayer in voices:
		voice.stop()
	for effect: AudioStreamPlayer in effects:
		effect.stop()
	if music:
		music.stop()

func _process(delta: float) -> void:
	if last_settings != str(GameState.settings):
		apply_settings()
	for seat: int in range(4):
		gains[seat] = move_toward(gains[seat], 1.0 if targets[seat] else 0.0, delta / (0.075 if targets[seat] else 0.12))
		voices[seat].volume_db = -24 + linear_to_db(maxf(gains[seat], 0.0001))
		if not targets[seat] and gains[seat] <= 0:
			voices[seat].stop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focused = false
		stop_all()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focused = true
		if music:
			apply_settings()

func _exit_tree() -> void:
	stop_all()
