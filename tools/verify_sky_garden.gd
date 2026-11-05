extends SceneTree

var level: Node3D
var failed: bool = false
var captures: bool = false
var recording: bool = false
var capture_index: int = 0
var record_index: int = 0
var frame_times: Array[float] = []
var max_draw_calls: int = 0
var max_triangles: int = 0
var max_height: float = -INF
var min_height: float = INF
var previous_tick: int = 0
var crew_count: int = 1
var seed_phase: int = 0
var capture_prefix: String = "phase2_v3"
var record_directory: String = ".bin/sky-record-jpg"
var level_number: int = 1
var assistants: bool = false
var resume_on_focus: bool = false
var focus_resumes: int = 0
var quality: String = "high"
var four_firing_frames: int = 0

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			level_number = clampi(int(argument.trim_prefix("--level=")), 1, 5)
		if argument.begins_with("--crew="):
			crew_count = clampi(int(argument.trim_prefix("--crew=")), 1, 4)
		if argument.begins_with("--seed="):
			seed_phase = int(argument.trim_prefix("--seed="))
		if argument.begins_with("--capture-prefix="):
			capture_prefix = argument.trim_prefix("--capture-prefix=").validate_filename()
		if argument.begins_with("--record-dir=.bin/") and not argument.contains(".."):
			record_directory = argument.trim_prefix("--record-dir=")
		if argument in ["--quality=low", "--quality=high"]:
			quality = argument.trim_prefix("--quality=")
	captures = "--capture" in OS.get_cmdline_user_args()
	recording = "--record" in OS.get_cmdline_user_args()
	assistants = "--assistants" in OS.get_cmdline_user_args()
	resume_on_focus = "--resume-on-focus" in OS.get_cmdline_user_args()
	if recording:
		DirAccess.make_dir_recursive_absolute("res://" + record_directory)
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func capture(tag: String) -> void:
	if captures and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://docs/screenshots/%s_%s.png" % [capture_prefix, tag])

