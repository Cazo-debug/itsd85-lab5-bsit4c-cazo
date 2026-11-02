class_name CoursePath
extends RefCounted

var curve: Curve3D = Curve3D.new()
var frames: Array[Dictionary] = []
var length: float = 0.0
var step: float = 1.2
var holes: Array[Dictionary] = []
var width_keys: Array = []
var exposed: Vector2 = Vector2(0.245, 0.315)
var water_style: WaterStyle = WaterStyle.new()
var water_time: float = 0.0

func build(definition: Dictionary) -> void:
	curve.clear_points()
	curve.bake_interval = 0.3
	var points: Array = definition.path
	for index: int in range(points.size()):
		var previous: Vector3 = points[maxi(0, index - 1)]
		var next: Vector3 = points[mini(points.size() - 1, index + 1)]
		var handle: Vector3 = (next - previous) / 6.0
		curve.add_point(points[index], -handle, handle)
	length = curve.get_baked_length()
	width_keys = definition.widths
	water_style = definition.get("water_style", WaterStyle.new())
	holes.clear()
	for hole: Dictionary in definition.holes:
		holes.append({"s": hole.fraction * length, "lateral": hole.lateral, "radius": hole.radius})
	frames.clear()
	var count: int = ceili(length / step)
	step = length / count
	for index: int in range(count + 1):
		var distance: float = index * step
		var at: Vector3 = curve.sample_baked(distance, true)
		var tangent: Vector3 = (curve.sample_baked(minf(length, distance + 0.25), true) - curve.sample_baked(maxf(0, distance - 0.25), true)).normalized()
		var lateral: Vector3 = tangent.cross(Vector3.UP).normalized()
		var normal: Vector3 = lateral.cross(tangent).normalized()
		frames.append({"s": distance, "position": at, "tangent": tangent, "lateral": lateral, "normal": normal, "width": width_at(distance)})

func width_at(distance: float) -> float:
	var fraction: float = distance / maxf(length, 1.0)
	for index: int in range(1, width_keys.size()):
		if fraction <= width_keys[index][0]:
			var weight: float = inverse_lerp(width_keys[index - 1][0], width_keys[index][0], fraction)
			return lerpf(width_keys[index - 1][1], width_keys[index][1], smoothstep(0, 1, weight))
	return width_keys[-1][1]

func sample(distance: float) -> Dictionary:
	var clamped: float = clampf(distance, 0, length)
	var index: int = mini(int(clamped / step), frames.size() - 2)
	var weight: float = (clamped - index * step) / step
	var a: Dictionary = frames[index]
	var b: Dictionary = frames[index + 1]
	var tangent: Vector3 = a.tangent.lerp(b.tangent, weight).normalized()
	var lateral: Vector3 = tangent.cross(Vector3.UP).normalized()
	return {"s": clamped, "position": a.position.lerp(b.position, weight), "tangent": tangent, "lateral": lateral, "normal": lateral.cross(tangent).normalized(), "width": lerpf(a.width, b.width, weight)}

func project(point: Vector3, previous_s: float = -1.0, window: float = 22.0) -> Dictionary:
	var first: int = 0 if previous_s < 0 else maxi(0, int((previous_s - window) / step))
	var last: int = frames.size() - 2 if previous_s < 0 else mini(frames.size() - 2, ceili((previous_s + window) / step))
	var best: float = INF
	var distance: float = clampf(previous_s, 0, length)
	for index: int in range(first, last + 1):
		var a: Vector3 = frames[index].position
		var offset: Vector3 = frames[index + 1].position - a
		var weight: float = clampf((point - a).dot(offset) / offset.length_squared(), 0, 1)
		var squared: float = point.distance_squared_to(a + offset * weight)
		if squared < best:
			best = squared
			distance = (index + weight) * step
	if previous_s >= 0:
		distance = clampf(distance, maxf(0, previous_s - window), minf(length, previous_s + window))
	var result: Dictionary = sample(distance)
	result["offset"] = (point - result.position).dot(result.lateral)
	return result

func surface_at(point: Vector3, previous_s: float) -> Dictionary:
	var result: Dictionary = project(point, previous_s, 9.0)
	var valid: bool = absf(result.offset) <= result.width * 0.5
	for hole: Dictionary in holes:
		if Vector2(result.s - hole.s, result.offset - hole.lateral).length() < hole.radius:
			valid = false
	# The finite start/end does not provide an infinite support plane.
	if (result.s < 0.01 and (point - result.position).dot(result.tangent) < 0) or (result.s > length - 0.01 and (point - result.position).dot(result.tangent) > 0):
		valid = false
	result["valid"] = valid
	var wave: Vector3 = water_style.displacement(result.s, result.offset, water_time)
	result.position += result.lateral * result.offset + Vector3.UP * wave.x
	result.normal = (result.lateral + Vector3.UP * wave.z).cross(result.tangent + Vector3.UP * wave.y).normalized()
	result["height"] = result.position.y
	result["flow"] = result.tangent * (1.3 if result.s / length > 0.18 and result.s / length < 0.23 else 0.0)
	return result

func safe_transform(distance: float) -> Transform3D:
	var at: Dictionary = sample(distance)
	var frame: Dictionary = surface_at(at.position, distance)
	return Transform3D(Basis.looking_at(frame.tangent, frame.normal), frame.position + frame.normal * 0.28)

func exposed_at(distance: float, side: float) -> bool:
	return side > 0 and distance / length > exposed.x and distance / length < exposed.y
