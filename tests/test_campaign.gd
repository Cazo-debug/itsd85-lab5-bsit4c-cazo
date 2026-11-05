extends GutTest

const StateScript: Script = preload("res://autoload/GameState.gd")
const PATH: String = "user://phase3_campaign_test.cfg"
var game: Node

func before_each() -> void:
	game = StateScript.new()
	game.persistence_path = PATH
	add_child_autofree(game)
	game.local_profiles = CrewData.default_profiles()
	game.set_profile(0, AvatarData.default_avatar())
	game.crew_slots = CrewData.default_slots()
	game.unlocked_level = 1
	game.best_times.clear()
	game.best_stars.clear()
	game.mode = "offline"

func after_each() -> void:
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(PATH + suffix)

func test_launch_locks_crew_and_local_owner_validation() -> void:
	assert_eq(CampaignFlow.course_cards(game).size(), 5)
	assert_eq(CampaignFlow.prepare_launch(game, 2), "")
	assert_eq(CampaignFlow.prepare_launch(game, 0), "")
	assert_eq(CampaignFlow.prepare_launch(game, 6), "")
	assert_eq(CampaignFlow.prepare_launch(game, 1), game.level_scene_path(1))
	game.assign_slot(0, "empty")
	assert_false(CampaignFlow.launch_error(game, 1).is_empty())
	game.assign_slot(2, "assist", 2)
	assert_false(CampaignFlow.launch_error(game, 1).is_empty())
	game.assign_slot(2, "local", 2)
	assert_eq(CampaignFlow.prepare_launch(game, 1), game.level_scene_path(1))
	assert_eq(game.active_local_seat, 2)
	assert_eq(game.crew_slots[0].control, "empty")

func test_ordered_campaign_results_reload_and_final_next_boundary() -> void:
	for number: int in range(1, 6):
		var result: Dictionary = CampaignFlow.finish(game, number, 60.0 + number, 240, true, number - 1, false)
		assert_eq(result.level, number)
		assert_eq(result.stars, 3)
		assert_true(result.saved)
		assert_eq(CampaignFlow.next_level(game, result), number + 1 if number < 5 else 0)
		assert_false(result.has("place"))
	assert_eq(game.unlocked_level, 5)
	var reloaded: Node = StateScript.new()
	reloaded.persistence_path = PATH
	add_child_autofree(reloaded)
	assert_eq(reloaded.best_times, game.best_times)
	assert_eq(reloaded.best_stars, game.best_stars)
	assert_eq(reloaded.local_profiles, game.local_profiles)
	assert_eq(reloaded.crew_slots, game.crew_slots)
	CampaignFlow.finish(game, 1, 180, 240, true, 0, false)
	assert_eq(game.best_times[1], 61.0)
	assert_eq(game.best_stars[1], 3)

func test_failure_practice_online_and_invalid_results_preserve_progress() -> void:
	var result: Dictionary = CampaignFlow.finish(game, 1, 240, 240, false, 2, false)
	assert_eq(result.stars, 0)
	assert_eq(CampaignFlow.next_level(game, result), 0)
	assert_eq(game.unlocked_level, 1)
	CampaignFlow.finish(game, 1, 25, 240, true, 0, true)
	assert_eq(game.unlocked_level, 1)
	assert_false(FileAccess.file_exists(PATH))
	game.mode = "online"
	assert_false(CampaignFlow.finish(game, 1, 25, 240, true, 0, false).saved)
	assert_eq(game.unlocked_level, 1)
	game.mode = "offline"
	assert_false(CampaignFlow.finish(game, 1, NAN, 240, true, 0, false).won)
	assert_true(game.best_times.is_empty())

func test_save_failure_is_reported_and_prior_file_is_preserved() -> void:
	assert_eq(game.save_progress(PATH), OK)
	var original: String = FileAccess.get_file_as_string(PATH)
	game.persistence_path = "user://phase3_missing_%d/save.cfg" % Time.get_ticks_usec()
	var result: Dictionary = CampaignFlow.finish(game, 1, 60, 240, true, 0, false)
	assert_false(result.saved)
	assert_ne(result.save_error, OK)
	assert_eq(FileAccess.get_file_as_string(PATH), original)
	game.persistence_path = PATH
	assert_eq(game.save_progress(PATH), OK)
	var restored: ConfigFile = ConfigFile.new()
	assert_eq(restored.load(PATH), OK)
	assert_eq(restored.get_value("game", "unlocked_level"), 2)

func test_sound_toggle_round_trips_without_touching_crew_or_progress() -> void:
	var profiles: Array = game.local_profiles.duplicate(true)
	assert_eq(CampaignFlow.toggle_sound(game), OK)
	var restored: Node = StateScript.new()
	restored.persistence_path = PATH
	add_child_autofree(restored)
	assert_false(restored.settings.sound)
	assert_eq(restored.local_profiles, profiles)
	assert_eq(restored.unlocked_level, 1)
