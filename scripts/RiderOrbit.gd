class_name RiderOrbit
extends RefCounted

const MIN_SEPARATION: float = 0.76
var angles: Array[float] = [0.0, PI * 0.5, PI, PI * 1.5]

func reset() -> void:
	angles.assign([0.0, PI * 0.5, PI, PI * 1.5])

func offset(seat: int, radius: float, height: float = 0.0) -> Vector3:
	return Vector3(sin(angles[seat]) * radius, height, cos(angles[seat]) * radius)

func advance(aims: Array[Vector3], aiming: Array[bool], occupied: Array[String], basis: Basis, speed: float, delta: float) -> void:
	for seat: int in range(4):
		if occupied[seat] == "empty" or not aiming[seat]:
			continue
		var local: Vector3 = basis.inverse() * aims[seat]
		if local.slide(Vector3.UP).length_squared() < 0.001:
			continue
		var target: float = atan2(local.x, local.z)
		var motion: float = clampf(angle_difference(angles[seat], target), -speed * delta, speed * delta)
		var next: float = wrapf(angles[seat] + motion, -PI, PI)
		var clear: bool = true
		for other: int in range(4):
			if other != seat and occupied[other] != "empty" and absf(angle_difference(next, angles[other])) < MIN_SEPARATION:
				clear = false
		if clear:
			angles[seat] = next
