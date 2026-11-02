extends GutTest

var ring: SwimRing
var path: CoursePath

func before_each() -> void:
	path = CoursePath.new()
	path.build(LevelDefs.LEVELS[0])
	var profiles: Array[Dictionary] = CrewData.default_profiles()
	profiles[0] = AvatarData.default_avatar()
	var slots: Array[Dictionary] = []
	for index: int in range(4):
		slots.append(CrewData.make_slot("local", index))
	ring = SwimRing.new()
	ring.setup(path, profiles, slots, 0)
	add_child_autofree(ring)
	ring.simulate = true
	ring.freeze = false
	await wait_physics_frames(4)

func test_held_force_drains_selected_seat_and_release_keeps_momentum() -> void:
	watch_signals(ring)
	assert_true(ring.set_thrust_input(0, Vector3.FORWARD, 1, true))
	await wait_physics_frames(15)
	assert_signal_emitted_with_parameters(ring, "thrust_started", [0])
	var short_time: float = ring.force_seconds[0]
	var short_speed: float = ring.linear_velocity.length()
	await wait_physics_frames(30)
	assert_gt(ring.force_seconds[0], short_time * 2)
	assert_gt(ring.linear_velocity.length(), short_speed)
	assert_lt(ring.gas[0], 1.0)
	assert_eq(ring.gas[1], 1.0)
	ring.set_thrust_input(0, Vector3.ZERO, 0, false)
	await wait_physics_frames(2)
	var stopped: float = ring.force_seconds[0]
	await wait_physics_frames(4)
	assert_eq(ring.force_seconds[0], stopped)
	assert_gt(ring.linear_velocity.length(), 0.1, "Release does not erase momentum")
	assert_false(ring.firing[0])
	assert_signal_emitted_with_parameters(ring, "thrust_stopped", [0])
	assert_true(ring.set_thrust_input(0, Vector3.FORWARD, 1, true))
	await wait_physics_frames(3)
	assert_gt(ring.force_seconds[0], stopped, "Repeated bursts work")

func test_four_seats_contribute_and_invalid_input_is_rejected() -> void:
	for index: int in range(4):
		assert_true(ring.set_thrust_input(index, Vector3.FORWARD, 0.8, true))
	await wait_physics_frames(10)
	for index: int in range(4):
		assert_lt(ring.gas[index], 1.0)
		assert_gt(ring.force_seconds[index], 0.05)
	assert_false(ring.set_thrust_input(4, Vector3.FORWARD, 1, true))
	assert_false(ring.set_thrust_input(-1, Vector3.FORWARD, 1, true))
	assert_false(ring.set_thrust_input(0, Vector3(INF, 0, 0), 1, true))
	assert_false(ring.set_thrust_input(0, Vector3.FORWARD, NAN, true))
	ring.seat_control[3] = "empty"
	assert_false(ring.set_thrust_input(3, Vector3.FORWARD, 1, true))
	ring.simulate = false
	assert_false(ring.set_thrust_input(0, Vector3.FORWARD, 1, true))
	assert_true(ring.set_thrust_input(0, Vector3.ZERO, 0, false), "Release is accepted even when disabled")

func test_depletion_latches_until_rest_and_release() -> void:
	ring.gas[0] = 0.002
	ring.set_thrust_input(0, Vector3.FORWARD, 1, true)
	await wait_physics_frames(12)
	assert_true(ring.depleted[0])
	var emitted: float = ring.force_seconds[0]
	await wait_physics_frames(95)
	assert_eq(ring.force_seconds[0], emitted, "Holding depleted gas never auto-sputters")
	assert_gte(ring.gas[0], ring.profile.rearm_threshold)
	ring.set_thrust_input(0, Vector3.ZERO, 0, false)
	await wait_physics_frames(2)
	assert_false(ring.depleted[0])
	ring.set_thrust_input(0, Vector3.FORWARD, 1, true)
	await wait_physics_frames(3)
	assert_gt(ring.force_seconds[0], emitted)

func test_off_center_force_turns_hull_and_symmetric_pair_cancels_yaw() -> void:
	ring.set_thrust_input(1, Vector3.FORWARD, 1, true)
	await wait_physics_frames(15)
	var single: float = absf(ring.angular_velocity.y)
	assert_gt(single, 0.05)
	ring.respawn_at_checkpoint()
	await wait_physics_frames(3)
	ring.set_thrust_input(1, Vector3.FORWARD, 1, true)
	ring.set_thrust_input(3, Vector3.FORWARD, 1, true)
	await wait_physics_frames(15)
	assert_lt(absf(ring.angular_velocity.y), single * 0.3)
	assert_gt(ring.linear_velocity.length(), 0.2)
	assert_false(ring.axis_lock_linear_y)
	assert_false(ring.axis_lock_angular_x)
	assert_false(ring.axis_lock_angular_z)

