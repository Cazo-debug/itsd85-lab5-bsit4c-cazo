extends SceneTree

# Automated input-event run: one local rider and the production three assistants.
# No per-seat thrust calls or transform edits by this harness after normal spawn.
const SAVE: String = "user://gate2_inputs_verifier.cfg"
var level: Node3D
var failed: bool = false
var assertions: int = 0
var touch_events: int = 0
var gas_presses: int = 0
var focus_resumes: int = 0
var aim_down: bool = false
var gas_down: bool = false
var resting: bool = false
var key_states: Dictionary = {}
var frame_times: Array[float] = []
var last_tick: int = 0
var maximum_calls: int = 0
var maximum_primitives: int = 0
var visible_frames: int = 0
var sampled_frames: int = 0
var capture_cooldown: int = 0
var capture_prefix: String = "gate2_inputs"
var captures: bool = true

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-prefix="):
			capture_prefix = argument.trim_prefix("--capture-prefix=").validate_filename()
	captures = not "--no-capture" in OS.get_cmdline_user_args()
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failed = true
		push_error(message)

func frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame

func button(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child: Node in node.get_children():
		var found: Button = button(child, text)
		if found:
			return found
	return null

func click(text: String) -> void:
	var target: Button = button(current_scene, text)
	check(target != null, "Missing button: " + text)
	if target == null:
		return
	var point: Vector2 = target.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
	await frames(3)

func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	touch_events += 1

func drag(index: int, point: Vector2) -> void:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = index
	event.position = point
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	touch_events += 1

func key(code: Key, pressed: bool) -> void:
	if key_states.get(code, false) == pressed:
		return
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	key_states[code] = pressed

func release_controls() -> void:
	touch(3, Vector2.ZERO, false)
	touch(7, Vector2.ZERO, false)
	for code: Key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE]:
		key(code, false)
	aim_down = false
	gas_down = false

func capture(tag: String) -> void:
	if captures and DisplayServer.get_name() != "headless":
		capture_cooldown = 3
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/%s_%s.png" % [capture_prefix, tag])

