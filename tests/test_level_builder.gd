extends GutTest

var builder: LevelBuilder

func before_each() -> void:
	builder = LevelBuilder.new()
	add_child_autofree(builder)
	builder.build(LevelDefs.LEVELS[0])

func test_tutorial_course_has_all_required_parts() -> void:
	var definition: Dictionary = LevelDefs.LEVELS[0]
	assert_not_null(builder.start)
	assert_eq(builder.start.position, LevelDefs.world_point(definition.start))
	assert_true(builder.finish is CoursePiece)
	assert_eq(builder.finish.position.z, -float(definition.finish_d))
	assert_eq(builder.checkpoints.size(), 2)
	assert_eq(builder.banks.size(), definition.segments.size() * 2)
	assert_eq(builder.beans.size(), definition.beans.size())
	assert_gte(builder.beans.size(), 6)
	for bank: CoursePiece in builder.banks:
		assert_eq(bank.get("collision_layer"), 2)
		assert_gt(bank.get_child_count(), 2)
	assert_eq(builder.center_at(30.0), 2.0)
	assert_eq(builder.center_at(80.0), -2.0)
	assert_eq(builder.width_at(80.0), 14.0)

func test_bean_collects_once_then_respawns() -> void:
	var player: FloatPlayer = preload("res://scenes/actors/FloatPlayer.tscn").instantiate() as FloatPlayer
	add_child_autofree(player)
	player.set_physics_process(false)
	player.gas = 1
	var bean: CoursePiece = builder.beans[0]
	bean.set_physics_process(false)
	bean._on_body_entered(player)
	assert_eq(player.gas, 2)
	assert_false(bean.visible)
	bean._on_body_entered(player)
	assert_eq(player.gas, 2)
	bean._physics_process(7.9)
	assert_false(bean.visible)
	bean._physics_process(0.2)
	assert_true(bean.visible)
	bean._on_body_entered(player)
	assert_eq(player.gas, 3)
	await get_tree().process_frame

func test_countdown_timeout_checkpoint_and_finish_rules() -> void:
	var level: RaceLevel = preload("res://scenes/levels/Level01.tscn").instantiate() as RaceLevel
	level.auto_return = false
	add_child(level)
	level.set_physics_process(false)
	assert_eq(level.state, RaceLevel.State.INTRO)
	assert_false(level.player.toot_toward(Vector3(0, 0, -20)))
	level._physics_process(2.0)
	assert_eq(level.state, RaceLevel.State.COUNTDOWN)
	assert_eq(level.race_time, 0.0)
	assert_false(level.camera.overview)
	assert_false(level.player.toot_toward(Vector3(0, 0, -20)))
	level._physics_process(2.99)
	assert_eq(level.race_time, 0.0)
	assert_eq(level.state, RaceLevel.State.COUNTDOWN)
	level._physics_process(0.02)
	assert_eq(level.state, RaceLevel.State.RACING)
	assert_true(level.tap_input.enabled)
	level._on_checkpoint(level.player, 45.0)
	assert_eq(level.player.checkpoint.z, -45.0)
	level._on_checkpoint(level.player, 10.0)
	assert_eq(level.player.checkpoint.z, -45.0)
	var previous_result: Dictionary = GameState.last_result.duplicate(true)
	level._physics_process(75.0)
	assert_eq(level.state, RaceLevel.State.FINISHED)
	assert_eq(GameState.last_result.stars, 0)
	assert_false(GameState.last_result.won)
	assert_false(level.tap_input.enabled)
	level._on_finish_crossed(level.player)
	assert_false(GameState.last_result.won, "Finish after timeout must not win")
	GameState.last_result = previous_result
	level.queue_free()
	await get_tree().process_frame
