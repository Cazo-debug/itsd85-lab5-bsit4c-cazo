extends Node

const SAVE_PATH: String = "user://save.cfg"
const SAVE_VERSION: int = 2
const TOTAL_LEVELS: int = 5
const DEFAULT_SETTINGS: Dictionary = {"sound": true, "music_volume": 0.7, "vibration": true, "quality": "high", "show_fps": false}
var unlocked_level: int = 1
var best_stars: Dictionary = {}
var best_times: Dictionary = {}
var current_level: int = 1
var mode: String = "offline"
## Star Scramble mode for offline runs: coop, versus or teams (see MatchRules). Not saved.
var match_mode: String = "coop"
var last_result: Dictionary = {}
var save_version: int = SAVE_VERSION
var local_profiles: Array[Dictionary] = CrewData.default_profiles()
var crew_slots: Array[Dictionary] = CrewData.default_slots()
var leader_profile: int = 0
var selected_profile: int = 0
var creator_return: String = "MainMenu"
var active_local_seat: int = 0
# Keep legacy readers and in-place avatar edits attached to profile zero.
var avatar: Dictionary:
	get:
		return local_profiles[0]
	set(value):
		local_profiles[0] = AvatarData.sanitize(value) if not value.is_empty() else {}
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var seen_tutorial: bool = false
var last_save_error: Error = OK
# Tests set this on their isolated instance; production uses SAVE_PATH.
var persistence_path: String = SAVE_PATH

func _ready() -> void:
	load_progress(persistence_path)

func is_unlocked(level: int) -> bool:
	return level >= 1 and level <= unlocked_level and level <= TOTAL_LEVELS

func complete_level(level: int, stars: int, time_used: float) -> void:
	if mode != "offline" or not is_unlocked(level) or stars < 1 or not is_finite(time_used) or time_used < 0.0:
		return
	best_stars[level] = maxi(int(best_stars.get(level, 0)), clampi(stars, 1, 3))
	best_times[level] = minf(float(best_times.get(level, INF)), time_used)
	unlocked_level = maxi(unlocked_level, mini(level + 1, TOTAL_LEVELS))
	save_progress(persistence_path)

func save_progress(path: String = SAVE_PATH) -> Error:
	# Preserve the exact original bytes before a migration or corrupt-file repair.
	if FileAccess.file_exists(path):
		var previous: ConfigFile = ConfigFile.new()
		var loaded: Error = previous.load(path)
		var previous_version: Variant = previous.get_value("game", "save_version", 0)
		if loaded != OK or not previous_version is int or previous_version != SAVE_VERSION:
			var backup: String = path + ".pre-v2.bak"
			if not FileAccess.file_exists(backup):
				var copied: Error = DirAccess.copy_absolute(path, backup)
				if copied != OK:
					push_warning("Save migration stopped: backup failed")
					last_save_error = copied
					return copied
	local_profiles = CrewData.sanitize_profiles(local_profiles)
	crew_slots = CrewData.sanitize_slots(crew_slots, local_profiles)
	validate_leader()
	var config: ConfigFile = ConfigFile.new()
	for key: String in ["unlocked_level", "best_stars", "best_times", "avatar", "settings", "seen_tutorial", "local_profiles", "leader_profile"]:
		config.set_value("game", key, get(key))
	config.set_value("game", "save_version", SAVE_VERSION)
	config.set_value("game", "crew_slots", CrewData.sanitize_slots(crew_slots, local_profiles, true))
	var error: Error = config.save(path + ".tmp")
	if error == OK:
		error = DirAccess.rename_absolute(path + ".tmp", path)
	if error != OK:
		push_warning("Could not save progress: %s" % error_string(error))
	else:
		save_version = SAVE_VERSION
	last_save_error = error
	return error

