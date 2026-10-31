extends GutTest

var builder: LevelBuilder

func before_each() -> void:
	builder = LevelBuilder.new()
	add_child_autofree(builder)
	builder.build(LevelDefs.LEVELS[0])

func test_water_is_confined_to_segments_and_material_is_shared() -> void:
	var segments: Array = LevelDefs.LEVELS[0].segments
	assert_eq(builder.water_segments.size(), segments.size())
	for index: int in range(segments.size()):
		var water: CoursePiece = builder.water_segments[index]
		var mesh: PlaneMesh = water.visual.mesh as PlaneMesh
		assert_almost_eq(mesh.size.x, float(segments[index].width) + 0.02, 0.001)
		assert_almost_eq(mesh.size.y, float(segments[index].length) + 0.02, 0.001)
		assert_eq(water.visual.material_override, builder.water_material)
		assert_eq(water.position.y, 0.0)

func test_cliffs_have_depth_but_collisions_stay_near_water() -> void:
	for bank: CoursePiece in builder.banks:
		var mesh: MeshInstance3D = bank.get_node("Cliff")
		var bounds: AABB = mesh.get_aabb()
		assert_almost_eq(mesh.position.y + bounds.position.y, -40.0, 0.001)
		assert_almost_eq(mesh.position.y + bounds.end.y, 0.9, 0.001)
		assert_eq(mesh.material_override, SkyEnvironment.cliff())
		var collider: CollisionShape3D = bank.get_child(-1) as CollisionShape3D
		assert_almost_eq((collider.shape as BoxShape3D).size.y, 2.9, 0.001)
	assert_eq(builder.decor.clouds.multimesh.instance_count, 128)
	assert_eq(builder.decor.get_node("IslandTops").multimesh.instance_count, 9)

func test_channel_walls_cover_both_sides_and_turn_joints() -> void:
	await get_tree().physics_frame
	var space: PhysicsDirectSpaceState3D = builder.get_world_3d().direct_space_state
	for segment: Dictionary in LevelDefs.LEVELS[0].segments:
		for offset: float in [0.1, 1.5, 12.0, 23.9]:
			var distance: float = segment.d + offset
			var origin: Vector3 = Vector3(segment.x, 0, -distance)
			for side: float in [-1.0, 1.0]:
				var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, origin + Vector3(side * 30, 0, 0), 2)
				assert_false(space.intersect_ray(query).is_empty(), "Open side at d=%s side=%s" % [distance, side])
	# The first and last transverse banks also close the channel.
	for pair: Array in [[Vector3(0, 0, -0.5), Vector3(0, 0, 10)], [Vector3(1, 0, -149), Vector3(1, 0, -160)]]:
		assert_false(space.intersect_ray(PhysicsRayQueryParameters3D.create(pair[0], pair[1], 2)).is_empty())

func test_scenery_rebuild_is_deterministic_and_camera_uses_reference_framing() -> void:
	var cloud: Transform3D = builder.decor.clouds.multimesh.get_instance_transform(0)
	builder.decor.build(LevelDefs.LEVELS[0].segments)
	assert_eq(builder.decor.clouds.multimesh.get_instance_transform(0), cloud)
	var camera: RaceCamera = RaceCamera.new()
	add_child_autofree(camera)
	assert_eq(camera.far, 800.0)
	assert_eq(camera.play_position(Vector3(2, 0, -40)), Vector3(1.7, 14, -28))
	assert_eq(camera.play_look(Vector3(2, 0, -40)), Vector3(1.8, 0, -47))
