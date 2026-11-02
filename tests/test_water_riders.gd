extends GutTest

func test_riders_face_outward_and_orbit_without_overlap() -> void:
	var model: SharedRingPreview = SharedRingPreview.new()
	add_child_autofree(model)
	var profiles: Array[Dictionary] = CrewData.default_profiles()
	profiles[0] = AvatarData.default_avatar()
	var slots: Array[Dictionary] = []
	for seat: int in range(4):
		slots.append(CrewData.make_slot("local", seat))
	model.configure(profiles, slots, 0)
	for anchor: Node3D in model.anchors:
		assert_gt(anchor.basis.z.dot(anchor.position.normalized()), 0.99, "Faces point out from the center")
	model.bake_moving_parts()
	var orbit: RiderOrbit = RiderOrbit.new()
	var aims: Array[Vector3] = [Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD, Vector3.FORWARD]
	var aiming: Array[bool] = [true, true, true, true]
	var occupied: Array[String] = ["local", "local", "local", "local"]
	for frame: int in range(300):
		orbit.advance(aims, aiming, occupied, Basis.IDENTITY, 1.8, 1.0 / 60)
	for a: int in range(4):
		for b: int in range(a + 1, 4):
			assert_gte(absf(angle_difference(orbit.angles[a], orbit.angles[b])), RiderOrbit.MIN_SEPARATION - 0.0001)
	assert_gt(absf(angle_difference(0, orbit.angles[0])), 0.5, "Rider leaves the initial anchor angle")
	var rest: Array[bool] = [false, false, false, false]
	var still: Array[float] = [0.0, 0.0, 0.0, 0.0]
	model.update_riders(orbit, rest, still, 0.1)
	for anchor: Node3D in model.anchors:
		assert_gt(anchor.basis.z.dot(anchor.position.normalized()), 0.99)
	assert_eq(model.riders.size(), 4, "Moving/baking preserves all riders")

func test_charge_color_tracks_actual_thrust_and_cools_on_release() -> void:
	var rider: RiderModel = RiderModel.new()
	add_child_autofree(rider)
	rider.apply(AvatarData.default_avatar())
	for frame: int in range(30):
		rider.animate_activity(1.0 / 60, true, 1.0)
	assert_almost_eq(rider.thrust_heat, 1.0, 0.001)
	assert_gt(rider.charge_material.albedo_color.r, 0.95)
	assert_lt(rider.charge_material.albedo_color.g, 0.3)
	assert_lt(rider.body_root.rotation.x, -0.1)
	for frame: int in range(40):
		rider.animate_activity(1.0 / 60, false, 0.0)
	assert_eq(rider.thrust_heat, 0.0)
	assert_eq(rider.charge_material.albedo_color, AvatarData.OUTFIT_COLORS[rider.appearance.outfit])

func test_wave_profile_matches_height_gradients_and_renderer_parameters() -> void:
	var path: CoursePath = CoursePath.new()
	path.build(LevelDefs.LEVELS[0])
	var style: WaterStyle = path.water_style
	var distance: float = path.length * 0.12
	var frame: Dictionary = path.sample(distance)
	path.water_time = 2.5
	var query: Dictionary = path.surface_at(frame.position, distance)
	var wave: Vector3 = style.displacement(distance, 0, 2.5)
	assert_almost_eq(query.height, frame.position.y + wave.x, 0.002)
	var ds: float = (style.displacement(distance + 0.001, 0, 2.5).x - style.displacement(distance - 0.001, 0, 2.5).x) / 0.002
	var dl: float = (style.displacement(distance, 0.001, 2.5).x - style.displacement(distance, -0.001, 2.5).x) / 0.002
	assert_almost_eq(wave.y, ds, 0.0001)
	assert_almost_eq(wave.z, dl, 0.0001)
	path.water_time = 4.0
	assert_gt(absf(path.surface_at(frame.position, distance).height - query.height), 0.02)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://shaders/route_water.gdshader")
	style.apply_to(material)
	assert_eq(material.get_shader_parameter("wave_a"), style.wave_a)
	assert_eq(material.get_shader_parameter("wave_b"), style.wave_b)
	assert_eq(material.get_shader_parameter("wave_amplitude"), style.wave_amplitude)
	for hole: Dictionary in path.holes:
		var local: Dictionary = path.sample(hole.s)
		assert_false(path.surface_at(local.position + local.lateral * hole.lateral, hole.s).valid, "Waves never add support over a hole")

func test_shared_water_clock_and_wake_pause_and_stop_on_fall() -> void:
	var level: SkyLevel = preload("res://scenes/levels/Level01.tscn").instantiate() as SkyLevel
	add_child_autofree(level)
	level.begin_run()
	level.brain.enabled = false
	level.hud.controls.enabled = false
	await wait_physics_frames(20)
	var clock: float = level.course.path.water_time
	assert_gt(clock, 0.0)
	assert_eq(level.course.water.material_override.get_shader_parameter("water_time"), clock)
	level.toggle_pause()
	await wait_physics_frames(10)
	assert_eq(level.course.path.water_time, clock, "Water animation shares the paused simulation clock")
	level.toggle_pause()
	level.player.enter_fall()
	level.course.update_water(level.race_time, level.player)
	assert_false(level.course.water.material_override.get_shader_parameter("ring_supported"))
	assert_eq(level.course.water.material_override.get_shader_parameter("wake_velocity"), Vector2.ZERO)
