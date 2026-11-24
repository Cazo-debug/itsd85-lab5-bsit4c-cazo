extends GutTest

# Checks tied directly to the ITSD 85 lab PDF.

func test_every_level_has_its_own_goal_with_its_time_limit() -> void:
	# R2: "Clear goal per level shown to the player (e.g. Collect 10 stars in 60 seconds)".
	var seen: Array[String] = []
	assert_gte(LevelDefs.LEVELS.size(), 5, "R1: at least 5 levels")
	for definition: Dictionary in LevelDefs.LEVELS:
		var goal: String = definition.goal_text
		assert_false(goal in seen, "Each level has a different goal")
		seen.append(goal)
		assert_true(goal.contains("%d s" % int(definition.time_limit)), "Goal states the time limit: " + goal)

func test_goal_text_is_visible_when_a_level_starts() -> void:
	var level: SkyLevel = SkyLevel.new()
	add_child_autofree(level)
	await wait_frames(2)
	level.hud.present(level.run_snapshot())
	assert_true(level.hud.banner.visible)
	assert_true(level.hud.banner.text.contains(LevelDefs.LEVELS[0].goal_text), "R2: goal on the start banner")

func test_android_presets_use_team_package_and_version_one() -> void:
	# PDF p. 22: com.itsd85.<teamname>.<gamename>; release v1.0.
	var presets: ConfigFile = ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK)
	var found: bool = false
	for section: String in presets.get_sections():
		if section.ends_with(".options") or presets.get_value(section, "name", "") != "Android Release":
			continue
		found = true
		var options: String = section + ".options"
		assert_eq(presets.get_value(options, "package/unique_name"), "com.itsd85.cazo.toottubes")
		assert_eq(presets.get_value(options, "version/name"), "1.0")
		assert_true(presets.get_value(options, "permissions/internet"), "R7/A.4 Internet permission")
		assert_true(presets.get_value(options, "permissions/access_network_state"), "A.4 network state permission")
	assert_true(found, "Android Release preset exists")
	assert_eq(ProjectSettings.get_setting("application/config/version"), "1.0")

func test_android_back_during_a_run_opens_pause_instead_of_quitting() -> void:
	# PDF p. 21: the Android back gesture must work; during play it must not lose the run.
	var level: SkyLevel = SkyLevel.new()
	add_child_autofree(level)
	await wait_frames(2)
	level.begin_run()
	level.state = level.State.RACING
	level._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(level.state, level.State.PAUSED, "Back opens the pause menu instead of leaving")
	level._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_eq(level.state, level.State.RACING, "Back again resumes")
