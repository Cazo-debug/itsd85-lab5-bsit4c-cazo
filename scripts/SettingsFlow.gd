class_name SettingsFlow
extends RefCounted

# Validation and persistence, without layout or scene navigation.
static func update(game: Node, key: String, value: Variant) -> Error:
	if key in ["sound", "vibration", "show_fps", "reduced_motion"]:
		if not value is bool:
			return ERR_INVALID_PARAMETER
	elif key == "quality":
		if value not in ["low", "high"]:
			return ERR_INVALID_PARAMETER
	elif key == "music_volume":
		if not (value is int or value is float) or not is_finite(value):
			return ERR_INVALID_PARAMETER
		value = clampf(float(value), 0, 1)
	else:
		return ERR_INVALID_PARAMETER
	game.settings[key] = value
	return game.save_progress(game.persistence_path)

static func apply_quality(level: Node3D, low: bool) -> void:
	# Presentation only: never change route, support, hazards, gas or seat count.
	for jet: CPUParticles3D in level.player.jets:
		jet.amount = 6 if low else 10
	level.player.spray.amount = 12 if low else 24
	if is_instance_valid(level.course.decor.clouds):
		level.course.decor.clouds.visible = not low
