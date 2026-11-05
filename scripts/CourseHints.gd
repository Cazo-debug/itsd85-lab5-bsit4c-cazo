class_name CourseHints
extends RefCounted

static func for_run(path: CoursePath, distance: float, gas: float, falling: bool) -> String:
	if falling:
		return "The whole crew returns to its checkpoint."
	if gas < 0.25:
		return "Release HOLD to refill your gas."
	for zone: Dictionary in path.flow_zones:
		if absf(distance - zone.s) < 12.0 and zone.kind == "whirlpool":
			return "Countersteer across the swirling water."
	if path.exposed_at(distance, 1.0):
		return "Stay centered: this bridge has an open edge."
	for hole: Dictionary in path.holes:
		if hole.s - distance > 0 and hole.s - distance < 18:
			return "Foam-rimmed holes drop the whole crew."
	if distance < 20:
		return "Aim, hold to push, release to coast."
	return "Wait for moving hazards; cross together."
