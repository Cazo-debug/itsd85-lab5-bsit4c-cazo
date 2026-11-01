extends GutTest

class RoutedScreen:
	extends "res://scripts/Screen.gd"
	var destination: String = ""
	func go(target: String) -> void:
		destination = target

const PATH: String = "user://v3_crew_ui_test.cfg"
var snapshot: Dictionary

func before_each() -> void:
	snapshot = {}
	for key: String in ["local_profiles", "crew_slots", "leader_profile", "selected_profile", "creator_return", "persistence_path"]:
		var value: Variant = GameState.get(key)
		snapshot[key] = value.duplicate(true) if value is Array else value
	GameState.persistence_path = PATH
	GameState.local_profiles = CrewData.default_profiles()
	GameState.set_profile(0, AvatarData.default_avatar())
	GameState.crew_slots = CrewData.default_slots()
	GameState.selected_profile = 0
	GameState.leader_profile = 0
	GameState.creator_return = "MainMenu"

func after_each() -> void:
	for key: String in snapshot:
		GameState.set(key, snapshot[key])
	for suffix: String in ["", ".pre-v2.bak", ".tmp"]:
		DirAccess.remove_absolute(PATH + suffix)

func test_selected_profile_save_and_cancel_are_isolated() -> void:
	var original: Array = GameState.local_profiles.duplicate(true)
	GameState.selected_profile = 2
	GameState.creator_return = "CrewSetup"
	var page: RoutedScreen = RoutedScreen.new()
	page.screen = "AvatarCreator"
	add_child_autofree(page)
	page.cycle("hat", 1)
	page.name_field.text = "Third"
	page.back()
	assert_eq(page.destination, "CrewSetup")
	assert_eq(GameState.local_profiles, original, "Back does not save the draft")
	page.save_avatar()
	assert_eq(GameState.local_profiles[2].name, "Third")
	assert_eq(GameState.local_profiles[2].hat, 1)
	for index: int in [0, 1, 3]:
		assert_eq(GameState.local_profiles[index], original[index])
	assert_eq(GameState.avatar, original[0])
	assert_eq(GameState.crew_slots[2].control, "empty", "Preview does not assign unoccupied seats")

func test_crew_controls_preview_and_leader_persist() -> void:
	var page: RoutedScreen = RoutedScreen.new()
	page.screen = "CrewSetup"
	add_child_autofree(page)
	assert_eq(page.model.riders.size(), 1)
	for index: int in range(1, 4):
		page.select_seat(index)
		page.cycle_control()
		assert_eq(GameState.crew_slots[index].control, "assist")
	assert_eq(page.model.riders.size(), 4)
	page.make_leader()
	assert_eq(GameState.leader_profile, 3)
	page.edit_crew_profile()
	assert_eq(GameState.selected_profile, 3)
	assert_eq(GameState.creator_return, "CrewSetup")
	assert_eq(page.destination, "AvatarCreator")
	page.cycle_control()
	assert_eq(GameState.crew_slots[3].control, "local")
	page.cycle_control()
	assert_eq(GameState.crew_slots[3].control, "empty")
	assert_eq(page.model.riders.size(), 3)
	assert_eq(GameState.leader_profile, 0)
	page.select_seat(1)
	page.cycle_crew_profile(1)
	assert_eq(GameState.crew_slots[1].profile, 3, "Skips a profile already in use")
	var saved: ConfigFile = ConfigFile.new()
	saved.load(PATH)
	assert_eq(saved.get_value("game", "crew_slots"), GameState.crew_slots)
	page.back()
	assert_eq(page.destination, "MainMenu")
