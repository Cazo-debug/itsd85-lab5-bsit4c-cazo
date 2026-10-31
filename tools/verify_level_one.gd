extends SceneTree
var level: Node3D
var captures: bool = false
var checks: int = 0
var game_state: Node
var measure: bool = false
var frame_count: int = 0
var sample_time: float = 0.0
var worst_frame: float = 0.0
var max_draw_calls: int = 0
var max_primitives: int = 0

func _initialize() -> void:
	captures = "--capture" in OS.get_cmdline_user_args()
	measure = "--measure" in OS.get_cmdline_user_args()
	call_deferred("verify")

func _process(delta: float) -> bool:
	if measure and is_instance_valid(level) and level.get("race_time") != null and level.race_time > 2.0:
		frame_count += 1
		sample_time += delta
		worst_frame = maxf(worst_frame, delta)
		max_draw_calls = maxi(max_draw_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		max_primitives = maxi(max_primitives, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	return false

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		push_error(message)
		quit(1)
		assert(value, message)

func touch(at: Vector2, pressed: bool) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.position = at
	event.pressed = pressed
	Input.parse_input_event(event)

func capture(name: String) -> void:
	if not captures:
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/phase2_sky_%s.png" % name)
	print("CAPTURE ", name)

func verify() -> void:
	root.size = Vector2i(720, 1280)
	game_state = root.get_node("GameState")
	game_state.persistence_path = "user://phase2_verifier.cfg"
	game_state.seen_tutorial = false
	level = load("res://scenes/levels/Level01.tscn").instantiate() as Node3D
	level.auto_return = false
	root.add_child(level)
	current_scene = level
	for frame: int in range(10):
		await physics_frame
	check(level.state == level.State.INTRO, "Race must start with course overview")
	await capture("overview")
	while level.state == level.State.INTRO:
		await physics_frame
	var water: Vector2 = level.camera.unproject_position(level.player.global_position + Vector3(0, 0, -6))
	touch(water, true)
	await process_frame
	touch(water, false)
	check(level.player.gas == 3, "Countdown touch spent gas")
	await capture("countdown")
	while level.state == level.State.COUNTDOWN:
		await physics_frame
	check(level.tap_input.enabled, "Input not enabled after GO")
	# Disabled pause still consumes touches; it cannot launch the float.
	var pause: Button = level.hud.root.find_child("Pause", true, false) as Button
	touch(pause.get_global_rect().get_center(), true)
	await process_frame
	touch(pause.get_global_rect().get_center(), false)
	check(level.player.gas == 3, "UI touch leaked into race input")
	water = level.camera.unproject_position(level.player.global_position + Vector3(0, 0, -6))
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.position = water
	mouse.global_position = water
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await process_frame
	mouse = mouse.duplicate()
	mouse.pressed = false
	Input.parse_input_event(mouse)
	check(level.player.gas == 2, "Water touch must spend exactly one charge")
	for frame: int in range(72):
		await physics_frame
	check(level.player.position.z < -2.5, "Touch did not move player forward")
	await capture("race")
	if captures:
		print("RENDER draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var waypoint: int = 1
	var last_toot: float = -1.0
	var captured_play: bool = false
	var pickups: Array[int] = [0]
	for bean: Node3D in level.course.beans:
		bean.bean_collected.connect(func(_body: Node3D) -> void: pickups[0] += 1)
	var points: Array = level.definition.waypoints
	while level.state == level.State.RACING:
		if captures and not captured_play and level.race_time >= 5.0:
			captured_play = true
			await capture("play")
		var target: Vector3 = Vector3(points[waypoint][0], 0, -points[waypoint][1])
		if level.player.position.distance_to(target) < 3.5 and waypoint < points.size() - 1:
			waypoint += 1
		if level.player.gas > 0 and level.race_time - last_toot > 0.5:
			level.player.toot_toward(Vector3(points[waypoint][0], 0, -points[waypoint][1]))
			last_toot = level.race_time
		check(absf(level.player.position.x) < 8.0, "Player escaped banks")
		check(level.player.linear_velocity.length() <= 14.0 + 0.1, "Speed cap broken")
		await physics_frame
	check(game_state.last_result.won, "Tutorial course could not be cleared")
	check(level.last_checkpoint_d == 95.0, "Checkpoint sensors did not register")
	check(pickups[0] > 0, "No bean sensor registered")
	check(game_state.best_stars.get(1, 0) > 0, "Win did not save stars")
	await capture("finish")
	print("VERIFIED checks=", checks, " finish_time=", level.race_time, " pickups=", pickups[0], " stars=", game_state.last_result.stars)
	if measure and sample_time > 0.0:
		print("DESKTOP avg_fps=", frame_count / sample_time, " worst_frame_ms=", worst_frame * 1000, " max_draw_calls=", max_draw_calls, " max_primitives=", max_primitives)
	DirAccess.remove_absolute(game_state.persistence_path)
	quit()
