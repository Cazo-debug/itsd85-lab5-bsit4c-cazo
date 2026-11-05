extends Node

# Opt-in developer check, also runnable from the embedded Windows release pack.
# It never writes the normal save. No automatic test mode in player navigation.
var failed: bool = false
var checks: int = 0
var game: Node
var audio: Node
var output: String = "user://phase5_build_check.json"
var captures: bool = false

func _ready() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--report="): output = argument.trim_prefix("--report=")
		if argument == "--capture": captures = true
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error(message)

func frames(count: int) -> void:
	for frame: int in range(count): await get_tree().process_frame

func capture(tag: String) -> void:
	if captures and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_tree().root.get_texture().get_image().save_png(output.get_base_dir() + "/phase5_" + tag + ".png")

func find_button(node: Node, text: String) -> Button:
	if node is Button and node.text.to_lower().begins_with(text.to_lower()): return node
	for child: Node in node.get_children():
		var found: Button = find_button(child, text)
		if found: return found
	return null

func click(text: String) -> void:
	var button: Button = find_button(get_tree().current_scene, text)
	check(button != null, "Button exists: " + text)
	if button == null: return
	var parent: Node = button.get_parent()
	while parent:
		if parent is ScrollContainer: parent.ensure_control_visible(button)
		parent = parent.get_parent()
	await frames(3)
	var point: Vector2 = button.get_global_rect().get_center()
	check(get_tree().root.get_visible_rect().has_point(point), "Button on screen: " + text)
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await get_tree().process_frame
	await frames(4)

func verify() -> void:
	get_tree().root.size = Vector2i(720, 1280)
	game = get_tree().root.get_node("GameState")
	audio = get_tree().root.get_node("Audio")
	game.persistence_path = "user://phase5_build_check.cfg"
	game.local_profiles = CrewData.default_profiles()
	game.set_profile(0, AvatarData.default_avatar())
	game.crew_slots = CrewData.default_slots()
	for seat: int in range(1, 4): game.assign_slot(seat, "local", seat)
	game.settings = game.DEFAULT_SETTINGS.duplicate()
	game.seen_tutorial = true
	check(get_tree().root.get_node("Net").phase == "idle", "Offline startup opens no connection")
	check(audio.voices.size() == 4 and audio.SOUNDS.size() == 9, "All original audio assets load")
	get_tree().change_scene_to_file("res://scenes/ui/Title.tscn")
	await frames(8)
	check(get_tree().current_scene.model.riders.size() == 4, "Title shows four riders on one ring")
	await capture("title")
	await click("Tap to start")
	check(get_tree().current_scene.name == "MainMenu", "Title navigation works")
	await click("Settings")
	check(get_tree().current_scene.name == "Settings", "Settings navigation works")
	await capture("settings")
	await click("Quality")
	await click("Reduced motion")
	await click("Show fps")
	await click("Vibration")
	await click("-")
	check(game.settings.quality == "low" and game.settings.show_fps and not game.settings.reduced_motion and not game.settings.vibration, "Preference controls update the application contract")
	var restored: Node = load("res://autoload/GameState.gd").new()
	restored.persistence_path = game.persistence_path
	get_tree().root.add_child(restored)
	check(restored.settings == game.settings, "Preferences reload from isolated storage")
	restored.queue_free()
	await click("Back")
	check(get_tree().current_scene.name == "MainMenu", "Settings Back works")
	await click("Credits")
	await click("Read licenses")
	check(get_tree().current_scene.notices.text.contains("SIL OPEN FONT LICENSE") and get_tree().current_scene.notices.text.contains("GODOT ENGINE"), "Full font and engine notices are bundled")
	await click("Back")
	game.current_level = 5
	get_tree().change_scene_to_file("res://scenes/levels/Level05.tscn")
	await frames(6)
	var level: Node3D = get_tree().current_scene
	level.begin_run()
	level.hud.controls.enabled = false
	for seat: int in range(4): level.player.set_thrust_input(seat, level.course.path.sample(3).tangent, 1, true)
	for frame: int in range(30): await get_tree().physics_frame
	check(level.player.gas[3] < 1 and level.player.force_seconds[3] > 0, "Fourth rider still contributes force on low quality")
	check(level.player.visual.riders.size() == 4 and not level.course.decor.clouds.visible, "Low quality retains four riders and only hides clouds")
	check(level.hud.fps_label.visible, "Saved FPS option is presented")
	level.toggle_pause()
	await frames(4)
	check(not audio.targets.has(true), "Pause releases every audio voice")
	await capture("pause_low_quality")
	# Actual mixed PCM from the audio server; no microphone/device recording.
	# The paused-run observer must not cancel this isolated four-voice stress test.
	level.feedback.set_process(false)
	var recorder: AudioEffectRecord = AudioEffectRecord.new()
	recorder.format = AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0, recorder)
	var effect_index: int = AudioServer.get_bus_effect_count(0) - 1
	recorder.set_recording_active(true)
	audio.focused = true
	audio.play_music()
	for seat: int in range(4): audio.set_thrust(seat, true)
	await get_tree().create_timer(0.2, true, false, true).timeout
	check(audio.targets.count(true) == 4 and audio.voices.all(func(voice: AudioStreamPlayer) -> bool: return voice.playing) and audio.gains.all(func(gain: float) -> bool: return gain > 0.99), "All four voices sustain at full gain during the mixer check")
	await get_tree().create_timer(0.5, true, false, true).timeout
	audio.stop_thrust()
	await get_tree().create_timer(0.25, true, false, true).timeout
	recorder.set_recording_active(false)
	var recorded: AudioStreamWAV = recorder.get_recording()
	AudioServer.remove_bus_effect(0, effect_index)
	var pcm: PackedByteArray = recorded.data
	var peak: float = 0
	var square: float = 0
	for index: int in range(0, pcm.size(), 2):
		var sample: float = pcm.decode_s16(index) / 32768.0
		peak = maxf(peak, absf(sample))
		square += sample * sample
	check(pcm.size() > 10000 and peak > 0.01, "Real audio mixer produces non-silent PCM")
	check(peak < 0.99, "Four voices plus music do not clip")
	game.settings.sound = false
	audio.apply_settings()
	check(not audio.music.playing and not audio.targets.has(true), "Master mute stops music and thrust")
	await get_tree().create_timer(0.12, true, false, true).timeout
	var report: Dictionary = {"passed": not failed, "checks": checks, "engine": Engine.get_version_info().string,
		"standalone": not OS.has_feature("editor"), "rendered": DisplayServer.get_name() != "headless", "audio_driver": AudioServer.get_driver_name(),
		"mixed_samples": pcm.size() / 2, "mixed_peak": peak, "mixed_rms": sqrt(square / maxf(1, pcm.size() / 2.0))}
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report, "\t")); file.close()
	print("BUILD_CHECK ", JSON.stringify(report))
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]: DirAccess.remove_absolute(game.persistence_path + suffix)
	get_tree().quit(1 if failed else 0)