func _process(_delta: float) -> bool:
	if is_instance_valid(level) and level.state == level.State.RACING and level.race_time > 1:
		var tick: int = Time.get_ticks_usec()
		if capture_cooldown > 0:
			capture_cooldown -= 1
		elif last_tick > 0:
			frame_times.append((tick - last_tick) / 1000.0)
		last_tick = tick
		maximum_calls = maxi(maximum_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		maximum_primitives = maxi(maximum_primitives, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		sampled_frames += 1
		var all_visible: bool = true
		for rider: Node3D in level.player.visual.riders:
			var point: Vector3 = rider.global_position + Vector3.UP * 0.8
			var screen: Vector2 = level.camera.unproject_position(point)
			all_visible = all_visible and not level.camera.is_position_behind(point) and Rect2(16, 360, 688, 600).has_point(screen)
		if all_visible:
			visible_frames += 1
	else:
		last_tick = 0
	return false

func drive_touch() -> void:
	var player: Node3D = level.player
	var target: Dictionary = level.course.path.sample(player.route_s + 5.5)
	var correction: Vector3 = (target.position - player.position).normalized() * 7.2 - player.linear_velocity
	var right: Vector3 = level.camera.global_basis.x.slide(Vector3.UP).normalized()
	var forward: Vector3 = (-level.camera.global_basis.z).slide(Vector3.UP).normalized()
	var vector: Vector2 = Vector2(correction.dot(right), -correction.dot(forward)).normalized() * clampf(correction.length() / 7.0, 0.15, 1.0)
	var controls: Control = level.hud.controls
	var point: Vector2 = controls.stick_rect().get_center() + vector * 80
	if not aim_down or controls.stick_id != 3:
		touch(3, point, true)
		aim_down = true
	else:
		drag(3, point)
	if player.gas[0] < 0.15 or player.depleted[0]:
		resting = true
	if player.gas[0] >= 0.65:
		resting = false
	var fire: bool = not resting and fmod(level.race_time, 2.0) < 1.65
	if gas_down != fire or (fire and controls.gas_id != 7):
		touch(7, controls.gas_rect().get_center(), fire)
		gas_down = fire
		if fire:
			gas_presses += 1

func verify() -> void:
	root.size = Vector2i(720, 1280)
	var game: Node = root.get_node("GameState")
	game.persistence_path = SAVE
	game.local_profiles = CrewData.default_profiles()
	game.local_profiles[0] = AvatarData.default_avatar()
	game.crew_slots = CrewData.default_slots()
	game.assign_slot(0, "local", 0)
	for seat: int in range(1, 4):
		game.assign_slot(seat, "assist", seat)
		game.local_profiles[seat].hat = seat
	game.active_local_seat = 0
	change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	await frames(6)
	await click("Play")
	check(current_scene.name == "ModeSelect", "Mouse events must open Mode Select")
	await click("Play offline")
	check(current_scene.name == "CrewSetup", "Mouse events must open Crew Setup")
	await click("Start Sky Garden")
	check(current_scene.name == "Level01", "Mouse events must launch the production course")
	if current_scene.name != "Level01":
		quit(1)
		return
	level = current_scene
	check(level.player.visual.riders.size() == 4, "All four configured riders must appear")
	check(level.player.seat_control.count("assist") == 3, "Use the real three assistants")
	check(level.find_children("*", "RigidBody3D", true, false).size() == 1, "Only one physical ring")
	await capture("overview")
	for index: int in range(360):
		if level.state == level.State.RACING:
			break
		await physics_frame
	check(level.state == level.State.RACING, "Normal intro/countdown must begin the run")
	var controls: Control = level.hud.controls
	touch(3, controls.stick_rect().get_center() + Vector2(0, -65), true)
	touch(7, controls.gas_rect().get_center(), true)
	await frames(20)
	check(level.player.held[0], "Two input fingers must supply actual thrust")
	check(level.player.force_seconds[0] > 0, "Local input must produce physical force")
	for seat: int in range(1, 4):
		check(level.player.force_seconds[seat] > 0, "Each assistant must contribute")
	drag(7, Vector2(10, 100))
	check(not level.player.held[0] and controls.gas_id == -1, "Dragging the firing finger outside must release immediately")
	var force_seconds: float = level.player.force_seconds[0]
	await frames(3)
	check(level.player.force_seconds[0] == force_seconds, "Release stops local force")
	check(level.player.linear_velocity.length() > 0.1, "Release retains drift")
	touch(7, controls.gas_rect().get_center(), true)
	await frames(6)
	await click("Pause")
	check(level.state == level.State.PAUSED and not true in level.player.held, "Pause clears every held request")
	var paused_time: float = level.race_time
	await frames(6)
	check(level.race_time == paused_time, "Pause must stop the run clock")
	await click("Resume")
	check(not level.player.held[0], "Resume cannot reuse the previous finger")
	release_controls()
	key(KEY_W, true)
	key(KEY_SPACE, true)
	check(Input.is_physical_key_pressed(KEY_SPACE), "Synthetic physical-key events reach the real input poll")
	await frames(12)
	check(level.player.held[0], "WASD/Space controls must fire")
	key(KEY_SPACE, false)
	await frames(3)
	check(not level.player.held[0], "Keyboard release stops held state")
	release_controls()
	level.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(level.state == level.State.PAUSED, "Application focus loss pauses the run")
	check(not true in level.player.held, "Focus loss leaves no stale requests")
	await click("Resume")
	await capture("controls_checked")
	var next_capture: int = 0
	var fractions: Array[float] = [0.12, 0.28, 0.40, 0.58, 0.80, 0.90]
	var tags: Array[String] = ["s_bend", "bridge", "climb", "hairpin", "obstacles", "holes"]
	var last_report: int = -1
	for frame: int in range(15000):
		await physics_frame
		if level.state == level.State.FINISHED:
			break
		if level.state == level.State.PAUSED:
			# The harness explicitly resumes after desktop focus loss.
			release_controls()
			await click("Resume")
			focus_resumes += 1
		if level.state != level.State.RACING:
			continue
		drive_touch()
		if int(level.race_time / 20) > last_report:
			last_report = int(level.race_time / 20)
			print("GATE2_RUN t=", snappedf(level.race_time, 0.1), " s=", snappedf(level.player.route_s, 0.1))
		if next_capture < fractions.size() and level.player.route_s / level.course.path.length >= fractions[next_capture]:
			await capture(tags[next_capture])
			next_capture += 1
	release_controls()
	check(level.won, "Input-event driver plus three assistants must complete the course")
	check(level.checkpoint_index == 2, "Both ordered checkpoints must be crossed")
	check(gas_presses > 5, "Demonstrate repeated holds/releases through actual input")
	check(not true in level.player.held, "Finish clears every request")
	check(level.player.visual.riders[0].thrust_heat < 0.1 or not level.player.simulate, "Feedback stops when the run ends")
	if DisplayServer.get_name() != "headless":
		check(sampled_frames > 100, "Sample the camera across the full rendered run")
		check(float(visible_frames) / maxf(sampled_frames, 1) >= 0.99, "All four rider head points stay inside the safe viewport for at least 99% of sampled frames")
	await capture("result")
	frame_times.sort()
	var report: Dictionary = {"passed": not failed, "assertions": assertions, "input": "synthetic Godot mouse/key/two-finger events", "crew": "one local plus three production assistants", "touch_events": touch_events, "hold_presses": gas_presses, "seconds": level.race_time, "contacts": level.player.contact_count, "recoveries": level.player.recoveries, "focus_resumes": focus_resumes, "camera_visible_fraction": float(visible_frames) / maxf(sampled_frames, 1), "max_draw_calls": maximum_calls, "max_primitives": maximum_primitives}
	if not frame_times.is_empty():
		report["frame_ms_median"] = frame_times[frame_times.size() / 2]
		report["frame_ms_p95"] = frame_times[int(frame_times.size() * 0.95)]
	await click("Back")
	check(current_scene.name == "CrewSetup", "Back returns to Crew Setup")
	report["passed"] = not failed
	report["assertions"] = assertions
	print("GATE2_INPUT_RESULT ", JSON.stringify(report))
	var output: FileAccess = FileAccess.open("res://.bin/gate2-input-result.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(SAVE + suffix)
	root.get_node("Audio").stop_all()
	await create_timer(0.12, true, false, true).timeout
	quit(1 if failed else 0)
