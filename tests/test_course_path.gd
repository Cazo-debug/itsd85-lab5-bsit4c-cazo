extends GutTest

var path: CoursePath

func before_each() -> void:
	path = CoursePath.new()
	path.build(LevelDefs.LEVELS[0])

func test_production_route_contains_real_bends_height_and_clearance() -> void:
	assert_gt(path.length, 400.0)
	var positive: bool = false
	var negative: bool = false
	var minimum: float = INF
	var maximum: float = -INF
	var max_slope: float = 0
	for index: int in range(1, path.frames.size()):
		var a: Dictionary = path.frames[index - 1]
		var b: Dictionary = path.frames[index]
		var turn: float = a.tangent.cross(b.tangent).y
		positive = positive or turn > 0.005
		negative = negative or turn < -0.005
		minimum = minf(minimum, b.position.y)
		maximum = maxf(maximum, b.position.y)
		max_slope = maxf(max_slope, absf(asin(b.tangent.y)))
		assert_gt(a.tangent.dot(b.tangent), 0.98, "Continuous tangent through every sampled seam")
		assert_gt(b.width, 4.8 + 1.6, "Physical ring plus tutorial clearance")
		assert_almost_eq(b.normal.dot(b.tangent), 0.0, 0.0001)
	assert_true(positive and negative, "Both directions of the S-bend exist")
	assert_gt(maximum - minimum, 10.0)
	assert_lt(rad_to_deg(max_slope), 15.0)
	var before: Dictionary = path.sample(path.length * 0.47)
	var after: Dictionary = path.sample(path.length * 0.68)
	assert_lt(before.tangent.slide(Vector3.UP).normalized().dot(after.tangent.slide(Vector3.UP).normalized()), cos(deg_to_rad(150)), "Hairpin turns at least 150 degrees")

func test_surface_and_progress_match_the_local_route_and_openings() -> void:
	for hole: Dictionary in path.holes:
		var frame: Dictionary = path.sample(hole.s)
		var center: Vector3 = frame.position + frame.lateral * hole.lateral
		assert_false(path.surface_at(center, hole.s).valid)
		assert_true(path.surface_at(frame.position, hole.s).valid, "Safe central line remains open")
		assert_false(path.surface_at(frame.position + frame.lateral * (frame.width / 2 + 1), hole.s).valid)
	var sample_s: float = path.length * 0.55
	var projected: Dictionary = path.project(path.sample(path.length * 0.68).position, sample_s)
	assert_between(projected.s, sample_s - 23, sample_s + 23, "Projection cannot jump to a nearby return arm")
	for fraction: float in [0.0, 0.12, 0.28, 0.38, 0.57, 0.69, 0.85, 0.99]:
		var frame: Dictionary = path.sample(fraction * path.length)
		var query: Dictionary = path.surface_at(frame.position, frame.s)
		assert_true(query.valid)
		assert_almost_eq(query.height, frame.position.y, 0.01)
	assert_false(path.exposed_at(path.length * 0.1, 1))
	assert_true(path.exposed_at(path.length * 0.28, 1))
	assert_false(path.exposed_at(path.length * 0.28, -1))

func test_generated_ribbon_boundaries_do_not_self_intersect() -> void:
	var edges: Array[PackedVector2Array] = []
	for side: float in [-1.0, 1.0]:
		var edge: PackedVector2Array = PackedVector2Array()
		for frame: Dictionary in path.frames:
			var point: Vector3 = frame.position + frame.lateral * frame.width * 0.5 * side
			edge.append(Vector2(point.x, point.z))
		edges.append(edge)
	var intersections: int = 0
	for side_a: int in range(2):
		for side_b: int in range(side_a, 2):
			for a: int in range(edges[side_a].size() - 1):
				for b: int in range(edges[side_b].size() - 1):
					if side_a == side_b and b <= a + 1:
						continue
					if Geometry2D.segment_intersects_segment(edges[side_a][a], edges[side_a][a + 1], edges[side_b][b], edges[side_b][b + 1]) != null:
						intersections += 1
	assert_eq(intersections, 0, "Reject crossed ribbon edges before shipping a route")

func test_course_has_six_hazard_types_and_safe_checkpoint_transforms() -> void:
	var course: CurvedCourse = CurvedCourse.new()
	add_child_autofree(course)
	course.build(LevelDefs.LEVELS[0])
	var kinds: Array[String] = ["hole"]
	for hazard: CourseHazard in course.hazards:
		kinds.append(hazard.kind)
		var a: Transform3D = hazard.evaluate(2.75)
		hazard.update_time(9)
		assert_eq(hazard.evaluate(2.75), a, "Motion depends only on shared time")
	assert_eq(kinds.count("bumper"), 2)
	for kind: String in ["bumper", "current", "mallet", "sweeper", "crossbar", "hole"]:
		assert_has(kinds, kind)
	assert_eq(course.path.holes.size(), 2)
	assert_eq(course.water.material_override.get_shader_parameter("hole_count"), 2)
	for distance: float in course.checkpoints:
		var safe: Transform3D = course.path.safe_transform(distance + 3)
		assert_true(course.path.surface_at(safe.origin, distance + 3).valid)
		for hazard: CourseHazard in course.hazards:
			assert_gt(absf(distance + 3 - hazard.route_s), 10.0, "Checkpoint avoids entire hazard sweep")
	# Probe the generated bank collision at one curved segment.
	await get_tree().physics_frame
	var frame: Dictionary = course.path.sample(course.path.length * 0.12)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(frame.position + Vector3.UP * 0.3, frame.position + frame.lateral * frame.width + Vector3.UP * 0.3, 2)
	assert_false(course.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "Visible guarded edge has a collider")
