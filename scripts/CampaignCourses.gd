class_name CampaignCourses
extends RefCounted

# Original route data. Geometry, water, riders and movement use the shared pipeline.
static func definitions() -> Array[Dictionary]:
	return [
		course(2, "Canyon Switchbacks", "Cross the canyon in 260 s. Dodge the mallets and boulders!", 260.0,
			[Vector3(0, 4, 10), Vector3(0, 4, -16), Vector3(18, 2, -45), Vector3(40, 1, -75), Vector3(42, 0, -112), Vector3(20, 0, -140), Vector3(-6, 1, -170), Vector3(-8, 3, -205), Vector3(16, 6, -235), Vector3(50, 8, -248), Vector3(85, 8, -240), Vector3(102, 7, -212), Vector3(96, 4, -178), Vector3(85, 1, -145), Vector3(108, -2, -117), Vector3(141, -1, -98), Vector3(164, 0, -70), Vector3(170, 0, -38)],
			[[0.0, 20.0], [0.10, 16.0], [0.23, 10.0], [0.33, 14.0], [0.49, 18.0], [0.64, 13.0], [0.75, 18.0], [1.0, 20.0]],
			[{"type": "bumper", "fraction": 0.12, "lateral": -4.6}, {"type": "mallet", "fraction": 0.19, "lateral": -5.6}, {"type": "mallet", "fraction": 0.36, "lateral": 5.6, "phase": 1.4}, {"type": "gate", "fraction": 0.44, "lateral": 5.5}, {"type": "boulder", "fraction": 0.58, "lateral": -4.8}, {"type": "crossbar", "fraction": 0.79, "lateral": 4.5}, {"type": "boulder", "fraction": 0.91, "lateral": 4.8}],
			["Launch basin", "Coral switchbacks", "Exposed canyon bend", "Paired mallets", "High return", "Gate and boulders", "Canyon finish"], Color("086e9b"), Color("55c8df"), Color("ffb57b")),
		course(3, "Cloud Bridges", "Cross the sky bridges in 270 s. Time the crushers!", 270.0,
			[Vector3(0, 0, 12), Vector3(0, 0, -18), Vector3(-20, 3, -48), Vector3(-30, 7, -80), Vector3(-10, 11, -112), Vector3(22, 13, -138), Vector3(50, 12, -165), Vector3(72, 10, -198), Vector3(104, 10, -205), Vector3(133, 8, -183), Vector3(139, 4, -148), Vector3(120, 1, -112), Vector3(124, -2, -80), Vector3(152, 0, -52), Vector3(173, 4, -18), Vector3(170, 6, 12)],
			[[0.0, 20.0], [0.12, 14.0], [0.23, 8.0], [0.34, 8.0], [0.42, 18.0], [0.57, 9.0], [0.67, 18.0], [0.80, 12.0], [1.0, 20.0]],
			[{"type": "crossbar", "fraction": 0.15, "lateral": 4.4}, {"type": "crusher", "fraction": 0.37, "lateral": -4.8}, {"type": "gate", "fraction": 0.48, "lateral": 5.6}, {"type": "crossbar", "fraction": 0.60, "lateral": 4.5}, {"type": "crusher", "fraction": 0.77, "lateral": 4.8, "phase": 2.0}, {"type": "bumper", "fraction": 0.88, "lateral": -4.8}],
			["Cloud dock", "First crossing", "Narrow sky climb", "Crusher waiting pool", "Staggered bridges", "Lower crossings", "Cloud finish"], Color("326fba"), Color("a1e9f5"), Color("c4c6f5")),
		course(4, "Spiral Springs", "Ride the spiral in 290 s. Beat the currents and whirlpools!", 290.0,
			[Vector3(0, 0, 10), Vector3(0, 0, -20), Vector3(20, 3, -52), Vector3(58, 7, -74), Vector3(100, 11, -80), Vector3(140, 14, -62), Vector3(160, 14, -24), Vector3(148, 11, 15), Vector3(116, 7, 39), Vector3(77, 3, 43), Vector3(44, 0, 65), Vector3(46, -1, 98), Vector3(77, 2, 119), Vector3(113, 4, 110), Vector3(142, 6, 84), Vector3(174, 7, 70), Vector3(205, 7, 81)],
			[[0.0, 20.0], [0.15, 16.0], [0.28, 10.0], [0.39, 20.0], [0.59, 19.0], [0.69, 12.0], [0.82, 20.0], [1.0, 20.0]],
			[{"type": "current", "fraction": 0.13, "lateral": 0.0, "cross_flow": 1.4}, {"type": "whirlpool", "fraction": 0.22, "lateral": -3.0}, {"type": "sweeper", "fraction": 0.39, "lateral": 4.8}, {"type": "whirlpool", "fraction": 0.50, "lateral": 3.0, "strength": -1.8}, {"type": "current", "fraction": 0.63, "lateral": 0.0, "cross_flow": -1.5}, {"type": "gate", "fraction": 0.78, "lateral": -5.8}, {"type": "sweeper", "fraction": 0.91, "lateral": 4.8}],
			["Spring dock", "Cross-current climb", "Upper spiral", "Whirlpool descent", "Lower spring", "Return passage", "Spring finish"], Color("147e88"), Color("78e5c3"), Color("f5c47c")),
		course(5, "Festival Summit", "Final challenge: reach the summit in 300 s!", 300.0,
			[Vector3(0, 2, 12), Vector3(0, 2, -16), Vector3(23, 1, -45), Vector3(47, 2, -75), Vector3(40, 6, -112), Vector3(12, 11, -142), Vector3(0, 14, -178), Vector3(23, 16, -208), Vector3(58, 16, -222), Vector3(91, 13, -210), Vector3(112, 9, -183), Vector3(112, 5, -148), Vector3(136, 1, -116), Vector3(166, -1, -94), Vector3(188, 1, -63), Vector3(184, 5, -28), Vector3(160, 7, -6)],
			[[0.0, 20.0], [0.12, 15.0], [0.24, 9.0], [0.34, 18.0], [0.47, 17.0], [0.59, 10.0], [0.71, 20.0], [0.84, 8.0], [0.93, 18.0], [1.0, 20.0]],
			[{"type": "bumper", "fraction": 0.11, "lateral": -4.7}, {"type": "current", "fraction": 0.17, "lateral": 0.0, "cross_flow": 1.0}, {"type": "crossbar", "fraction": 0.23, "lateral": 4.2}, {"type": "mallet", "fraction": 0.35, "lateral": -5.7}, {"type": "gate", "fraction": 0.43, "lateral": 5.3}, {"type": "crusher", "fraction": 0.50, "lateral": -4.5}, {"type": "sweeper", "fraction": 0.59, "lateral": 4.7}, {"type": "boulder", "fraction": 0.66, "lateral": -4.7}, {"type": "whirlpool", "fraction": 0.77, "lateral": 3.0}, {"type": "crossbar", "fraction": 0.85, "lateral": 4.2}, {"type": "gate", "fraction": 0.94, "lateral": -5.7}],
			["Festival dock", "Opening combination", "Summit climb", "Mallet and gate", "Fast descent", "Final balance bridge", "Summit finish"], Color("305eaa"), Color("56d6e8"), Color("ffabd0"))
	]

