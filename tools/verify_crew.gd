extends SceneTree

const PATH: String = "user://v3_crew_verifier.cfg"
var failed: bool = false

func _initialize() -> void:
	call_deferred("verify")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func settle() -> void:
	for frame: int in range(10):
		await process_frame

func press_text(node: Node, text: String) -> bool:
	if node is Button and node.text == text:
		node.pressed.emit()
		return true
	for child: Node in node.get_children():
		if press_text(child, text):
			return true
	return false

func check_layout(node: Node, scrolling: bool = false) -> void:
	if node is Control and node.is_visible_in_tree():
		if node is Button or node is LineEdit:
			check(node.size.y >= 120 and node.size.x >= 120, "%s has a small touch target" % node.name)
		if not scrolling and (node is Button or node is Label or node is SubViewportContainer):
			var rect: Rect2 = node.get_global_rect()
			check(rect.position.y >= 80 and rect.end.y <= 1280 and rect.position.x >= 0 and rect.end.x <= 720, "%s extends outside safe viewport: %s" % [node.name, rect])
	for child: Node in node.get_children():
		if not child is SubViewport:
			check_layout(child, scrolling or node is ScrollContainer)

func capture(tag: String) -> void:
	await settle()
	check_layout(current_scene)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://docs/screenshots/phase1_crew_%s.png" % tag) == OK, "Screenshot failed")
		print("RENDER ", tag, " draw calls: ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " primitives: ", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))

func verify() -> void:
	root.size = Vector2i(720, 1280)
	var state: Node = root.get_node("GameState")
	state.persistence_path = PATH
	state.local_profiles = CrewData.default_profiles()
	state.crew_slots = CrewData.default_slots()
	state.selected_profile = 0
	state.creator_return = "MainMenu"
	change_scene_to_file("res://scenes/ui/Title.tscn")
	await settle()
	check(press_text(current_scene, "Tap to start"), "Title start missing")
	await settle()
	check(current_scene.name == "AvatarCreator", "First launch must create a profile")
	current_scene.name_field.text = "Skipper"
	check(press_text(current_scene, "Save"), "Creator Save missing")
	await settle()
	check(current_scene.name == "MainMenu", "Creator did not return to menu")
	check(press_text(current_scene, "Play"), "Play missing")
	await settle()
	check(current_scene.name == "CrewSetup", "Play must open CrewSetup")
	check(current_scene.model.riders.size() == 1, "Default crew should have one rider")
	await capture("one")
	for index: int in range(1, 4):
		current_scene.crew_buttons[index].pressed.emit()
		current_scene.crew_control_button.pressed.emit()
		state.local_profiles[index].hat = index
		state.local_profiles[index].float_style = index
	check(current_scene.model.riders.size() == 4, "Four-rider preview missing")
	check(press_text(current_scene, "Make leader"), "Leader control missing")
	await capture("four")
	check(press_text(current_scene, "Edit rider"), "Edit rider missing")
	await settle()
	check(current_scene.name == "AvatarCreator" and state.selected_profile == 3, "Wrong edited profile")
	current_scene.name_field.text = "Cloud Captain"
	current_scene.cycle("hat", 1)
	await capture("creator")
	check(press_text(current_scene, "Save"), "Save missing")
	await settle()
	check(current_scene.name == "CrewSetup", "Edited rider must return to crew")
	check(state.avatar.name == "Skipper", "Editing another profile changed profile zero")
	var expected: Array = state.local_profiles.duplicate(true)
	state.local_profiles = CrewData.default_profiles()
	state.load_progress(PATH)
	check(state.local_profiles == expected and state.crew_slots.size() == 4, "Saved crew failed to reload")
	check(state.leader_profile == 3, "Leader failed to persist")
	current_scene._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await settle()
	check(current_scene.name == "MainMenu", "Android Back failed")
	check(press_text(current_scene, "Play"), "Play missing")
	await settle()
	check(press_text(current_scene, "Modes / legacy prototype"), "Legacy entry missing")
	await settle()
	check(current_scene.name == "ModeSelect", "Mode route failed")
	await capture("modes")
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(PATH + suffix)
	print("Crew navigation, layout and persistence: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)