func _process(_delta: float) -> bool:
	if is_instance_valid(level) and level.state == level.State.RACING and level.race_time > 1:
		if level.player.firing.count(true) == 4:
			four_firing_frames += 1
		var tick: int = Time.get_ticks_usec()
		if previous_tick > 0:
			frame_times.append((tick - previous_tick) / 1000.0)
		previous_tick = tick
		max_draw_calls = maxi(max_draw_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		max_triangles = maxi(max_triangles, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	else:
		previous_tick = 0
	return false

func verify() -> void:
	root.size = Vector2i(720, 1280)
	var game: Node = root.get_node("GameState")
	game.settings = game.DEFAULT_SETTINGS.duplicate()
	game.settings.quality = quality
	game.persistence_path = "user://course_verifier_%d_%d_%d%s.cfg" % [level_number, crew_count, seed_phase, "_assist" if assistants else ""]
	game.current_level = level_number
	game.unlocked_level = level_number
	game.local_profiles = CrewData.default_profiles()
	game.local_profiles[0] = AvatarData.default_avatar()
	game.crew_slots = CrewData.default_slots()
	for seat: int in range(crew_count):
		game.local_profiles[seat].hat = seat
		game.assign_slot(seat, "assist" if assistants and seat > 0 else "local", seat)
	game.leader_profile = 0
	level = load(game.level_scene_path(level_number)).instantiate()
	root.add_child(level)
	current_scene = level
	level.brain.all_seats = not assistants
	level.brain.clock = seed_phase * 0.17
	if assistants:
		var driver: CrewBrain = CrewBrain.new()
		driver.ring = level.player
		driver.all_seats = true
		driver.control_seat = 0
		driver.clock = seed_phase * 0.17
		level.add_child(driver)
	for frame: int in range(3):
		await process_frame
	await capture("overview")
	check(level.player.visual.riders.size() == crew_count, "Configured rider count differs")
	check(not level.player.set_thrust_input(0, Vector3.FORWARD, 1, true), "Countdown must reject input")
	print("START crew=", crew_count, " seed=", seed_phase, " length=", level.course.path.length)
	var tags: Array[String] = ["s_bend", "bridge", "climb", "hairpin", "descent", "obstacles", "holes", "finish"]
	var fractions: Array[float] = [0.12, 0.275, 0.36, 0.57, 0.68, 0.77, 0.88, 0.965]
	var last_report: int = -1
	var frame_count: int = 0
	while level.state != level.State.FINISHED and frame_count < ceili((level.time_limit + 15) * 60):
		await physics_frame
		frame_count += 1
		if level.state == level.State.PAUSED and resume_on_focus:
			level.toggle_pause()
			focus_resumes += 1
		level.hud.controls.enabled = false
		var ratio: float = level.player.route_s / level.course.path.length
		max_height = maxf(max_height, level.player.position.y)
		min_height = minf(min_height, level.player.position.y)
		if int(level.race_time / 10) > last_report:
			last_report = int(level.race_time / 10)
			print("RUN t=", snappedf(level.race_time, 0.1), " s=", snappedf(level.player.route_s, 0.1), " y=", snappedf(level.player.position.y, 0.1), " gas=", level.player.gas, " falls=", level.player.recoveries)
		if capture_index < fractions.size() and ratio >= fractions[capture_index]:
			await capture(tags[capture_index])
			capture_index += 1
		if recording and frame_count % 2 == 0 and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_jpg("res://%s/%05d.jpg" % [record_directory, record_index], 0.9)
			record_index += 1
	check(level.won, "Normal thrust driver did not finish")
	check(level.checkpoint_index == 2, "Both ordered checkpoints must be crossed")
	check(max_height - min_height > 9.0, "Physical body failed to climb and descend")
	check(not game.last_result.has("place"), "Cooperative result has a finishing place")
	if DisplayServer.get_name() != "headless":
		check(max_draw_calls > 0 and frame_times.size() > 60, "Rendered verification must collect real frame samples")
		check(max_draw_calls < 150, "Rendered draw calls exceed the course budget")
		check(max_triangles < 60000, "Rendered primitives exceed the course budget")
		if crew_count == 4:
			check(four_firing_frames > 60, "Rendered profiling must sample all four riders firing")
	if "--result-capture" in OS.get_cmdline_user_args():
		captures = true
	await capture("result")
	frame_times.sort()
	var report: Dictionary = {"passed": not failed, "crew": crew_count, "seed": seed_phase, "seconds": level.race_time, "recoveries": level.player.recoveries, "contacts": level.player.contact_count, "max_tilt_degrees": rad_to_deg(level.player.peak_tilt), "height_min": min_height, "height_max": max_height, "pickups": level.pickups_collected, "max_draw_calls": max_draw_calls, "max_primitives": max_triangles, "headless": DisplayServer.get_name() == "headless", "recording": recording, "force_seconds": level.player.force_seconds}
	report["level"] = level_number
	report["course"] = level.definition.name
	report["assistants"] = assistants
	report["focus_resumes"] = focus_resumes
	report["quality"] = quality
	report["four_firing_frames"] = four_firing_frames
	if not frame_times.is_empty():
		report["frame_ms_median"] = frame_times[frame_times.size() / 2]
		report["frame_ms_p95"] = frame_times[int(frame_times.size() * 0.95)]
	print("RESULT ", JSON.stringify(report))
	var report_path: String = "res://.bin/sky_result_%d_%d.json" % [crew_count, seed_phase] if level_number == 1 else "res://.bin/course_result_%d_%d_%d.json" % [level_number, crew_count, seed_phase]
	if assistants:
		report_path = report_path.trim_suffix(".json") + "_assist.json"
	if quality == "low":
		report_path = report_path.trim_suffix(".json") + "_low.json"
	var output: FileAccess = FileAccess.open(report_path, FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(game.persistence_path + suffix)
	root.get_node("Audio").stop_all()
	await create_timer(0.12, true, false, true).timeout
	quit(1 if failed else 0)
