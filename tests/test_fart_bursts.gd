extends GutTest

var ring: SwimRing

func before_each() -> void:
	var path: CoursePath = CoursePath.new()
	path.build(LevelDefs.LEVELS[0])
	var profiles: Array[Dictionary] = CrewData.default_profiles()
	for index: int in range(profiles.size()):
		profiles[index] = AvatarData.sanitize(profiles[index])
	var slots: Array[Dictionary] = []
	for index: int in range(4):
		slots.append(CrewData.make_slot("local", index))
	ring = SwimRing.new()
	ring.setup(path, profiles, slots, 0)
	add_child_autofree(ring)
	ring.simulate = true
	ring.freeze = false
	await wait_physics_frames(4)

func test_only_the_holding_rider_bursts_and_spends_gas() -> void:
	assert_true(ring.set_thrust_input(1, Vector3.FORWARD, 1, true))
	await wait_physics_frames(50)
	assert_gt(ring.bursts_fired[1], 1, "Holding repeats bursts at the configured rate")
	for seat: int in [0, 2, 3]:
		assert_eq(ring.bursts_fired[seat], 0, "Idle riders never fart")
		assert_eq(ring.gas[seat], 1.0, "Idle riders keep their own gas")
	assert_lt(ring.gas[1], 1.0)
	ring.set_thrust_input(1, Vector3.ZERO, 0, false)
	await wait_physics_frames(3)
	var fired: int = ring.bursts_fired[1]
	await wait_physics_frames(40)
	assert_eq(ring.bursts_fired[1], fired, "Release stops new bursts")

func test_puffs_are_soft_billboards_with_a_hard_cap() -> void:
	var config: FartConfig = FartConfig.current
	assert_lte(config.emitters_per_rider() * config.puffs_per_burst, config.max_live_puffs_per_rider)
	assert_lt(config.puffs_per_burst_low, config.puffs_per_burst)
	for pool: Array in ring.burst_pools:
		assert_eq(pool.size(), config.emitters_per_rider())
		for burst: CPUParticles3D in pool:
			assert_true(burst.mesh is QuadMesh, "Billboard quads, not solid spheres")
			var material: StandardMaterial3D = (burst.mesh as QuadMesh).material
			assert_eq(material.billboard_mode, BaseMaterial3D.BILLBOARD_PARTICLES)
			assert_eq(material.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA)
			assert_true(burst.one_shot, "Bursts, not a stream")
			assert_almost_eq(burst.color_ramp.sample(1.0).a, 0.0, 0.001, "Puffs fade to zero alpha")

func test_burst_points_away_from_the_float_and_squashes_its_rider() -> void:
	ring.emit_burst(0, ring.global_transform)
	var fired: CPUParticles3D = null
	for burst: CPUParticles3D in ring.burst_pools[0]:
		if burst.emitting:
			fired = burst
	assert_not_null(fired)
	var outward: Vector3 = (fired.global_position - ring.global_position).slide(Vector3.UP)
	assert_gt(outward.length(), SharedRingPreview.SEAT_RADIUS, "Emitter sits at the rider's rear, outside the seat")
	assert_gt(fired.direction.slide(Vector3.UP).normalized().dot(outward.normalized()), 0.9, "Puffs leave away from the float centre")
	var rider: RiderModel = ring.visual.riders[0]
	assert_lt(rider.burst_clock, 0.1, "The burst reaches its rider")
	rider.burst()
	rider.animate_activity(1.0 / 60, false, 0.0)
	assert_lt(rider.pose_root.scale.y, 0.9, "Quick crouch at the start of a burst")
	var tallest: float = 0.0
	for frame: int in range(30):
		rider.animate_activity(1.0 / 60, false, 0.0)
		tallest = maxf(tallest, rider.pose_root.scale.y)
	assert_gt(tallest, 1.02, "Then a springy lift/stretch")

func test_full_pool_skips_bursts_instead_of_spawning_more() -> void:
	for attempt: int in range(ring.burst_pools[0].size() + 3):
		ring.emit_burst(0, ring.global_transform)
	assert_eq(ring.bursts_fired[0], ring.burst_pools[0].size())

func test_riders_are_sculpted_and_baked_into_few_toon_meshes() -> void:
	for rider: RiderModel in ring.visual.riders:
		assert_true(rider.baked)
		var visible_meshes: int = 0
		for node: Node in rider.find_children("*", "MeshInstance3D", true, false):
			if (node as MeshInstance3D).is_visible_in_tree():
				visible_meshes += 1
		assert_lte(visible_meshes, 4, "Body, head, face and butt only")
