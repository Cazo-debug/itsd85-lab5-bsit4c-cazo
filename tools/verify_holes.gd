extends SceneTree

var level: Node3D
var captures: bool = false

func _initialize() -> void:
	captures = "--capture" in OS.get_cmdline_user_args()
	call_deferred("verify")

func capture(label: String) -> void:
	if not captures:
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/phase2_holes_%s.png" % label)

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		assert(condition, message)

func verify() -> void:
	root.size = Vector2i(720, 1280)
	var game_state: Node = root.get_node("GameState")
	game_state.persistence_path = "user://hole_verifier.cfg"
	level = load("res://scenes/legacy/LegacyLevel01.tscn").instantiate() as Node3D
	level.auto_return = false
	root.add_child(level)
	current_scene = level
	while level.state != level.State.RACING:
		await physics_frame
	# Show the openings first, with the player behind the first hole.
	level.player.freeze = true
	level.player.position = level.course.holes[0].position + Vector3(0, 0, 5)
	level.player.reset_physics_interpolation()
	level.camera.snap_to_player()
	for frame: int in range(190):
		await physics_frame
	await capture("course")
	level.player.position = level.course.holes[0].position
	level.player.reset_physics_interpolation()
	level.player.freeze = false
	var time_before: float = level.race_time
	for frame: int in range(3):
		await physics_frame
	check(level.player.falling, "Real race did not detect entry into the hole")
	check(not level.player.toot_toward(Vector3(0, 0, -50)), "Input accepted during fall")
	for frame: int in range(25):
		await physics_frame
	check(level.player.model.position.y < -1.0, "Float visual did not drop")
	await capture("fall")
	for frame: int in range(40):
		await physics_frame
	check(not level.player.falling, "Fall never completed")
	check(level.player.position.distance_to(level.player.checkpoint + Vector3(0, 0, -3)) < 0.1, "Wrong respawn location")
	check(level.player.controls_enabled and not level.player.freeze, "Respawn did not restore input")
	check(level.race_time > time_before + 0.9, "Race timer stopped during fall")
	await capture("respawn")
	print("VERIFIED: actual hole entry, blocked input, rendered drop, checkpoint respawn and continuing timer")
	DirAccess.remove_absolute(game_state.persistence_path)
	quit()
