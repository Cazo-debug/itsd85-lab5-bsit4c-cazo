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

func _ready() -> void:
	Audio.stop_thrust(true)
	Audio.play_music()
	apply_preferences()

func apply_preferences() -> void:
	quality = GameState.settings.get("quality", "high")
	SettingsFlow.apply_quality(level, quality == "low")
	level.camera.reduced_motion = GameState.settings.get("reduced_motion", true)

func _process(_delta: float) -> void:
	if not is_instance_valid(level.player):
		return
	if quality != GameState.settings.get("quality", "high"):
		apply_preferences()
	var running: bool = level.state == level.State.RACING
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
	if previous_state == level.State.RACING and not running:
		Audio.stop_thrust(true)
	previous_state = level.state
	previous_falling = level.player.falling
	previous_checkpoint = level.checkpoint_index
	previous_pickups = level.pickups_collected
	previous_contacts = level.player.contact_count

func vibrate(duration: int) -> void:
	var now: int = Time.get_ticks_msec()
	if OS.has_feature("android") and GameState.settings.get("vibration", true) and now - last_vibration > 200:
		Input.vibrate_handheld(duration)
		last_vibration = now

func _exit_tree() -> void:
	Audio.stop_thrust(true)
