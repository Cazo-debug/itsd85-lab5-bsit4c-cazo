extends GutTest

var world: Node3D
var player: FloatPlayer

func before_each() -> void:
	world = Node3D.new()
	add_child_autofree(world)
	player = preload("res://scenes/actors/FloatPlayer.tscn").instantiate() as FloatPlayer
	world.add_child(player)
	player.set_physics_process(false)

func test_impulse_spends_gas_and_empty_meter_refuses_input() -> void:
	assert_eq(player.gas, 3)
	assert_true(player.toot_toward(Vector3(10, 8, 0)))
	assert_eq(player.gas, 2)
	assert_true(player.toot_toward(Vector3(10, 0, 0)))
	assert_true(player.toot_toward(Vector3(10, 0, 0)))
	assert_eq(player.gas, 0)
	assert_false(player.toot_toward(Vector3(10, 0, 0)))
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_gt(player.linear_velocity.x, 0.0)
	assert_almost_eq(player.position.y, 0.0, 0.01)
	assert_lte(player.linear_velocity.length(), FloatPlayer.MAX_SPEED + 0.01)

func test_refill_timing_and_capacity() -> void:
	player.gas = 0
	player.advance_gas(1.49)
	assert_eq(player.gas, 0)
	player.advance_gas(0.02)
	assert_eq(player.gas, 1)
	player.advance_gas(1.5)
	assert_eq(player.gas, 2)
	player.advance_gas(20.0)
	assert_eq(player.gas, 3)
	player.add_gas(99)
	assert_eq(player.gas, 3)
	player.toot_toward(Vector3(10, 0, 0))
	player.advance_gas(0.2)
	assert_eq(player.gas, 2, "Time spent at full gas cannot be banked")

func test_nearby_invalid_and_countdown_taps_do_nothing() -> void:
	assert_false(player.toot_toward(Vector3(0.1, 0, 0)))
	assert_false(player.toot_toward(Vector3(INF, 0, 0)))
	player.controls_enabled = false
	assert_false(player.toot_toward(Vector3(10, 0, 0)))
	player.controls_enabled = true
	player.freeze = true
	assert_false(player.toot_toward(Vector3(10, 0, 0)))
	assert_eq(player.gas, 3)

func test_solver_caps_external_velocity() -> void:
	player.linear_velocity = Vector3(70, 0, -70)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_lte(player.linear_velocity.length(), FloatPlayer.MAX_SPEED + 0.01)

func test_banks_block_and_bounce_the_float() -> void:
	var bank: CoursePiece = preload("res://scenes/course/Bank.tscn").instantiate() as CoursePiece
	bank.position.x = 3.0
	bank.dimensions = Vector3(1, 1.2, 10)
	world.add_child(bank)
	player.toot_toward(Vector3(10, 0, 0))
	var bounced: bool = false
	for frame: int in range(45):
		await get_tree().physics_frame
		if player.linear_velocity.x < -0.1:
			bounced = true
	assert_lt(player.position.x, 2.5)
	assert_true(bounced, "A real solver contact should reflect X velocity")
