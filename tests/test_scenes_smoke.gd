extends GutTest

class RoutedScreen:
	extends "res://scripts/Screen.gd"
	var destination: String = ""
	func go(target: String) -> void:
		destination = target

func test_first_launch_and_back_navigation() -> void:
	var original: Dictionary = GameState.avatar.duplicate(true)
	GameState.avatar = {}
	var page: RoutedScreen = RoutedScreen.new()
	page.start()
	assert_eq(page.destination, "AvatarCreator")
	page.screen = "AvatarCreator"
	page.back()
	assert_eq(page.destination, "Title")
	GameState.avatar = AvatarData.default_avatar()
	page.start()
	assert_eq(page.destination, "MainMenu")
	page.back()
	assert_eq(page.destination, "MainMenu")
	for destination: String in ["ModeSelect", "Settings", "Credits"]:
		page.screen = destination
		page._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		assert_eq(page.destination, "MainMenu")
	page.screen = "MainMenu"
	page.back()
	assert_eq(page.destination, "Title")
	page.free()
	GameState.avatar = original

func test_creator_controls_and_save() -> void:
	var original: Dictionary = GameState.avatar.duplicate(true)
	var original_path: String = GameState.persistence_path
	GameState.persistence_path = "user://phase1_creator_test.cfg"
	GameState.avatar = {}
	var page: RoutedScreen = RoutedScreen.new()
	page.screen = "AvatarCreator"
	add_child(page)
	for key: String in AvatarData.LIMITS:
		page.cycle(key, -1)
		assert_eq(page.draft[key], AvatarData.LIMITS[key] - 1)
		assert_eq(page.model.appearance[key], page.draft[key])
		page.cycle(key, 1)
		assert_eq(page.draft[key], 0)
	page.randomize_avatar()
	assert_eq(AvatarData.sanitize(page.draft), page.draft)
	page.name_field.text = "Skipper"
	page.save_avatar()
	assert_eq(page.destination, "MainMenu")
	assert_eq(GameState.avatar.name, "Skipper")
	var saved: ConfigFile = ConfigFile.new()
	assert_eq(saved.load(GameState.persistence_path), OK)
	assert_eq(saved.get_value("game", "avatar"), GameState.avatar)
	page.queue_free()
	await get_tree().process_frame
	DirAccess.remove_absolute(GameState.persistence_path)
	GameState.avatar = original
	GameState.persistence_path = original_path

func find_scenes(path: String) -> Array[String]:
	var result: Array[String] = []
	for file: String in DirAccess.get_files_at(path):
		if file.ends_with(".tscn"):
			result.append(path.path_join(file))
	for directory: String in DirAccess.get_directories_at(path):
		result.append_array(find_scenes(path.path_join(directory)))
	return result

func test_every_scene_loads_and_instantiates() -> void:
	var paths: Array[String] = find_scenes("res://scenes")
	assert_gte(paths.size(), 7)
	for path: String in paths:
		var packed: PackedScene = load(path) as PackedScene
		assert_not_null(packed, path)
		var instance: Node = packed.instantiate()
		add_child(instance)
		await get_tree().process_frame
		assert_true(instance.is_inside_tree(), path)
		instance.queue_free()
		await get_tree().process_frame
