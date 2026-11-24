extends GutTest

# Graphics and game-feel pass: sculpted riders, secondary motion, float feel, fart,
# water, quality fallback and frame budget. Everything here is presentation only.
const PATH: String = "user://visual_feel_test.cfg"
const QUIET: Array[bool] = [false, false, false, false]
const STILL: Array[float] = [0.0, 0.0, 0.0, 0.0]
var saved: Dictionary

func before_each() -> void:
	saved = {}
	for key: String in ["settings", "persistence_path", "local_profiles", "crew_slots", "leader_profile", "mode", "last_save_error", "last_result", "unlocked_level", "best_stars", "best_times"]:
		var value: Variant = GameState.get(key)
		saved[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	GameState.persistence_path = PATH
	GameState.settings = GameState.DEFAULT_SETTINGS.duplicate()
	GameState.local_profiles = CrewData.default_profiles()
	GameState.set_profile(0, AvatarData.default_avatar())
	GameState.crew_slots = []
	for seat: int in range(4):
		GameState.crew_slots.append(CrewData.make_slot("local", seat))
	GameState.mode = "offline"

func after_each() -> void:
	for key: String in saved:
		GameState.set(key, saved[key])
	Audio.stop_all()
	get_viewport().scaling_3d_scale = 1.0
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(PATH + suffix)

func rider() -> RiderModel:
	var model: RiderModel = RiderModel.new()
	add_child_autofree(model)
	model.apply(AvatarData.default_avatar())
	model.setup_motion(0)
	model.bake()
	return model

func ring() -> SwimRing:
	var path: CoursePath = CoursePath.new()
	path.build(LevelDefs.LEVELS[0])
	var slots: Array[Dictionary] = []
	for seat: int in range(4):
		slots.append(CrewData.make_slot("local", seat))
	var float_ring: SwimRing = SwimRing.new()
	float_ring.setup(path, CrewData.default_profiles(), slots, 0)
	add_child_autofree(float_ring)
	return float_ring

func test_butt_is_sculpted_into_the_body_in_the_animal_colour() -> void:
	var model: RiderModel = rider()
	assert_eq(Color(model.cheek_color, 1.0), Color("7b69b9"), "Same colour as the hippo's body, no pink blush")
	assert_eq(model.cheek_color.a, 0.0, "No glow at rest")
	assert_null(model.find_child("Butt", true, false), "No separate butt parts")
	var visible: int = 0
	var body: MeshInstance3D = null
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		if mesh.is_visible_in_tree():
			visible += 1
		if mesh.material_override == model.body_material:
			body = mesh
	assert_lte(visible, 3, "Body, head and one face")
	assert_not_null(body, "The baked body uses the rider's own toon material")
	var arrays: Array = body.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var masks: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var rear: int = 0
	var front: int = 0
	for index: int in range(vertices.size()):
		if masks[index].x > 0.3:
			if vertices[index].z < 0.0 and vertices[index].y < 0.8:
				rear += 1
			else:
				front += 1
	assert_gt(rear, 20, "Butt mask covers the lower rear")
	assert_eq(front, 0, "...and nothing else")

func test_moods_drive_cheer_panic_and_flail_poses() -> void:
	var model: RiderModel = rider()
	model.set_mood("cheer")
	for frame: int in range(40):
		model.animate_activity(1.0 / 60, false, 0.0)
	assert_true(model.happy_root.visible, "Happy eyes")
	assert_false(model.eyes_root.visible)
	assert_gt(model.arms.x, 1.5, "Left arm up")
	assert_gt(model.arms.z, 1.5, "Right arm up")
	assert_eq(model.body_material.get_shader_parameter("arm_left"), Vector2(model.arms.x, model.arms.y), "The shader moves the arms")
	model.set_mood("panic")
	for frame: int in range(20):
		model.animate_activity(1.0 / 60, false, 0.0)
	assert_true(model.eyes_root.visible)
	assert_gt(model.eyes_root.scale.x, 1.2, "Wide eyes while falling")
	model.set_mood("ride")
	model.flail(1.0)
	var peak: float = 0.0
	for frame: int in range(30):
		model.animate_activity(1.0 / 60, false, 0.0)
		peak = maxf(peak, model.arms.x)
	assert_gt(peak, 0.6, "Arms flail when hit")
	for frame: int in range(150):
		model.animate_activity(1.0 / 60, false, 0.0)
	assert_lt(absf(model.arms.x), 0.1, "Hands settle back on the handles")

func test_riders_lean_toward_the_reported_motion() -> void:
	var model: RiderModel = rider()
	model.set_float_motion(Vector2(6.0, 0.0))
	for frame: int in range(60):
		model.animate_activity(1.0 / 60, false, 0.0)
	assert_gt(model.pose_root.rotation.x, 0.15, "Leans forward")
	model.set_float_motion(Vector2(0.0, 6.0))
	for frame: int in range(90):
		model.animate_activity(1.0 / 60, false, 0.0)
	assert_lt(model.pose_root.rotation.z, -0.15, "Leans to its right")

func test_float_feel_is_visual_only_and_settles() -> void:
	var float_ring: SwimRing = ring()
	var body: Transform3D = float_ring.global_transform
	float_ring.visual.impact(Vector3.RIGHT, 1.0)
	float_ring.visual.burst(0, Vector3.BACK)
	float_ring.visual.land(1.0)
	var moved: bool = false
	for frame: int in range(10):
		float_ring.visual.animate_riders(QUIET, STILL, 1.0 / 60)
		moved = moved or not float_ring.visual.ring.transform.is_equal_approx(Transform3D.IDENTITY)
	assert_true(moved, "Kick, squash and bounce show on the float")
	assert_eq(float_ring.global_transform, body, "Never moves the physics body")
	for model: RiderModel in float_ring.visual.riders:
		assert_lt(model.flail_clock, 1.0, "Every rider reacts to the hit")
	for frame: int in range(300):
		float_ring.visual.animate_riders(QUIET, STILL, 1.0 / 60)
	assert_lt(absf(float_ring.visual.squash), 0.01)
	assert_lt(float_ring.visual.surge.length(), 0.01)

func test_rider_weight_tips_the_float_toward_where_riders_sit() -> void:
	var model: SharedRingPreview = SharedRingPreview.new()
	model.driven = true
	add_child_autofree(model)
	var profiles: Array[Dictionary] = CrewData.default_profiles()
	profiles[0] = AvatarData.default_avatar()
	var slots: Array[Dictionary] = [CrewData.make_slot("local", 0), CrewData.empty_slot(), CrewData.empty_slot(), CrewData.empty_slot()]
	model.configure(profiles, slots, 0)
	for frame: int in range(180):
		model.animate_riders(QUIET, STILL, 1.0 / 60)
	var seat: Vector3 = model.seat_bases[0].origin
	assert_lt((model.ring.transform * seat).y, -0.1, "The lone rider's side dips")
	assert_gt((model.ring.transform * -seat).y, 0.1, "The empty side lifts")

func test_burst_cloud_is_blown_back_and_splashes_alternate() -> void:
	var float_ring: SwimRing = ring()
	float_ring.linear_velocity = Vector3(0, 0, -6)
	float_ring.splash_height_valid = true
	float_ring.splash_height = float_ring.global_position.y - 0.3
	float_ring.emit_burst(0, float_ring.global_transform)
	var fired: CPUParticles3D = null
	for burst: CPUParticles3D in float_ring.burst_pools[0]:
		if burst.emitting:
			fired = burst
	assert_gt(fired.gravity.z, 1.0, "Puffs stream back against the float's motion")
	assert_true(float_ring.splashes[0].emitting, "Foam ring where the cloud meets the water")
	assert_true(float_ring.droplet_pools[0][0].emitting, "Droplets on High")
	float_ring.emit_burst(0, float_ring.global_transform)
	assert_true(float_ring.splashes[1].emitting, "The next burst uses the other ring, so neither is cut short")
	float_ring.set_effects_quality(true)
	float_ring.emit_burst(1, float_ring.global_transform)
	assert_false(float_ring.droplet_pools[1][0].emitting or float_ring.droplet_pools[1][1].emitting, "Low quality skips droplets")

func test_water_is_unshaded_chunked_and_shares_one_material() -> void:
	var course: CurvedCourse = CurvedCourse.new()
	add_child_autofree(course)
	course.build(LevelDefs.LEVELS[0])
	assert_gt(course.water_chunks.size(), 4, "Route water is split for culling and front-to-back drawing")
	assert_eq(course.water, course.water_chunks[0])
	for chunk: MeshInstance3D in course.water_chunks:
		assert_eq(chunk.material_override, course.water.material_override)
	var material: ShaderMaterial = course.water.material_override
	assert_true(material.shader.code.contains("unshaded"), "Lit water cost ~21 ms per frame on the test phone")
	var pattern: ImageTexture = RaceEffects.water_pattern()
	assert_eq(material.get_shader_parameter("pattern"), pattern)
	assert_eq(pattern, RaceEffects.water_pattern(), "Generated once")
	assert_eq(pattern.get_width(), RaceEffects.PATTERN_SIZE)
	assert_true(pattern.get_image().has_mipmaps())
	var holder: Node3D = Node3D.new()
	add_child_autofree(holder)
	SkyEnvironment.install(holder)
	var world: WorldEnvironment = holder.get_node("SkyEnvironment")
	assert_false(world.environment.fog_enabled, "Engine fog cost ~14 ms per frame on the test phone")

func test_obstacle_foam_follows_only_shared_race_time() -> void:
	var course: CurvedCourse = CurvedCourse.new()
	add_child_autofree(course)
	course.build(LevelDefs.LEVELS[4])
	var lifted: int = 0
	for hazard: CourseHazard in course.hazards:
		hazard.update_time(3.0)
		var first: Vector3 = hazard.water_foam()
		hazard.update_time(7.5)
		hazard.update_time(3.0)
		assert_eq(hazard.water_foam(), first, "Same time, same foam")
		if hazard.kind == "crusher":
			for step: int in range(60):
				hazard.update_time(step * 0.1)
				if hazard.moving.position.y > 1.6:
					assert_lte(hazard.water_foam().z, 0.0, "No foam under a lifted crusher")
					lifted += 1
	assert_gt(lifted, 0)

func test_shared_finish_makes_the_crew_cheer_and_a_fall_makes_it_panic() -> void:
	var level: SkyLevel = SkyLevel.new()
	add_child_autofree(level)
	level.begin_run()
	level.player.falling = true
	level.player._process(1.0 / 60)
	for model: RiderModel in level.player.visual.riders:
		assert_eq(model.mood, "panic")
	level.player.falling = false
	level.feedback._process(1.0 / 60)
	level.end_run(true)
	level.feedback._process(1.0 / 60)
	assert_true(level.player.celebrating)
	assert_true(level.camera.celebrating, "The camera frames the cheering crew above the result card")
	level.player._process(1.0 / 60)
	for model: RiderModel in level.player.visual.riders:
		assert_eq(model.mood, "cheer")

func test_low_quality_trims_heavy_effects_and_high_restores_them() -> void:
	var level: SkyLevel = SkyLevel.new()
	add_child_autofree(level)
	var water: ShaderMaterial = level.course.water.material_override
	SettingsFlow.apply_quality(level, true)
	assert_eq(water.get_shader_parameter("detail"), 0.0, "One water texture layer")
	assert_false(level.course.decor.cloud_cards.visible)
	assert_true(level.player.low_effects, "No droplet bursts")
	assert_almost_eq(level.get_viewport().scaling_3d_scale, SettingsFlow.LOW_3D_SCALE, 0.001)
	assert_eq(level.player.visual.riders.size(), 4)
	SettingsFlow.apply_quality(level, false)
	assert_eq(water.get_shader_parameter("detail"), 1.0)
	assert_true(level.course.decor.cloud_cards.visible)
	assert_false(level.player.low_effects)
	assert_almost_eq(level.get_viewport().scaling_3d_scale, 1.0, 0.001)

func test_frame_budget_steps_the_3d_view_down_then_back_up() -> void:
	var level: SkyLevel = SkyLevel.new()
	add_child_autofree(level)
	var feedback: RunFeedback = level.feedback
	feedback.quality = "high"
	for frame: int in range(400):
		feedback.keep_frame_budget(0.030)
	assert_almost_eq(feedback.render_scale, RunFeedback.MIN_SCALE, 0.001, "Slow frames shrink the 3D view, not below the floor")
	assert_almost_eq(level.get_viewport().scaling_3d_scale, RunFeedback.MIN_SCALE, 0.001)
	for frame: int in range(1000):
		feedback.keep_frame_budget(0.016)
	assert_gt(feedback.render_scale, RunFeedback.MIN_SCALE, "Headroom brings resolution back")
