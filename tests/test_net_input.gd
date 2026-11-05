extends GutTest

var gate: NetInputGate
var owners: Array[int] = [1, 22, 33, 44]
var gas: Array[float] = [1.0, 1.0, 1.0, 1.0]

func before_each() -> void:
	gate = NetInputGate.new()
	gas.assign([1.0, 1.0, 1.0, 1.0])

func packet(sequence: int = 1) -> Dictionary:
	return {"seat": 1, "round": 7, "seq": sequence, "direction": Vector3(2, 0, -2), "strength": 0.8, "held": true}

func test_ownership_round_sequence_and_payload_types_are_checked() -> void:
	assert_true(gate.accept(33, packet(), owners, 7, 1000, gas, true).is_empty())
	assert_true(gate.accept(22, packet(), owners, 8, 1000, gas, true).is_empty())
	var clean: Dictionary = gate.accept(22, packet(), owners, 7, 1000, gas, true)
	assert_eq(clean.seat, 1)
	assert_almost_eq(clean.direction.length(), 1.0, 0.0001)
	assert_true(gate.accept(22, packet(), owners, 7, 1001, gas, true).is_empty())
	assert_true(gate.accept(22, packet(0), owners, 7, 1001, gas, true).is_empty())
	for key: String in ["seat", "round", "seq", "held", "direction", "strength"]:
		var bad: Dictionary = packet(2)
		bad[key] = "bad"
		assert_true(gate.accept(22, bad, owners, 7, 1001, gas, true).is_empty(), key)
	assert_false(gate.accept(22, packet(2), owners, 7, 1002, gas, true).is_empty())

func test_nonfinite_values_bounds_gas_and_run_state_cannot_add_force() -> void:
	for direction: Vector3 in [Vector3(NAN, 0, 0), Vector3(INF, 0, 0), Vector3.ZERO, Vector3(101, 0, 0)]:
		var bad: Dictionary = packet()
		bad.direction = direction
		assert_true(gate.accept(22, bad, owners, 7, 1000, gas, true).is_empty())
	for strength: float in [-0.1, 1.1, NAN, INF]:
		var bad: Dictionary = packet()
		bad.strength = strength
		assert_true(gate.accept(22, bad, owners, 7, 1000, gas, true).is_empty())
	for seat: int in [-1, 4]:
		var bad: Dictionary = packet()
		bad.seat = seat
		assert_true(gate.accept(22, bad, owners, 7, 1000, gas, true).is_empty())
	assert_true(gate.accept(22, packet(), owners, 7, 1000, gas, false).is_empty())
	gas[1] = 0
	assert_true(gate.accept(22, packet(), owners, 7, 1000, gas, true).is_empty())
	var release: Dictionary = packet()
	release.held = false
	release.direction = Vector3.ZERO
	assert_false(gate.accept(22, release, owners, 7, 1001, gas, false).is_empty())

func test_rate_limit_does_not_block_fresh_release_and_stale_thrust_expires() -> void:
	for sequence: int in range(1, NetInputGate.MAX_RATE + 1):
		assert_false(gate.accept(22, packet(sequence), owners, 7, 1000, gas, true).is_empty())
	assert_true(gate.accept(22, packet(91), owners, 7, 1001, gas, true).is_empty())
	var release: Dictionary = packet(92)
	release.held = false
	assert_false(gate.accept(22, release, owners, 7, 1001, gas, true).is_empty())
	assert_false(gate.expired(1, 1351))
	assert_true(gate.expired(1, 1352))
	assert_true(gate.expired(2, 0))
	assert_false(gate.accept(22, packet(93), owners, 7, 2001, gas, true).is_empty())
	gate.reset()
	assert_true(gate.expired(1, 2002))
	var new_round: Dictionary = packet(1)
	new_round.round = 8
	assert_false(gate.accept(22, new_round, owners, 8, 2002, gas, true).is_empty())
