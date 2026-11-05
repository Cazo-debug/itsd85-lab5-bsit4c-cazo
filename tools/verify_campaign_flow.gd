extends SceneTree

# Complete mode uses only menu actions and normal thrust after each spawn.
# --previews deliberately places the ring: visual fixtures, never solvability proof.
const SAVE: String = "user://phase3_campaign_flow.cfg"
var game: Node
var failed: bool = false
var checks: int = 0
var captures: bool = false
var reports: Array[Dictionary] = []
var prefix: String = "phase3"

func _initialize() -> void:
	captures = "--capture" in OS.get_cmdline_user_args()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--prefix="):
			prefix = argument.trim_prefix("--prefix=").validate_filename()
	call_deferred("verify")

func check(value: bool, detail: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error(detail)

func frames(count: int) -> void:
	for frame: int in range(count):
		await physics_frame

func button(node: Node, starts: String) -> Button:
	if node is Button and node.text.begins_with(starts):
		return node
	for child: Node in node.get_children():
		var found: Button = button(child, starts)
		if found:
			return found
	return null

func click(starts: String) -> void:
	var target: Button = button(current_scene, starts)
	check(target != null, "Missing UI action: " + starts)
	if target == null:
		return
	check(not target.disabled, "UI action disabled: " + starts)
	var parent: Node = target.get_parent()
	while parent:
		if parent is ScrollContainer:
			parent.ensure_control_visible(target)
		parent = parent.get_parent()
	await frames(2)
	var point: Vector2 = target.get_global_rect().get_center()
	check(root.get_visible_rect().has_point(point), "Action outside visible viewport: " + starts)
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
	await frames(6)

func capture(label: String) -> void:
	if captures and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/%s_%s.png" % [prefix, label])

func wait_for_race(level: Node3D) -> void:
	for frame: int in range(420):
		if level.state == level.State.RACING:
			return
		await physics_frame
	check(false, "Countdown failed to reach active gameplay")

func configure_game() -> void:
	game.persistence_path = "user://phase3_preview_flow.cfg" if "--previews" in OS.get_cmdline_user_args() else SAVE
	game.local_profiles = CrewData.default_profiles()
	game.local_profiles[0] = AvatarData.default_avatar()
	game.crew_slots = CrewData.default_slots()
	for seat: int in range(4):
		game.assign_slot(seat, "local" if seat == 0 else "assist", seat)
	game.active_local_seat = 0
	game.leader_profile = 0
	game.unlocked_level = 1
	game.current_level = 1
	game.best_stars.clear()
	game.best_times.clear()
	game.last_result.clear()
	game.settings = game.DEFAULT_SETTINGS.duplicate()
	game.seen_tutorial = true
	game.mode = "offline"

func verify() -> void:
	root.size = Vector2i(720, 1280)
	game = root.get_node("GameState")
	configure_game()
	if "--reload" in OS.get_cmdline_user_args():
		await verify_reload()
	elif "--previews" in OS.get_cmdline_user_args():
		await preview_courses()
	else:
		await complete_campaign()
	var report: Dictionary = {"passed": not failed, "checks": checks, "headless": DisplayServer.get_name() == "headless", "runs": reports,
		"mode": "preview placement fixtures" if "--previews" in OS.get_cmdline_user_args() else ("fresh-process reload" if "--reload" in OS.get_cmdline_user_args() else "legal-input UI campaign")}
	print("CAMPAIGN_FLOW_RESULT ", JSON.stringify(report))
	var file: FileAccess = FileAccess.open("res://.bin/%s-flow.json" % prefix, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	# Complete mode leaves only its disposable test save for a second-process reload.
	if failed or "--reload" in OS.get_cmdline_user_args() or "--previews" in OS.get_cmdline_user_args():
		cleanup()
	quit(1 if failed else 0)

func complete_campaign() -> void:
	change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	await frames(8)
	await click("Courses")
	check(current_scene.name == "LevelSelect", "Courses opens Level Select")
	check(button(current_scene, "2.").disabled and button(current_scene, "5.").disabled, "Fresh campaign locks later courses")
	await capture("locked_courses")
	await click("1.")
	check(current_scene.name == "Level01", "Level 1 launches through the menu")
	var level: Node3D = current_scene as Node3D
	await wait_for_race(level)
	await click("Pause")
	check(level.state == level.State.PAUSED, "Pause menu stops the run")
	var clock: float = level.race_time
	await frames(20)
	check(level.race_time == clock and not true in level.player.held, "Paused clock and held input remain stopped")
	await capture("pause")
	await click("Sound:")
	check(not game.settings.sound, "Pause sound preference changes")
	var before_restart: int = level.get_instance_id()
	await click("Restart")
	level = current_scene as Node3D
	check(level.get_instance_id() != before_restart and level.state == level.State.INTRO, "Restart creates a fresh run")
	await wait_for_race(level)
	# Dedicated timeout fixture, separate from the normal course completions below.
	level.time_limit = 0.1
	await frames(15)
	check(level.state == level.State.FINISHED and not level.won, "Timeout shows cooperative failure")
	check(game.unlocked_level == 1 and game.best_stars.is_empty(), "Failure does not unlock or award stars")
	check(button(current_scene, "Next course") == null, "Failure offers no Next")
	await capture("timeout")
	before_restart = level.get_instance_id()
	await click("Retry")
	level = current_scene as Node3D
	check(level.get_instance_id() != before_restart and level.time_limit == LevelDefs.LEVELS[0].time_limit, "Retry resets the original course/time budget")
	for number: int in range(1, 6):
		level = current_scene as Node3D
		check(level.level_number == number, "Next launches the expected course")
		await wait_for_race(level)
		var driver: CrewBrain = CrewBrain.new()
		driver.ring = level.player
		driver.all_seats = true
		driver.control_seat = 0
		level.add_child(driver)
		for frame: int in range(22000):
			await physics_frame
			level.hud.controls.enabled = false
			if level.state == level.State.PAUSED:
				level.toggle_pause()
			if level.state == level.State.FINISHED:
				break
		check(level.won, "Legal input must complete " + level.definition.name)
		check(level.checkpoint_index == level.course.checkpoints.size(), "Both ordered checkpoints crossed")
		check(game.last_result.level == number, "Result records the actual level")
		check(game.unlocked_level == mini(5, number + 1), "Only the next course unlocks")
		check(level.result.saved, "Winning progress is saved")
		check(not true in level.player.held, "Finish clears the whole crew's inputs")
		for seconds: float in level.player.force_seconds:
			check(seconds > 1.0, "Each local/assistant seat actually contributes")
		reports.append({"level": number, "seconds": level.race_time, "contacts": level.player.contact_count, "recoveries": level.player.recoveries})
		print("CAMPAIGN_COURSE ", JSON.stringify(reports[-1]))
		await capture("result_%d" % number)
		if number < 5:
			await click("Next course")
		else:
			check(button(current_scene, "Next course") == null, "Final course has no invalid sixth course")
			await click("Menu")
	check(current_scene.name == "MainMenu", "Result Menu returns to Main Menu")
	check(FileAccess.file_exists(SAVE), "Campaign save exists for fresh-process verification")

func verify_reload() -> void:
	check(FileAccess.file_exists(SAVE), "Run complete mode first to create the isolated save")
	game.load_progress(SAVE)
	check(game.unlocked_level == 5 and game.best_stars.size() == 5 and game.best_times.size() == 5, "All results reload in a new process")
	check(not game.settings.sound, "Pause sound preference survives application restart")
	check(game.crew_slots[0].control == "local" and game.crew_slots[3].control == "assist", "Crew ownership survives restart")
	change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	await frames(8)
	await click("Courses")
	check(not button(current_scene, "5.").disabled, "Reloaded final course is playable")
	await capture("unlocked_courses")
	await click("5.")
	check(current_scene.name == "Level05", "Reload launches the final course from UI")

func preview_courses() -> void:
	# These are explicitly placed visual/performance samples, not completed runs.
	game.unlocked_level = 5
	for number: int in range(1, 6):
		change_scene_to_file(game.level_scene_path(number))
		await frames(8)
		var level: Node3D = current_scene as Node3D
		await capture("course_%d_overview" % number)
		level.begin_run()
		level.brain.enabled = false
		level.hud.controls.enabled = false
		var at: float = level.course.path.length * 0.53
		level.player.checkpoint_s = at
		level.player.checkpoint = level.course.path.safe_transform(at)
		level.player.respawn_at_checkpoint()
		level.previous_s = at
		level.camera.overview = false
		level.camera.snap()
		await frames(20)
		await capture("course_%d_play" % number)
		reports.append({"level": number, "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "visible_primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
		await click("Pause")
		await capture("course_%d_pause" % number)
		await click("Resume")
		level.end_run(false)
		await frames(4)
		await capture("course_%d_result" % number)
		if number == 5:
			await click("Menu")
			await click("Courses")
			await capture("course_list" )

func cleanup() -> void:
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(game.persistence_path + suffix)
