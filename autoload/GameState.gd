extends Node

const SAVE_PATH: String = "user://save.cfg"
const TOTAL_LEVELS: int = 5
const DEFAULT_SETTINGS: Dictionary = {"sound": true, "music_volume": 0.7, "vibration": true, "quality": "high", "show_fps": false}
var unlocked_level: int = 1
var best_stars: Dictionary = {}
var best_times: Dictionary = {}
var current_level: int = 1
var mode: String = "offline"
var last_result: Dictionary = {}
var avatar: Dictionary = {}
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var seen_tutorial: bool = false
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

func save_progress(path: String = SAVE_PATH) -> void:
	var config: ConfigFile = ConfigFile.new()
	for key: String in ["unlocked_level", "best_stars", "best_times", "avatar", "settings", "seen_tutorial"]:
		config.set_value("game", key, get(key))
	var error: Error = config.save(path)
	if error != OK:
		push_warning("Could not save progress: %s" % error_string(error))

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
	avatar = AvatarData.sanitize(saved_avatar) if saved_avatar is Dictionary and not saved_avatar.is_empty() else {}
	settings = DEFAULT_SETTINGS.duplicate()
	var saved_settings: Variant = config.get_value("game", "settings", {})
	if saved_settings is Dictionary:
		for key: String in ["sound", "vibration", "show_fps"]:
			if saved_settings.get(key) is bool:
				settings[key] = saved_settings[key]
		var volume: Variant = saved_settings.get("music_volume")
		if (volume is float or volume is int) and is_finite(volume):
			settings.music_volume = clampf(volume, 0.0, 1.0)
		if saved_settings.get("quality") in ["low", "high"]:
			settings.quality = saved_settings.quality
	seen_tutorial = config.get_value("game", "seen_tutorial", false) == true

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
