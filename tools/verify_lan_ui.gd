extends SceneTree

# Rendered presentation fixtures only, not network or human acceptance.
var net: Node
var failed: bool = false
var checks: int = 0

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error(message)

func frames(count: int) -> void:
	for frame: int in range(count): await process_frame

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/phase4_" + label + ".png")

func verify() -> void:
	net = root.get_node("Net")
	net.navigating = false
	var game: Node = root.get_node("GameState")
	var original_mode: String = game.mode
	change_scene_to_file("res://scenes/ui/ModeSelect.tscn")
	await frames(6)
	check(current_scene.name == "ModeSelect", "Mode Select available")
	await capture("mode_select")
	check(net.host(AvatarData.default_avatar(), 17780) == OK, "Fixture session opens")
	for seat: int in range(1, 4):
		net.owners[seat] = seat + 10
		net.profiles[seat] = AvatarData.sanitize({"name": "Rider %d" % (seat + 1), "outfit": seat + 1})
		net.ready_peers[seat + 10] = true
	change_scene_to_file("res://scenes/ui/Lobby.tscn")
	await frames(8)
	check(current_scene.model.riders.size() == 4, "Four lobby occupants on one ring")
	check(not current_scene.start_button.disabled, "Ready crew can start")
	await capture("lobby_four")
	net.phase = "loading"
	change_scene_to_file("res://scenes/levels/Level01.tscn")
	await frames(6)
	var level: Node3D = current_scene
	level.begin_run()
	level.race_time = 112.5
	level.end_run(true)
	check(level.result.get("online", false), "Actual online HUD presents cooperative result")
	await frames(6)
	await capture("shared_result")
	net.close_session()
	check(game.mode == original_mode, "Fixture restores original mode")
	print("LAN presentation fixtures: %d checks, passed=%s" % [checks, not failed])
	quit(1 if failed else 0)
