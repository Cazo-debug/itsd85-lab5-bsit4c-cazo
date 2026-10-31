extends GutTest

const StateScript: Script = preload("res://autoload/GameState.gd")
const TEST_PATH: String = "user://phase1_test_save.cfg"
var state: Node

func before_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)
	state = StateScript.new()
	state.persistence_path = TEST_PATH
	add_child_autofree(state)

func after_each() -> void:
	DirAccess.remove_absolute(TEST_PATH)

func test_progression_bounds_and_repeated_completion() -> void:
	assert_eq(state.unlocked_level, 1)
	assert_true(state.is_unlocked(1))
	assert_false(state.is_unlocked(0))
	state.complete_level(1, 3, 20.0)
	state.complete_level(1, 1, 30.0)
	assert_eq(state.unlocked_level, 2)
	assert_eq(state.best_stars[1], 3)
	assert_eq(state.best_times[1], 20.0)
	state.complete_level(4, 3, 10.0)
	assert_eq(state.unlocked_level, 2, "Locked levels cannot advance progress")
	for level: int in range(2, 6):
		state.complete_level(level, 2, 15.0)
	assert_eq(state.unlocked_level, 5)
	assert_false(state.is_unlocked(6))

func test_save_load_and_reset() -> void:
	state.complete_level(1, 2, 24.0)
	state.avatar = AvatarData.default_avatar()
	state.avatar.name = "Captain"
	state.settings.sound = false
	state.seen_tutorial = true
	state.save_progress(TEST_PATH)
	var restored: Node = StateScript.new()
	restored.persistence_path = TEST_PATH
	add_child_autofree(restored)
	assert_eq(restored.unlocked_level, 2)
	assert_eq(restored.best_stars, state.best_stars)
	assert_eq(restored.best_times, state.best_times)
	assert_eq(restored.avatar, state.avatar)
	assert_false(restored.settings.sound)
	assert_true(restored.seen_tutorial)
	restored.reset_progress()
	assert_eq(restored.unlocked_level, 1)
	assert_eq(restored.best_stars, {})
	assert_eq(restored.best_times, {})
	assert_false(restored.seen_tutorial)
	assert_true(restored.has_avatar(), "Reset progress preserves customization")

func test_star_boundaries() -> void:
	assert_eq(StateScript.calc_stars(50.01, 100.0), 3)
	assert_eq(StateScript.calc_stars(50.0, 100.0), 2)
	assert_eq(StateScript.calc_stars(25.01, 100.0), 2)
	assert_eq(StateScript.calc_stars(25.0, 100.0), 1)
	assert_eq(StateScript.calc_stars(0.01, 100.0), 1)
	assert_eq(StateScript.calc_stars(0.0, 100.0), 0)
	assert_eq(StateScript.calc_stars(-1.0, 100.0), 0)
	assert_eq(StateScript.calc_stars(10.0, 0.0), 0)

func test_online_results_never_advance_campaign() -> void:
	state.mode = "online"
	state.complete_level(1, 3, 10.0)
	assert_eq(state.unlocked_level, 1)
	assert_eq(state.best_stars, {})
