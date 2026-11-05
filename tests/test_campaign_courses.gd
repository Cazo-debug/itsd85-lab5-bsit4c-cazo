extends GutTest

func test_all_five_routes_have_clearance_height_and_safe_ordered_checkpoints() -> void:
	var titles: Array[String] = []
	for definition: Dictionary in LevelDefs.LEVELS:
		titles.append(definition.name)
		var path: CoursePath = CoursePath.new()
		path.build(definition)
		assert_gt(path.length, 400.0, definition.name)
		var low: float = INF
		var high: float = -INF
		for frame: Dictionary in path.frames:
			low = minf(low, frame.position.y)
			high = maxf(high, frame.position.y)
			assert_gte(frame.width, 5.6, definition.name + " keeps hull clearance")
			assert_lt(absf(rad_to_deg(asin(frame.tangent.y))), 15.0, definition.name + " controllable slope")
		assert_gt(high - low, 9.0, definition.name + " real elevation")
		assert_eq(definition.checkpoints.size(), 2)
		assert_lt(definition.checkpoints[0], definition.checkpoints[1])
		for fraction: float in definition.checkpoints:
			var distance: float = fraction * path.length + 3.0
			var safe: Transform3D = path.safe_transform(distance)
			assert_true(path.surface_at(safe.origin, distance).valid)
			for hazard: Dictionary in definition.hazards:
				assert_gt(absf(distance - hazard.fraction * path.length), 10.0, "Checkpoint outside hazard sweep")
		for hole: Dictionary in path.holes:
			var at: Dictionary = path.sample(hole.s)
			assert_false(path.surface_at(at.position + at.lateral * hole.lateral, hole.s).valid)
			assert_true(path.surface_at(at.position, hole.s).valid, "Central safe line is open")
	assert_eq(titles.size(), 5)
	var unique: Dictionary = {}
	for title: String in titles:
		unique[title] = true
	assert_eq(unique.size(), 5)
	assert_ne(LevelDefs.LEVELS[1].path, LevelDefs.LEVELS[2].path)
	assert_ne(LevelDefs.LEVELS[2].path, LevelDefs.LEVELS[3].path)
	assert_ne(LevelDefs.LEVELS[3].path, LevelDefs.LEVELS[4].path)

func test_new_hazard_motion_and_whirlpool_surface_forces_are_deterministic() -> void:
	var path: CoursePath = CoursePath.new()
	path.build(LevelDefs.LEVELS[3])
	for kind: String in ["crusher", "gate", "boulder", "whirlpool"]:
		var hazard: CourseHazard = CourseHazard.new()
		hazard.configure({"type": kind, "fraction": 0.5, "lateral": 0.0}, path)
		add_child_autofree(hazard)
		var before: Transform3D = hazard.evaluate(2.75)
		hazard.update_time(19.0)
		assert_eq(hazard.evaluate(2.75), before)
		assert_ne(hazard.evaluate(0.0), hazard.evaluate(1.25), kind + " really moves")
		assert_ne(hazard.response, "reset", "Ordinary solid hazards are recoverable")
	var zone: Dictionary = path.flow_zones[1]
	var frame: Dictionary = path.sample(zone.s)
	var left: Vector3 = path.surface_at(frame.position + frame.lateral * (zone.lateral - 2), zone.s).flow
	var right: Vector3 = path.surface_at(frame.position + frame.lateral * (zone.lateral + 2), zone.s).flow
	assert_lt(left.dot(frame.tangent) * right.dot(frame.tangent), 0.0, "Opposite sides swirl in opposite directions")
	assert_lte(left.length(), 3.0)
	assert_lte(right.length(), 3.0)

func test_new_solids_open_and_close_real_collision_and_contact_the_ring() -> void:
	var path: CoursePath = CoursePath.new()
	path.build(LevelDefs.LEVELS[1])
	for kind: String in ["crusher", "gate", "boulder"]:
		var hazard: CourseHazard = CourseHazard.new()
		hazard.configure({"type": kind, "fraction": 0.5, "lateral": 0.0, "travel": 6.0}, path)
		add_child(hazard)
		var ring: SwimRing = preload("res://scenes/actors/SwimRing.tscn").instantiate() as SwimRing
		var profiles: Array[Dictionary] = CrewData.default_profiles()
		profiles[0] = AvatarData.default_avatar()
		ring.checkpoint_s = path.length * 0.5
		ring.setup(path, profiles, CrewData.default_slots(), 0)
		add_child(ring)
		hazard.update_time(3.75 if kind == "crusher" else 0.0)
		ring.simulate = true
		ring.freeze = false
		await wait_physics_frames(30)
		assert_gt(ring.contact_count, 0, kind + " makes an actual solver contact")
		var frame: Dictionary = path.sample(path.length * 0.5)
		var origin: Vector3 = frame.position + frame.normal * 0.5
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin - frame.tangent * 3, origin + frame.tangent * 3, 2)
		assert_false(get_viewport().world_3d.direct_space_state.intersect_ray(query).is_empty(), kind + " blocks the crossing when closed")
		hazard.update_time(1.25)
		await wait_physics_frames(2)
		assert_true(get_viewport().world_3d.direct_space_state.intersect_ray(query).is_empty(), kind + " opens a real collision-free window")
		ring.queue_free()
		hazard.queue_free()
		await get_tree().process_frame

func test_all_campaign_ribbon_boundaries_are_free_of_self_intersections() -> void:
	for definition: Dictionary in LevelDefs.LEVELS:
		var path: CoursePath = CoursePath.new()
		path.build(definition)
		var segments: Array[Dictionary] = []
		for side: float in [-1.0, 1.0]:
			for index: int in range(path.frames.size() - 1):
				var a: Dictionary = path.frames[index]
				var b: Dictionary = path.frames[index + 1]
				var first: Vector3 = a.position + a.lateral * a.width * 0.5 * side
				var last: Vector3 = b.position + b.lateral * b.width * 0.5 * side
				var start: Vector2 = Vector2(first.x, first.z)
				var end: Vector2 = Vector2(last.x, last.z)
				segments.append({"a": start, "b": end, "bounds": Rect2(start, end - start).abs().grow(0.0001), "side": side, "index": index})
		var intersections: int = 0
		for first: int in range(segments.size()):
			var a: Dictionary = segments[first]
			for last: int in range(first + 1, segments.size()):
				var b: Dictionary = segments[last]
				if a.side == b.side and abs(a.index - b.index) <= 1:
					continue
				if a.bounds.intersects(b.bounds) and Geometry2D.segment_intersects_segment(a.a, a.b, b.a, b.b) != null:
					intersections += 1
		assert_eq(intersections, 0, definition.name + " has no crossed ribbon boundaries")
