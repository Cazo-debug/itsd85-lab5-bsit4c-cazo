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

const LOW_3D_SCALE: float = 0.75

static func apply_quality(level: Node3D, low: bool) -> void:
	# Presentation only: never change route, support, hazards, gas or seat count.
	# Low is the fallback for weak phones: fewer puffs and spray, no droplet bursts,
	# one water texture layer (no streaks/sparkles), no cloud lobes or cloud cards,
	# and the 3D view drawn at 75% resolution (the HUD stays sharp).
	var config: FartConfig = FartConfig.current
	level.player.set_puff_count(config.puffs_per_burst_low if low else config.puffs_per_burst)
	level.player.spray.amount = 12 if low else 24
	level.player.wake.amount = 4 if low else 8
	level.player.set_effects_quality(low)
	level.course.set_quality(low)
	if level.is_inside_tree():
		level.get_viewport().scaling_3d_scale = LOW_3D_SCALE if low else 1.0
	if is_instance_valid(level.course.decor.clouds):
		level.course.decor.clouds.visible = not low