static func course(number: int, title: String, goal: String, limit: float, points: Array, widths: Array, hazards: Array, titles: Array, deep: Color, shallow: Color, bank: Color) -> Dictionary:
	var style: WaterStyle = WaterStyle.new()
	style.deep_color = deep
	style.shallow_color = shallow
	var sections: Array = []
	var starts: Array[float] = [0.0, 0.09, 0.245, 0.34, 0.53, 0.74, 0.965]
	for index: int in range(titles.size()):
		sections.append([starts[index], titles[index]])
	return {"number": number, "name": title, "time_limit": limit,
		"goal_text": goal, "path": points, "widths": widths,
		"hazards": hazards, "water_style": style, "bank_color": bank,
		"cliff_tint": Color(0.85, 0.90, 1.1) if number == 3 else Color.WHITE,
		"checkpoints": [0.29, 0.71],
		"holes": [{"fraction": 0.81 if number != 5 else 0.89, "lateral": -5.5, "radius": 2.7}, {"fraction": 0.91 if number != 5 else 0.975, "lateral": 5.5, "radius": 2.7}],
		"beans": [0.05, 0.18, 0.30, 0.41, 0.55, 0.67, 0.72, 0.87, 0.96],
		"sections": sections, "exposed": Vector2(0.245, 0.315) if number != 3 else Vector2(0.22, 0.34)}
