extends GutTest

class RoutedLevel:
	extends "res://scripts/Level.gd"
	var destination: String = ""
	func leave_scene(path: String) -> void:
		destination = path

const PATH: String = "user://phase3_ui_test.cfg"
var snapshot: Dictionary

func before_each() -> void:
	snapshot = {}
	for key: String in ["persistence_path", "local_profiles", "crew_slots", "unlocked_level", "current_level", "active_local_seat", "leader_profile", "settings", "last_result", "best_times", "best_stars", "seen_tutorial", "mode", "last_save_error"]:
		var value: Variant = GameState.get(key)
		snapshot[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	GameState.persistence_path = PATH
	GameState.local_profiles = CrewData.default_profiles()
	GameState.set_profile(0, AvatarData.default_avatar())
	GameState.crew_slots = CrewData.default_slots()
	GameState.unlocked_level = 3
	GameState.current_level = 1
	GameState.active_local_seat = 0
	GameState.leader_profile = 0
	GameState.settings = GameState.DEFAULT_SETTINGS.duplicate()
	GameState.seen_tutorial = true
	GameState.mode = "offline"

func after_each() -> void:
	for key: String in snapshot:
		GameState.set(key, snapshot[key])
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(PATH + suffix)

func find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):
		return node
	for child: Node in node.get_children():
		var found: Button = find_button(child, prefix)
		if found:
			return found
	return null

func test_level_select_locks_and_settings_use_the_campaign_contract() -> void:
	var page: Control = preload("res://scenes/ui/LevelSelect.tscn").instantiate()
	add_child_autofree(page)
	assert_false(find_button(page, "3.").disabled)
	assert_true(find_button(page, "4.").disabled)
	assert_true(find_button(page, "5.").disabled)
	var settings: Control = preload("res://scenes/ui/Settings.tscn").instantiate()
	add_child_autofree(settings)
	settings.toggle_sound()
	assert_false(GameState.settings.sound)
	var file: ConfigFile = ConfigFile.new()
	assert_eq(file.load(PATH), OK)
	assert_false(file.get_value("game", "settings").sound)
	assert_eq(GameState.unlocked_level, 3)

func test_presentation_snapshot_is_detached_from_physics_and_save_state() -> void:
	var level: RoutedLevel = RoutedLevel.new()
	add_child_autofree(level)
	var view: Dictionary = level.run_snapshot()
	view.crew[0].gas = 0
	view.progress = 1
	view.result["won"] = true
	level.hud.present(view)
	assert_eq(level.player.gas[0], 1.0)
	assert_lt(level.player.route_s, 10.0)
	assert_eq(GameState.unlocked_level, 3)
	assert_eq(level.state, SkyLevel.State.INTRO)

func test_paused_quit_touch_reaches_ui_instead_of_the_disabled_gas_pad() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.own_world_3d = true
	add_child_autofree(viewport)
	var level: RoutedLevel = RoutedLevel.new()
	viewport.add_child(level)
	level.begin_run()
	level.player.set_thrust_input(0, Vector3.FORWARD, 1.0, true)
	level.toggle_pause()
	await get_tree().process_frame
	await get_tree().process_frame
	var target: Button = find_button(level.hud.root, "Quit to menu")
	assert_not_null(target)
	assert_false(true in level.player.held)
	var point: Vector2 = target.get_global_rect().get_center()
	point.x = level.hud.controls.gas_rect().get_center().x
	assert_true(viewport.get_visible_rect().has_point(point), "Pause action must fit inside the portrait viewport")
	assert_true(target.get_global_rect().has_point(point))
	assert_true(level.hud.controls.gas_rect().has_point(point), "Exercise the UI button over the hidden gas pad")
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 8
	touch.position = point
	touch.pressed = true
	var neutral: InputEventAction = InputEventAction.new()
	neutral.action = "ui_cancel"
	viewport.push_input(neutral)
	assert_false(viewport.is_input_handled(), "The isolated viewport begins with unhandled input")
	# Inspect ownership during the input phase; the GUI is expected to handle it later.
	level.hud.controls._input(touch)
	assert_false(viewport.is_input_handled(), "Disabled gameplay pads must leave UI touches available")
	for down: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.position = point
		event.global_position = point
		event.pressed = down
		viewport.push_input(event)
		await get_tree().process_frame
	assert_eq(level.destination, "res://scenes/ui/MainMenu.tscn")
	assert_eq(level.player.force_seconds[0], 0.0, "Pause/UI touches cannot apply force")

func test_result_is_for_actual_course_and_is_committed_only_once() -> void:
	var level: RoutedLevel = RoutedLevel.new()
	level.level_number = 3
	add_child_autofree(level)
	level.begin_run()
	level.race_time = 80
	level.end_run(true)
	assert_eq(GameState.last_result.level, 3)
	assert_eq(GameState.unlocked_level, 4)
	assert_not_null(find_button(level.hud.root, "Next course"))
	var first: Dictionary = GameState.last_result.duplicate(true)
	level.race_time = 100
	level.end_run(false)
	assert_eq(GameState.last_result, first)
	level.handle_action("next")
	assert_eq(level.destination, GameState.level_scene_path(4))

func test_contextual_hints_and_first_thrust_mark_tutorial_without_practice_progress() -> void:
	var path: CoursePath = CoursePath.new()
	path.build(LevelDefs.LEVELS[0])
	assert_true(CourseHints.for_run(path, path.length * 0.28, 1, false).contains("bridge"))
	assert_true(CourseHints.for_run(path, 20, 0.1, false).contains("Release"))
	var level: RoutedLevel = RoutedLevel.new()
	level.practice = true
	add_child_autofree(level)
	GameState.seen_tutorial = false
	level.mark_tutorial_seen(0)
	assert_false(GameState.seen_tutorial)
	assert_false(FileAccess.file_exists(PATH))
	level.practice = false
	level.mark_tutorial_seen(0)
	assert_true(GameState.seen_tutorial)
	assert_true(FileAccess.file_exists(PATH))
