extends GutTest

var level: RaceLevel

func before_each() -> void:
	level = preload("res://scenes/levels/Level01.tscn").instantiate() as RaceLevel
	level.auto_return = false
	add_child_autofree(level)
	level.set_physics_process(false)
	level.player.set_physics_process(false)
	level._physics_process(2.0)
	level._physics_process(3.0)

func test_six_open_shafts_replace_solid_circular_islands() -> void:
	assert_eq(level.definition.islands.size(), 0)
	assert_eq(level.course.holes.size(), 6)
	var cutouts: PackedVector3Array = level.course.water_material.get_shader_parameter("holes")
	assert_eq(cutouts.size(), 8)
	for index: int in range(6):
		var hole: CourseHole = level.course.holes[index]
		assert_eq(cutouts[index], Vector3(hole.position.x, hole.position.z, hole.radius))
		var mesh: CylinderMesh = (hole.get_child(0) as MeshInstance3D).mesh as CylinderMesh
		assert_false(mesh.cap_top)
		assert_false(mesh.cap_bottom)
		assert_eq(hole.find_children("*", "CollisionObject3D", true, false).size(), 0)
	assert_eq(cutouts[6].z, 0.0)
	assert_ne(level.course.water_material, SkyEnvironment.water(), "Preview water must not inherit race holes")

func test_center_falls_edge_is_safe_and_respawn_uses_latest_checkpoint() -> void:
	var hole: CourseHole = level.course.holes[3]
	level._on_checkpoint(level.player, 45.0)
	level.player.position = hole.position + Vector3(hole.radius - 0.19, 0, 0)
	level.check_holes()
	assert_false(level.player.falling, "Center outside radius - 0.2 stays afloat")
	level.player.position = hole.position
	watch_signals(level.player)
	level.check_holes()
	assert_signal_emit_count(level.player, "fell", 1)
	assert_true(level.player.falling)
	assert_false(level.player.toot_toward(Vector3(0, 0, -100)))
	assert_false(level.player.fall_into_hole(), "Repeated checks cannot restart the fall")
	level.player._physics_process(0.45)
	level.player._process(0.0)
	assert_lt(level.player.model.position.y, -2.0)
	assert_lt(level.player.model.scale.x, 1.0)
	level._physics_process(0.45)
	assert_almost_eq(level.race_time, 0.45, 0.001, "Clock continues during the fall")
	level.player._physics_process(0.46)
	assert_false(level.player.falling)
	assert_signal_emit_count(level.player, "respawned", 1)
	assert_eq(level.player.position, Vector3(2, 0, -48))
	assert_eq(level.player.linear_velocity, Vector3.ZERO)
	assert_true(level.player.controls_enabled)
	for other: CourseHole in level.course.holes:
		assert_false(other.contains_center(level.player.position))

func test_timeout_during_fall_cannot_reenable_controls_or_win() -> void:
	var previous: Dictionary = GameState.last_result.duplicate(true)
	level.player.position = level.course.holes[0].position
	level.check_holes()
	level._on_finish_crossed(level.player)
	assert_eq(level.state, RaceLevel.State.RACING)
	level._physics_process(75.0)
	level.player._physics_process(2.0)
	assert_eq(level.state, RaceLevel.State.FINISHED)
	assert_false(GameState.last_result.won)
	assert_false(level.player.controls_enabled)
	assert_true(level.player.freeze)
	GameState.last_result = previous