func load_progress(path: String = SAVE_PATH) -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
		return
	var saved_level: Variant = config.get_value("game", "unlocked_level", 1)
	unlocked_level = clampi(saved_level, 1, TOTAL_LEVELS) if saved_level is int else 1
	best_stars.clear()
	best_times.clear()
	var stars_data: Variant = config.get_value("game", "best_stars", {})
	var times_data: Variant = config.get_value("game", "best_times", {})
	for level: int in range(1, TOTAL_LEVELS + 1):
		if stars_data is Dictionary and stars_data.get(level) is int:
			best_stars[level] = clampi(stars_data[level], 1, 3)
		if times_data is Dictionary:
			var value: Variant = times_data.get(level)
			if (value is float or value is int) and is_finite(value) and value >= 0:
				best_times[level] = float(value)
	var saved_avatar: Variant = config.get_value("game", "avatar", {})
	local_profiles = CrewData.sanitize_profiles(config.get_value("game", "local_profiles", 0), saved_avatar)
	crew_slots = CrewData.sanitize_slots(config.get_value("game", "crew_slots", 0), local_profiles, true)
	var saved_leader: Variant = config.get_value("game", "leader_profile", 0)
	leader_profile = saved_leader if saved_leader is int else 0
	validate_leader()
	save_version = SAVE_VERSION
	settings = DEFAULT_SETTINGS.duplicate()
	var saved_settings: Variant = config.get_value("game", "settings", {})
	if saved_settings is Dictionary:
		for key: String in ["sound", "vibration", "show_fps"]:
			if saved_settings.get(key) is bool:
				settings[key] = saved_settings[key]
		# Optional preference: preserve old settings dictionaries exactly during migration.
		if saved_settings.get("reduced_motion") is bool:
			settings.reduced_motion = saved_settings.reduced_motion
		var volume: Variant = saved_settings.get("music_volume")
		if (volume is float or volume is int) and is_finite(volume):
			settings.music_volume = clampf(volume, 0.0, 1.0)
		if saved_settings.get("quality") in ["low", "high"]:
			settings.quality = saved_settings.quality
	var saved_tutorial: Variant = config.get_value("game", "seen_tutorial", false)
	seen_tutorial = saved_tutorial is bool and saved_tutorial

func set_profile(index: int, value: Dictionary) -> bool:
	if index < 0 or index >= CrewData.MAX_RIDERS:
		return false
	local_profiles[index] = AvatarData.sanitize(value)
	# First-use creator establishes the initial occupied seat.
	if index == 0 and not has_crew():
		crew_slots = CrewData.default_slots()
	return true

func assign_slot(index: int, control: String, profile: int = -1, owner: String = "") -> bool:
	if index < 0 or index >= CrewData.MAX_RIDERS:
		return false
	var candidate: Dictionary = CrewData.make_slot(control, profile, owner)
	if not CrewData.valid_slot(candidate, local_profiles):
		return false
	for seat: int in range(CrewData.MAX_RIDERS):
		if seat != index and control != "empty" and crew_slots[seat].control != "empty":
			if crew_slots[seat].profile == profile or crew_slots[seat].owner == candidate.owner:
				return false
	crew_slots[index] = candidate
	validate_leader()
	return true

func has_crew() -> bool:
	for slot: Dictionary in crew_slots:
		if slot.control != "empty" and CrewData.valid_slot(slot, local_profiles):
			return true
	return false

func validate_leader() -> void:
	var occupied: Array[int] = []
	for slot: Dictionary in crew_slots:
		if slot.control != "empty" and CrewData.valid_slot(slot, local_profiles):
			occupied.append(slot.profile)
	if leader_profile not in occupied:
		leader_profile = occupied[0] if not occupied.is_empty() else 0

func reset_progress() -> void:
	unlocked_level = 1
	best_stars.clear()
	best_times.clear()
	current_level = 1
	last_result.clear()
	seen_tutorial = false
	save_progress(persistence_path)

func has_avatar() -> bool:
	return not avatar.is_empty()

func level_scene_path(level: int) -> String:
	return "res://scenes/levels/Level%02d.tscn" % clampi(level, 1, TOTAL_LEVELS)

static func calc_stars(time_left: float, time_limit: float) -> int:
	if not is_finite(time_left) or not is_finite(time_limit) or time_left <= 0.0 or time_limit <= 0.0:
		return 0
	var ratio: float = time_left / time_limit
	return 3 if ratio > 0.5 else (2 if ratio > 0.25 else 1)