func test_open_hole_causes_actual_gravity_drop_and_group_recovery() -> void:
	var hole: Dictionary = path.holes[0]
	var frame: Dictionary = path.sample(hole.s)
	ring.global_transform = Transform3D(Basis.IDENTITY, frame.position + frame.lateral * hole.lateral + Vector3.UP * 0.28)
	ring.route_s = hole.s
	ring.linear_velocity = Vector3.ZERO
	var initial_y: float = ring.position.y
	await wait_physics_frames(65)
	assert_true(ring.falling)
	assert_lt(ring.position.y, initial_y - 3.0, "Physical body drops, not only its visual child")
	assert_false(ring.set_thrust_input(0, Vector3.FORWARD, 1, true))
	ring.respawn_at_checkpoint()
	assert_false(ring.falling)
	assert_eq(ring.global_transform, ring.checkpoint)
	assert_eq(ring.linear_velocity, Vector3.ZERO)
	assert_eq(ring.angular_velocity, Vector3.ZERO)
	assert_eq(ring.visual.riders.size(), 4)
	assert_false(true in ring.held)

func test_current_and_downhill_move_the_body_without_thrust() -> void:
	var current_s: float = path.length * 0.205
	ring.global_transform = path.safe_transform(current_s)
	ring.route_s = current_s
	ring.linear_velocity = Vector3.ZERO
	await wait_physics_frames(60)
	assert_gt(ring.linear_velocity.dot(path.sample(current_s).tangent), 0.2, "Current supplies local forward force")
	var downhill_s: float = path.length * 0.72
	ring.global_transform = path.safe_transform(downhill_s)
	ring.route_s = downhill_s
	ring.linear_velocity = Vector3.ZERO
	ring.angular_velocity = Vector3.ZERO
	var height: float = ring.position.y
	await wait_physics_frames(90)
	assert_gt(ring.linear_velocity.dot(path.sample(downhill_s).tangent), 0.3, "Gravity creates downhill drift")
	assert_lt(ring.position.y, height - 0.1)
	assert_false(true in ring.held)

func test_assistants_use_per_seat_gas_and_release_when_disabled() -> void:
	ring.seat_control[1] = "assist"
	ring.seat_control[2] = "assist"
	ring.seat_control[3] = "assist"
	var brain: CrewBrain = CrewBrain.new()
	brain.ring = ring
	add_child_autofree(brain)
	await wait_physics_frames(20)
	assert_eq(ring.gas[0], 1.0, "Assistant never controls the human seat")
	for seat: int in range(1, 4):
		assert_lt(ring.gas[seat], 1.0)
		assert_gt(ring.force_seconds[seat], 0.0)
	brain.enabled = false
	await wait_physics_frames(2)
	assert_false(true in ring.held)

func test_aim_moves_the_real_force_anchor_without_consuming_gas() -> void:
	assert_true(ring.set_aim_input(0, Vector3.FORWARD))
	var start: Vector3 = ring.orbit.offset(0, SharedRingPreview.SEAT_RADIUS)
	await wait_physics_frames(40)
	assert_gt(start.distance_to(ring.orbit.offset(0, SharedRingPreview.SEAT_RADIUS)), 1.0)
	assert_eq(ring.gas[0], 1.0)
	assert_eq(ring.force_seconds[0], 0.0)
	assert_false(ring.set_aim_input(4, Vector3.FORWARD))
	assert_false(ring.set_aim_input(0, Vector3(INF, 0, 0)))
	ring.enter_fall()
	assert_false(ring.set_aim_input(0, Vector3.FORWARD))
	assert_false(true in ring.aiming)
	ring.respawn_at_checkpoint()
	assert_eq(ring.orbit.angles[0], 0.0)
	assert_false(true in ring.aiming)

func test_waves_move_the_physical_hull_without_thrust() -> void:
	var low: float = INF
	var high: float = -INF
	for frame: int in range(180):
		path.water_time = frame / 60.0
		await wait_physics_frames(1)
		if frame > 60:
			low = minf(low, ring.position.y)
			high = maxf(high, ring.position.y)
	assert_gt(high - low, 0.04, "Physical support responds to the shared waves")
	assert_false(ring.falling)
	assert_eq(ring.force_seconds[0], 0.0)
