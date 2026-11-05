extends GutTest

const PATH: String = "user://phase5_polish_test.cfg"
var saved: Dictionary

func before_each() -> void:
	saved = {}
	for key: String in ["settings", "persistence_path", "local_profiles", "crew_slots", "leader_profile", "mode", "last_save_error"]:
		var value: Variant = GameState.get(key)
		saved[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	GameState.persistence_path = PATH
	GameState.settings = GameState.DEFAULT_SETTINGS.duplicate()
	GameState.local_profiles = CrewData.default_profiles()
	GameState.set_profile(0, AvatarData.default_avatar())
	GameState.crew_slots = []
	for seat: int in range(4): GameState.crew_slots.append(CrewData.make_slot("local", seat))
	GameState.mode = "offline"

func after_each() -> void:
	for key: String in saved: GameState.set(key, saved[key])
	Audio.stop_all()
	Audio.apply_settings()
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]: DirAccess.remove_absolute(PATH + suffix)

func test_settings_validation_round_trip_and_old_save_defaults() -> void:
	for change: Array in [["quality", "low"], ["music_volume", 0.3], ["reduced_motion", false], ["vibration", false], ["show_fps", true], ["sound", false]]:
		assert_eq(SettingsFlow.update(GameState, change[0], change[1]), OK)
	var restored: Node = load("res://autoload/GameState.gd").new()
	restored.persistence_path = PATH
	add_child_autofree(restored)
	assert_eq(restored.settings, GameState.settings)
	var before: Dictionary = GameState.settings.duplicate()
	for change: Array in [["quality", "ultra"], ["music_volume", NAN], ["music_volume", "loud"], ["reduced_motion", 1], ["anything", true]]:
		assert_eq(SettingsFlow.update(GameState, change[0], change[1]), ERR_INVALID_PARAMETER)
	assert_eq(GameState.settings, before)
	var old: ConfigFile = ConfigFile.new()
	old.set_value("game", "settings", {"quality": "low", "sound": false})
	assert_eq(old.save(PATH), OK)
	restored.load_progress(PATH)
	assert_true(restored.settings.get("reduced_motion", true))
	assert_eq(restored.settings.quality, "low")
	assert_false(restored.settings.sound)

func test_low_quality_preserves_all_four_riders_and_physics_contract() -> void:
	var level: SkyLevel = SkyLevel.new()
	add_child_autofree(level)
	var profile: Dictionary = {"mass": level.player.mass, "path": level.course.path.length, "collisions": level.player.collision_mask, "gas": level.player.gas.duplicate(), "hazards": level.course.hazards.size()}
	SettingsFlow.apply_quality(level, true)
	assert_eq(level.player.visual.riders.size(), 4)
	assert_false(level.course.decor.clouds.visible)
	assert_eq(level.player.jets[3].amount, 6)
	assert_eq(level.player.spray.amount, 12)
	assert_eq(level.player.mass, profile.mass)
	assert_eq(level.course.path.length, profile.path)
	assert_eq(level.player.collision_mask, profile.collisions)
	assert_eq(level.player.gas, profile.gas)
	assert_eq(level.course.hazards.size(), profile.hazards)
	SettingsFlow.apply_quality(level, false)
	assert_true(level.course.decor.clouds.visible)
	assert_eq(level.player.jets[3].amount, 10)
	assert_eq(level.player.spray.amount, 24)

func test_audio_follows_actual_thrust_and_stops_on_pause_fall_finish_and_exit() -> void:
	var level: SkyLevel = SkyLevel.new()
	add_child(level)
	level.begin_run()
	level.player.firing[0] = true
	level.feedback._process(0.016)
	assert_true(Audio.targets[0])
	level.player.falling = true
	level.feedback._process(0.016)
	assert_false(Audio.targets[0])
	level.player.falling = false
	level.feedback._process(0.016)
	assert_true(Audio.targets[0])
	level.toggle_pause()
	level.feedback._process(0.016)
	assert_false(Audio.targets[0])
	level.toggle_pause()
	level.player.firing[0] = true
	level.feedback._process(0.016)
	level.end_run(false)
	level.feedback._process(0.016)
	assert_eq(Audio.targets, [false, false, false, false])
	level.free()
	assert_eq(Audio.targets, [false, false, false, false])

func test_title_and_scrollable_settings_preserve_portrait_targets() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	add_child_autofree(viewport)
	var title: Control = load("res://scenes/ui/Title.tscn").instantiate()
	viewport.add_child(title)
	await wait_process_frames(4)
	assert_eq(title.model.riders.size(), 4)
	check_buttons(title, true)
	title.free()
	var settings: Control = load("res://scenes/ui/Settings.tscn").instantiate()
	viewport.add_child(settings)
	await wait_process_frames(4)
	check_buttons(settings, false)
	settings.adjust_volume(-0.2)
	settings.toggle("quality")
	settings.toggle("reduced_motion")
	assert_almost_eq(GameState.settings.music_volume, 0.5, 0.001)
	assert_eq(GameState.settings.quality, "low")
	assert_false(GameState.settings.reduced_motion)

func check_buttons(node: Node, visible_bounds: bool) -> void:
	if node is Button:
		assert_gte(node.size.y, 120.0)
		if visible_bounds:
			assert_gte(node.global_position.y, 80.0)
			assert_lte(node.get_global_rect().end.y, 1280.0)
	for child: Node in node.get_children(): check_buttons(child, visible_bounds)
