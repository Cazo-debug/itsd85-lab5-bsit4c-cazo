extends SceneTree

# Deliberate placement fixtures for contact/fall evidence, not solvability runs.
var level: Node3D
var failed: bool = false

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame
		resume_fixture()

func resume_fixture() -> void:
	# A capture window may lose desktop focus. The normal game's pause is tested
	# separately; this isolated no-input fixture resumes its simulation explicitly.
	if level.state == level.State.PAUSED:
		level.toggle_pause()
		level.brain.enabled = false
		level.hud.controls.enabled = false

func capture(tag: String) -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/phase2_v3_%s.png" % tag)

func place(distance: float, lateral: float) -> void:
	level.player.release_all_inputs()
	level.player.falling = false
	level.player.fall_time = 0
	level.player.unsupported_time = 0
	level.player.upside_down_time = 0
	level.player.linear_velocity = Vector3.ZERO
	level.player.angular_velocity = Vector3.ZERO
	level.player.route_s = distance
	level.previous_s = distance
	var frame: Dictionary = level.course.path.sample(distance)
	level.player.global_transform = Transform3D(Basis.IDENTITY, frame.position + frame.lateral * lateral + Vector3.UP * 0.28)
	level.player.reset_physics_interpolation()
	level.camera.snap()

func verify() -> void:
	root.size = Vector2i(720, 1280)
	var game: Node = root.get_node("GameState")
	game.persistence_path = "user://sky_recovery_verifier.cfg"
	game.local_profiles = CrewData.default_profiles()
	game.local_profiles[0] = AvatarData.default_avatar()
	game.crew_slots = CrewData.default_slots()
	for seat: int in range(4):
		game.assign_slot(seat, "local", seat)
	level = load("res://scenes/levels/Level01.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	level.begin_run()
	level.camera.overview = false
	level.brain.enabled = false
	level.hud.controls.enabled = false
	level.player.checkpoint_s = level.course.checkpoints[1] + 3
	level.player.checkpoint = level.course.path.safe_transform(level.player.checkpoint_s)
	var hole: Dictionary = level.course.path.holes[0]
	place(hole.s, hole.lateral)
	var initial_y: float = level.player.position.y
	var clock: float = level.race_time
	await frames(65)
	check(level.player.falling, "Open hole must start a group fall")
	check(level.player.position.y < initial_y - 3, "Hole must cause a physical gravity drop")
	check(not level.player.ripple.visible, "No water ripple on a falling crew")
	await capture("hole_fall")
	await frames(55)
	check(level.player.recoveries == 1 and not level.player.falling, "Hole recovery must complete once")
	check(level.player.position.distance_to(level.player.checkpoint.origin) < 1, "Recovery returns to latest safe checkpoint")
	check(not true in level.player.held, "Recovery must clear every held request")
	check(level.player.visual.riders.size() == 4, "All riders recover on the same hull")
	check(level.race_time > clock, "Run clock must continue during fall/recovery")
	await capture("hole_recovered")
	var edge_s: float = level.course.path.length * 0.28
	var edge: Dictionary = level.course.path.sample(edge_s)
	place(edge_s, edge.width / 2 + 3)
	initial_y = level.player.position.y
	await frames(65)
	check(level.player.falling and level.player.position.y < initial_y - 3, "Exposed bridge edge has no invisible support")
	await capture("edge_fall")
	await frames(55)
	check(level.player.recoveries == 2 and not level.player.falling, "Edge recovery must complete safely")
	var mallet: Node3D
	for hazard: Node3D in level.course.hazards:
		if hazard.kind == "mallet":
			mallet = hazard
	level.race_time = 0
	level.hud.banner.text = "MALLET CONTACT\nControlled physics fixture"
	place(mallet.route_s, -3.2)
	level.player.peak_tilt = 0
	var captured: bool = false
	for index: int in range(100):
		await physics_frame
		resume_fixture()
		if not captured and level.player.peak_tilt > 0.18:
			await capture("mallet_contact")
			captured = true
	check(level.player.contact_count > 0 and level.player.peak_tilt > 0.1, "Mallet must physically tip the hull")
	if not captured:
		await capture("mallet_contact")
	print("RECOVERY_RESULT ", JSON.stringify({"passed": not failed, "recoveries": level.player.recoveries, "contacts": level.player.contact_count, "tilt_degrees": rad_to_deg(level.player.peak_tilt)}))
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(game.persistence_path + suffix)
	quit(1 if failed else 0)
