class_name SkyGardenData
extends RefCounted

static func definition() -> Dictionary:
	return {
		"number": 1, "name": "Sky Garden", "time_limit": 240.0,
		"goal_text": "One ring. Reach the summit together!",
		"path": [Vector3(0, 0, 10), Vector3(0, 0, -12), Vector3(20, 0, -36), Vector3(24, 0, -60), Vector3(4, 1, -82), Vector3(-8, 2, -106), Vector3(4, 4, -133), Vector3(28, 7, -150), Vector3(50, 10, -175), Vector3(60, 10, -202), Vector3(82, 10, -219), Vector3(107, 10, -210), Vector3(118, 9, -185), Vector3(112, 6, -154), Vector3(98, 1, -124), Vector3(105, -1, -96), Vector3(130, 1, -74), Vector3(150, 1, -45), Vector3(142, 1, -20)],
		"widths": [[0.0, 20.0], [0.08, 16.0], [0.20, 16.0], [0.255, 7.2], [0.31, 7.2], [0.36, 17.0], [0.69, 17.0], [0.77, 20.0], [1.0, 20.0]],
		"checkpoints": [0.23, 0.70],
		"holes": [{"fraction": 0.875, "lateral": -5.1, "radius": 2.9}, {"fraction": 0.935, "lateral": 5.1, "radius": 2.9}],
		"hazards": [{"type": "bumper", "fraction": 0.105, "lateral": -4.5}, {"type": "bumper", "fraction": 0.16, "lateral": 4.5}, {"type": "current", "fraction": 0.205, "lateral": 0.0}, {"type": "sweeper", "fraction": 0.40, "lateral": 4.7}, {"type": "mallet", "fraction": 0.765, "lateral": -6.2}, {"type": "crossbar", "fraction": 0.825, "lateral": 5.0}],
		"beans": [0.055, 0.19, 0.235, 0.335, 0.47, 0.62, 0.71, 0.80, 0.90, 0.97],
		"sections": [[0.0, "Cloud launch"], [0.08, "Garden S-bends"], [0.245, "Narrow sky bridge"], [0.32, "Climb & crest"], [0.48, "Canyon return"], [0.74, "Obstacle garden"], [0.96, "Shared finish"]]
	}
