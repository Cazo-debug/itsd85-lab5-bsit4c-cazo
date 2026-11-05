class_name CrewBrain
extends Node

var ring: SwimRing
var all_seats: bool = false
var enabled: bool = true
var clock: float = 0.0
var speed: float = 7.2
var control_seat: int = -1
var resting: Array[bool] = [false, false, false, false]

func _physics_process(delta: float) -> void:
	clock += delta
	if ring == null:
		return
	for index: int in range(4):
		if control_seat >= 0 and index != control_seat:
			continue
		if ring.seat_control[index] == "empty" or (not all_seats and ring.seat_control[index] != "assist"):
			continue
		if not enabled or not ring.simulate or ring.falling:
			ring.set_thrust_input(index, Vector3.ZERO, 0, false)
			continue
		var target: Dictionary = ring.path.sample(ring.route_s + 5.5)
		var offset: Vector3 = target.position - ring.position
		var desired: Vector3 = offset.normalized() * speed
		var correction: Vector3 = desired - ring.linear_velocity
		if ring.gas[index] < 0.15 or ring.depleted[index]:
			resting[index] = true
		if ring.gas[index] >= 0.65:
			resting[index] = false
		var should_fire: bool = not resting[index]
		var pulse: bool = fmod(clock + index * 0.11, 2.0) < 1.65
		ring.set_thrust_input(index, correction, clampf(correction.length() / 7.0, 0, 1), should_fire and pulse)
