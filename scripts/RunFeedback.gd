class_name RunFeedback
extends Node

# Observes authoritative/local presentation state. Never applies physics or saves.
var level: Node3D
var previous_state: int = -1
var previous_falling: bool = false
var previous_checkpoint: int = 0
var previous_pickups: int = 0
var previous_contacts: int = 0
var last_vibration: int = -1000
var quality: String = ""
# High-quality frame budget: when the last two seconds of racing averaged under 46 FPS,
# the 3D view is drawn a little smaller (down to 80%); it steps back up when there is
# headroom. The HUD always stays sharp. Presentation only.
const BUDGET_WINDOW: float = 2.0
const SLOW_MS: float = 1000.0 / 46.0
const FAST_MS: float = 1000.0 / 52.0
const MIN_SCALE: float = 0.8
var render_scale: float = 1.0
var budget_seconds: float = 0.0
var budget_frames: int = 0
var headroom_windows: int = 0

func _ready() -> void:
	Audio.stop_thrust(true)
	Audio.play_music()
	apply_preferences()

func apply_preferences() -> void:
	quality = GameState.settings.get("quality", "high")
	SettingsFlow.apply_quality(level, quality == "low")
	render_scale = 1.0
	budget_seconds = 0.0
	budget_frames = 0
	level.camera.reduced_motion = GameState.settings.get("reduced_motion", true)

func _process(delta: float) -> void:
	if not is_instance_valid(level.player):
		return
	if quality != GameState.settings.get("quality", "high"):
		apply_preferences()
	var running: bool = level.state == level.State.RACING
	if running and quality == "high":
		keep_frame_budget(delta)
	for seat: int in range(4):
		Audio.set_thrust(seat, running and not level.player.falling and level.player.firing[seat] and level.player.seat_control[seat] != "empty")
	if level.player.falling and not previous_falling:
		Audio.play_sfx("fall")
		vibrate(60)
	if level.checkpoint_index > previous_checkpoint:
		Audio.play_sfx("checkpoint")
	if level.pickups_collected > previous_pickups:
		Audio.play_sfx("bean")
	if level.player.contact_count > previous_contacts and running:
		Audio.play_sfx("impact")
		vibrate(20)
	if level.state == level.State.FINISHED and previous_state != level.State.FINISHED:
		Audio.stop_thrust(true)
		Audio.play_sfx("win" if level.won else "timeout")
		if level.won:
			# Presentation: the crew cheers and the camera frames it (host and joined phones).
			level.player.celebrate()
			level.camera.celebrate()
	if previous_state == level.State.RACING and not running:
		Audio.stop_thrust(true)
	previous_state = level.state
	previous_falling = level.player.falling
	previous_checkpoint = level.checkpoint_index
	previous_pickups = level.pickups_collected
	previous_contacts = level.player.contact_count

func keep_frame_budget(delta: float) -> void:
	budget_seconds += delta
	budget_frames += 1
	if budget_seconds < BUDGET_WINDOW:
		return
	var average_ms: float = budget_seconds * 1000.0 / budget_frames
	# Down at once when slow; back up only after three comfortable windows (no pumping).
	headroom_windows = headroom_windows + 1 if average_ms < FAST_MS else 0
	if average_ms > SLOW_MS and render_scale > MIN_SCALE:
		render_scale = maxf(MIN_SCALE, render_scale - 0.05)
	elif headroom_windows >= 3 and render_scale < 1.0:
		render_scale = minf(1.0, render_scale + 0.05)
		headroom_windows = 0
	if level.is_inside_tree():
		level.get_viewport().scaling_3d_scale = render_scale
	budget_seconds = 0.0
	budget_frames = 0

func vibrate(duration: int) -> void:
	var now: int = Time.get_ticks_msec()
	if OS.has_feature("android") and GameState.settings.get("vibration", true) and now - last_vibration > 200:
		Input.vibrate_handheld(duration)
		last_vibration = now

func _exit_tree() -> void:
	Audio.stop_thrust(true)
	if is_instance_valid(level) and level.is_inside_tree():
		level.get_viewport().scaling_3d_scale = 1.0
