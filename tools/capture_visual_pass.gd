extends SceneTree

# Rendered 720x1280 evidence for the graphics/game-feel pass: idle, all four riders
# farting, a turn, a fall and a finish (VisualShowcase drives the normal seat inputs).
# Run windowed (not headless), for example:
#   .bin/Godot_v4.7.2-stable_win64_console.exe --path . --resolution 720x1280 \
#     -s tools/capture_visual_pass.gd -- --tag=after --quality=high
const OUTPUT: String = "res://docs/screenshots/visual_pass"
# Untyped: a -s script compiles before the autoloads that SkyLevel depends on.
var level: Node3D
var showcase: Node
var tag: String = "after"
var quality: String = "high"
var saved: Array[String] = []
var probe: Array = []

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--tag="):
			tag = argument.trim_prefix("--tag=")
		elif argument.begins_with("--quality="):
			quality = argument.trim_prefix("--quality=")
		elif argument.begins_with("--probe="):
			probe = Array(argument.trim_prefix("--probe=").split(","))
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(720, 1280)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var game: Node = root.get_node("GameState")
	game.persistence_path = "user://visual_pass_capture.cfg"
	game.settings = game.DEFAULT_SETTINGS.duplicate()
	game.settings.quality = quality
	game.settings.show_fps = true
	game.mode = "offline"
	game.seen_tutorial = true
	game.local_profiles = CrewData.default_profiles()
	game.local_profiles[0] = AvatarData.default_avatar()
	game.crew_slots = CrewData.default_slots()
	for seat: int in range(4):
		game.assign_slot(seat, "local", seat)
		game.local_profiles[seat].toot = seat
	level = load("res://scenes/levels/Level01.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	while level.state != level.State.RACING:
		await physics_frame
	showcase = load("res://scripts/VisualShowcase.gd").new()
	showcase.level = level
	showcase.hold_seconds = 0.4
	showcase.step_ready.connect(save_step)
	level.add_child(showcase)
	if not probe.is_empty():
		showcase.probe(probe)
		while not showcase.finished:
			await process_frame
		print("VISUAL_PASS_PROBE ", JSON.stringify(showcase.probe_results))
		quit(0)
		return
	showcase.run()
	while not showcase.finished:
		await process_frame
	await process_frame
	print("VISUAL_PASS_RESULT ", JSON.stringify({"tag": tag, "quality": quality, "saved": saved,
		"firing": showcase.summary(), "won": level.won}))
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(game.persistence_path + suffix)
	quit(0 if saved.size() == showcase.STEPS.size() and level.won else 1)

func save_step(step: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var path: String = "%s/%s_%s.png" % [OUTPUT, tag, step]
	root.get_texture().get_image().save_png(path)
	saved.append(step)
