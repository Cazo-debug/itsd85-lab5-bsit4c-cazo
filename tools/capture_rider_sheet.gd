extends SceneTree

# Close-up sheet of every sculpted animal (rows) from behind, the side and the front
# (columns), for checking the body/butt sculpt. Optional state: --pose=idle|fart|cheer|panic.
#   .bin/Godot_v4.7.2-stable_win64_console.exe --path . --resolution 900x1200 \
#     -s tools/capture_rider_sheet.gd -- --out=res://docs/screenshots/visual_pass/riders_sheet.png
const VIEWS: Array[float] = [PI, PI * 0.5, 0.0]
var out: String = "res://docs/screenshots/visual_pass/riders_sheet.png"
var pose: String = "idle"

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out = argument.trim_prefix("--out=")
		elif argument.begins_with("--pose="):
			pose = argument.trim_prefix("--pose=")
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(900, 1200)
	var stage: Node3D = Node3D.new()
	root.add_child(stage)
	load("res://scripts/SkyEnvironment.gd").install(stage)
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.6 * 6.0
	stage.add_child(camera)
	camera.position = Vector3(4.5, 7.5 + 30.0 * tan(0.28), 30)
	camera.look_at(Vector3(4.5, 7.5, 0))
	var riders: Array[Node3D] = []
	for animal: int in range(6):
		for view: int in range(VIEWS.size()):
			var rider: Node3D = load("res://scripts/RiderModel.gd").new()
			var avatar: Dictionary = {"name": "R", "skin": animal, "outfit": 0, "float_style": 0, "hat": 0, "toot": 0}
			stage.add_child(rider)
			rider.apply(avatar)
			rider.setup_motion(animal)
			rider.bake()
			rider.position = Vector3(view * 3.0 + 1.5, (5 - animal) * 2.6 + 0.6, 0)
			rider.rotation = Vector3(0, VIEWS[view], 0)
			riders.append(rider)
	for frame: int in range(40):
		for rider: Node3D in riders:
			if pose == "cheer" or pose == "panic":
				rider.set_mood(pose)
			rider.animate_activity(1.0 / 60.0, pose == "fart", 0.0)
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("RIDER_SHEET ", out)
	quit(0)
