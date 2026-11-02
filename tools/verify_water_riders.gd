extends SceneTree

# Focused rendered fixture. Full no-teleport solvability remains in verify_sky_garden.
var level: Node3D
var failed: bool = false
var draw_calls: int = 0
var primitives: int = 0

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame
		if level.state == level.State.PAUSED:
			level.toggle_pause()
			level.brain.enabled = false
			level.hud.controls.enabled = false
		draw_calls = maxi(draw_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		primitives = maxi(primitives, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))

func capture(tag: String) -> void:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/phase2_feel_%s.png" % tag)

func verify() -> void:
	root.size = Vector2i(720, 1280)
	var game: Node = root.get_node("GameState")
	game.persistence_path = "user://water_riders_verifier.cfg"
	game.local_profiles = CrewData.default_profiles()
	game.local_profiles[0] = AvatarData.default_avatar()
	game.crew_slots = CrewData.default_slots()
	for seat: int in range(4):
		game.assign_slot(seat, "local", seat)
		game.local_profiles[seat].hat = seat
	level = load("res://scenes/levels/Level01.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(3)
	await capture("overview")
	level.begin_run()
	level.brain.enabled = false
	level.hud.controls.enabled = false
	level.camera.overview = false
	level.player.route_s = level.course.path.length * 0.12
	level.player.transform = level.course.path.safe_transform(level.player.route_s)
	level.previous_s = level.player.route_s
	level.camera.snap()
	await frames(15)
	await capture("outward")
	var direction: Vector3 = level.course.path.sample(level.player.route_s).tangent
	level.player.set_aim_input(0, direction)
	await frames(50)
	check(absf(angle_difference(0, level.player.orbit.angles[0])) > 0.4, "Aim must move a rider around the rim")
	check(level.player.gas[0] == 1, "Moving around the rim does not burn gas")
	await capture("orbit")
	for seat: int in range(4):
		level.player.set_thrust_input(seat, direction, 1, true)
	await frames(60)
	check(level.player.visual.riders[0].thrust_heat > 0.9, "Rear charge tint must reflect actual firing")
	await capture("thrust")
	var speed: float = level.player.linear_velocity.length()
	level.player.release_all_inputs()
	await frames(15)
	check(level.player.linear_velocity.length() > 0.2, "Hull must coast after release")
	await capture("wake")
	await frames(30)
	check(level.player.visual.riders[0].thrust_heat < 0.01, "Tint must cool on release")
	await capture("released")
	print("WATER_RIDERS_RESULT ", JSON.stringify({"passed": not failed, "riders": level.player.visual.riders.size(), "draw_calls": draw_calls, "primitives": primitives, "speed_before_release": speed, "speed_after_release": level.player.linear_velocity.length(), "physical_tilt_degrees": rad_to_deg(level.player.peak_tilt)}))
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(game.persistence_path + suffix)
	quit(1 if failed else 0)
