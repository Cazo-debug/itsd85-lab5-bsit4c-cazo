extends GutTest

var level: SkyLevel
var snapshot: Dictionary
const PATH: String = "user://phase2_v3_run_test.cfg"

func before_each() -> void:
	snapshot = {"path": GameState.persistence_path, "result": GameState.last_result.duplicate(true)}
	GameState.persistence_path = PATH
	level = preload("res://scenes/levels/Level01.tscn").instantiate() as SkyLevel
	add_child_autofree(level)
	level.brain.enabled = false
	level.hud.controls.enabled = false

func after_each() -> void:
	GameState.persistence_path = snapshot.path
	GameState.last_result = snapshot.result
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(PATH + suffix)

func test_touch_ownership_release_drag_and_focus_clear_held_state() -> void:
	level.begin_run()
	var input: CrewInput = level.hud.controls
	input.set_anchors_preset(Control.PRESET_TOP_LEFT)
	input.size = Vector2(720, 1280)
	input.handle_touch(3, input.stick_rect().get_center() + Vector2(0, -65), true)
	input.handle_touch(7, input.gas_rect().get_center(), true)
	assert_eq(input.stick_id, 3)
	assert_eq(input.gas_id, 7)
	input._physics_process(1.0 / 60)
	assert_true(level.player.held[input.active_seat])
	input.handle_drag(3, input.stick_rect().get_center())
	input._physics_process(1.0 / 60)
	assert_false(level.player.held[input.active_seat], "Centering the aim pad releases the previous thrust")
	input.handle_drag(3, input.stick_rect().get_center() + Vector2(0, -65))
	input._physics_process(1.0 / 60)
	assert_true(level.player.held[input.active_seat])
	input.handle_touch(99, Vector2(20, 80), false)
	assert_eq(input.gas_id, 7, "Unrelated touch cannot release the held finger")
	input.handle_drag(7, Vector2(1, 1))
	assert_eq(input.gas_id, -1)
	assert_false(level.player.held[input.active_seat])
	input.handle_touch(8, input.gas_rect().get_center(), true)
	input._physics_process(1.0 / 60)
	input._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_eq(input.gas_id, -1)
	assert_eq(input.stick_id, -1)
	assert_false(true in level.player.held)
	input.handle_touch(10, Vector2(600, 100), true)
	assert_eq(input.gas_id, -1, "HUD touches do not thrust")

func test_pause_timeout_and_fall_do_not_resume_stale_input() -> void:
	level.begin_run()
	level.player.set_thrust_input(0, Vector3.FORWARD, 1, true)
	level.toggle_pause()
	assert_eq(level.state, SkyLevel.State.PAUSED)
	assert_false(true in level.player.held)
	var clock: float = level.race_time
	level._physics_process(4)
	assert_eq(level.race_time, clock)
	level.toggle_pause()
	assert_true(level.player.simulate)
	assert_false(true in level.player.held)
	level.player.enter_fall()
	level.race_time = level.time_limit - 0.01
	level._physics_process(0.02)
	assert_eq(level.state, SkyLevel.State.FINISHED)
	assert_false(level.player.simulate)
	var recoveries: int = level.player.recoveries
	level.player.respawn_at_checkpoint()
	level._physics_process(5)
	assert_eq(level.player.recoveries, recoveries, "Timeout cancels pending recovery")
	assert_false(GameState.last_result.has("place"))

func test_ordered_finish_cannot_skip_checkpoints_and_practice_does_not_save() -> void:
	level.begin_run()
	level.player.route_s = level.course.finish_s + 3
	level.player.position = level.course.path.sample(level.player.route_s).position + Vector3.UP * 0.28
	level.previous_s = level.course.finish_s - 1
	level.check_progress()
	assert_eq(level.state, SkyLevel.State.RACING, "Skipping checkpoints cannot finish")
	level.practice = true
	level.end_run(true)
	assert_false(FileAccess.file_exists(PATH), "Practice never advances the campaign")

func test_live_mallet_contact_tips_the_physical_ring() -> void:
	level.begin_run()
	level.hud.controls.enabled = false
	var mallet: CourseHazard
	for hazard: CourseHazard in level.course.hazards:
		if hazard.kind == "mallet":
			mallet = hazard
	# A controlled collision fixture, separate from the no-teleport solvability run.
	var frame: Dictionary = level.course.path.sample(mallet.route_s)
	level.player.global_transform = Transform3D(Basis.IDENTITY, frame.position + frame.lateral * -3.2 + Vector3.UP * 0.28)
	level.player.route_s = mallet.route_s
	level.previous_s = mallet.route_s
	level.player.linear_velocity = Vector3.ZERO
	await wait_physics_frames(100)
	assert_gt(level.player.contact_count, 0, "Mallet collision body reaches the hull")
	assert_gt(level.player.peak_tilt, 0.1, "Collision changes physical orientation")
	assert_true(level.player.position.is_finite())
