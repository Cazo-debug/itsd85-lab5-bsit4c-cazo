class_name CampaignFlow
extends RefCounted

# Application rules only: no Control, theme, layout, node paths or scene mutation.
static func launch_error(game: Node, number: int, practice: bool = false) -> String:
	if number < 1 or number > LevelDefs.LEVELS.size():
		return "This course is unavailable."
	if not practice and not game.is_unlocked(number):
		return "Complete the previous course to unlock this one."
	if not game.has_crew():
		return "Add a rider before launching."
	for slot: Dictionary in game.crew_slots:
		if slot.control == "local":
			return ""
	return "Choose at least one Local rider to steer."

static func prepare_launch(game: Node, number: int, practice: bool = false) -> String:
	if not launch_error(game, number, practice).is_empty():
		return ""
	var locals: Array[int] = []
	for index: int in range(game.crew_slots.size()):
		if game.crew_slots[index].control == "local":
			locals.append(index)
	if game.active_local_seat not in locals:
		game.active_local_seat = locals[0]
	game.current_level = number
	game.mode = "offline"
	return "res://scenes/levels/Practice.tscn" if practice else game.level_scene_path(number)

static func finish(game: Node, number: int, elapsed: float, limit: float, won: bool, recoveries: int, practice: bool) -> Dictionary:
	if not is_finite(elapsed) or elapsed < 0 or not is_finite(limit) or limit <= 0 or number < 1 or number > LevelDefs.LEVELS.size():
		won = false
		elapsed = 0.0
	won = won and elapsed < limit
	var stars: int = game.calc_stars(maxf(0, limit - elapsed), limit) if won and not practice else 0
	var result: Dictionary = {"won": won, "stars": stars, "level": number, "time": elapsed,
		"recoveries": recoveries, "practice": practice, "saved": false, "save_error": OK}
	if practice:
		return result
	game.last_result = result.duplicate()
	if won and game.mode == "offline" and game.is_unlocked(number):
		game.complete_level(number, stars, elapsed)
		result.save_error = game.last_save_error
		result.saved = result.save_error == OK
	game.last_result = result.duplicate()
	return result

static func next_level(game: Node, result: Dictionary) -> int:
	var next: int = int(result.get("level", 0)) + 1
	if game.mode == "offline" and result.get("won", false) and not result.get("practice", false) and next <= LevelDefs.LEVELS.size() and game.is_unlocked(next):
		return next
	return 0

static func toggle_sound(game: Node) -> Error:
	game.settings.sound = not game.settings.get("sound", true)
	return game.save_progress(game.persistence_path)

static func course_cards(game: Node) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for definition: Dictionary in LevelDefs.LEVELS:
		var number: int = definition.number
		cards.append({"number": number, "name": definition.name, "unlocked": game.is_unlocked(number),
			"stars": int(game.best_stars.get(number, 0)), "time": float(game.best_times.get(number, 0))})
	return cards
