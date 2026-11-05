class_name LevelDefs
extends RefCounted

static var LEVELS: Array[Dictionary] = campaign()

static func campaign() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = [SkyGardenData.definition()]
	definitions.append_array(CampaignCourses.definitions())
	return definitions

# Isolated legacy fixtures retain their original data contract.
const LEGACY_LEVELS: Array[Dictionary] = [{
	"number": 1, "name": "Lazy River",
	"goal_text": "Toot to the finish ring in 75 seconds",
	"time_limit": 75.0, "bots": 0, "bot_toot_delay": 1.6, "bot_aim_error_deg": 20.0,
	"segments": [
		{"d": 0.0, "length": 24.0, "width": 14.0, "x": 0.0},
		{"d": 24.0, "length": 24.0, "width": 14.0, "x": 2.0},
		{"d": 48.0, "length": 24.0, "width": 14.0, "x": 0.0},
		{"d": 72.0, "length": 24.0, "width": 14.0, "x": -2.0},
		{"d": 96.0, "length": 24.0, "width": 14.0, "x": 0.0},
		{"d": 120.0, "length": 30.0, "width": 14.0, "x": 1.0}
	],
	"islands": [],
	"holes": [
		{"pos": [-3.5, 18.0], "radius": 1.8},
		{"pos": [5.0, 41.0], "radius": 1.8},
		{"pos": [-4.0, 65.0], "radius": 1.6},
		{"pos": [2.5, 88.0], "radius": 1.8},
		{"pos": [-3.5, 112.0], "radius": 1.7},
		{"pos": [4.5, 131.0], "radius": 1.5}
	],
	"obstacles": [],
	"beans": [[0.0, 10.0], [1.5, 28.0], [0.0, 47.0], [0.0, 62.0], [-2.0, 79.0], [-1.0, 97.0], [0.5, 116.0], [0.0, 132.0]],
	"checkpoints": [45.0, 95.0],
	"waypoints": [[0.0, 2.0], [0.0, 21.0], [1.0, 37.0], [0.0, 60.0], [-2.0, 77.0], [-1.0, 96.0], [0.0, 118.0], [0.0, 143.0]],
	"start": [0.0, 2.0], "finish_d": 140.0
}]

static func world_point(point: Array) -> Vector3:
	return Vector3(float(point[0]), 0.0, -float(point[1]))
