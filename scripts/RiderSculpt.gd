class_name RiderSculpt
extends RefCounted

# Sculpted low-poly shapes for the riders: lathed bodies and tapered limbs with smooth normals.

## Revolve a (radius, height) profile around +Y. `side` scales X; `front`/`back` scale the +Z/-Z halves.
static func lathe(profile: PackedVector2Array, segments: int = 16, side: float = 1.0, front: float = 1.0, back: float = 1.0) -> ArrayMesh:
	var builder: SurfaceTool = SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.set_smooth_group(0)
	for row: int in range(profile.size()):
		for column: int in range(segments):
			var angle: float = TAU * column / segments
			var depth: float = cos(angle) * profile[row].x
			builder.add_vertex(Vector3(sin(angle) * profile[row].x * side, profile[row].y, depth * (front if depth > 0.0 else back)))
	for row: int in range(profile.size() - 1):
		for column: int in range(segments):
			var a: int = row * segments + column
			var b: int = row * segments + (column + 1) % segments
			var c: int = a + segments
			var d: int = b + segments
			# Clockwise when seen from outside (Godot's front face).
			for index: int in [a, c, b, b, c, d]:
				builder.add_index(index)
	builder.generate_normals()
	return builder.commit()

## Seated pear-shaped body: one smooth mesh (no separate butt parts). The lower rear swells
## into two cheeks with a soft crease, in the body's own colour. Rows below the waist use
## `seat`; rows above blend into `lean` (the rider's Upper node), so the chest tips toward
## the float centre while the seat stays planted and the arms/head still line up.
## Vertex colour carries the crease/underside shading; UV2 = (butt mask, belly mask).
static func pear_body(profile: PackedVector2Array, seat: Transform3D, lean: Transform3D, segments: int = 32) -> ArrayMesh:
	var builder: SurfaceTool = SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.set_smooth_group(0)
	for row: int in range(profile.size()):
		for column: int in range(segments):
			var angle: float = TAU * column / segments
			var sample: Dictionary = pear_sample(profile[row].x, profile[row].y, angle, seat, lean)
			builder.set_color(Color.WHITE.darkened(sample.shade))
			builder.set_uv2(sample.mask)
			builder.add_vertex(sample.point)
	for row: int in range(profile.size() - 1):
		for column: int in range(segments):
			var a: int = row * segments + column
			var b: int = row * segments + (column + 1) % segments
			var c: int = a + segments
			var d: int = b + segments
			for index: int in [a, c, b, b, c, d]:
				builder.add_index(index)
	builder.generate_normals()
	return builder.commit()

## Point on the pear body surface at height `y` (profile space) and `angle` (0 = front, PI = rear).
static func pear_point(profile: PackedVector2Array, seat: Transform3D, lean: Transform3D, y: float, angle: float, inset: float = 0.0) -> Vector3:
	var radius: float = profile[0].x
	for row: int in range(1, profile.size()):
		if y <= profile[row].y:
			radius = lerpf(profile[row - 1].x, profile[row].x, inverse_lerp(profile[row - 1].y, profile[row].y, y))
			break
	return pear_sample(maxf(radius - inset, 0.0), y, angle, seat, lean).point

static func pear_sample(radius: float, y: float, angle: float, seat: Transform3D, lean: Transform3D) -> Dictionary:
	var side: float = sin(angle)
	var front: float = cos(angle)
	var rear: float = maxf(-front, 0.0)
	var from_back: float = atan2(side, -front) # 0 straight back, +-PI/2 at the hips
	var hump: float = smoothstep(-0.10, 0.16, y) * (1.0 - smoothstep(0.26, 0.56, y))
	var lobe: float = exp(-pow((absf(from_back) - 0.44) / 0.32, 2.0)) * rear
	var crease: float = exp(-pow(from_back / 0.15, 2.0)) * rear
	var r: float = radius * (1.0 + hump * (0.16 * lobe - 0.20 * crease))
	var depth: float = front * r * (0.94 if front > 0.0 else lerpf(0.94, 0.80, smoothstep(0.30, 0.80, y)))
	var point: Vector3 = Vector3(side * r, y, depth - hump * lobe * 0.07)
	point = (seat * point).lerp(lean * point, smoothstep(0.30, 0.85, y))
	var belly: float = maxf(front, 0.0) * smoothstep(0.20, 0.45, y) * (1.0 - smoothstep(0.65, 0.95, y))
	return {"point": point, "shade": 0.24 * hump * crease + 0.10 * (1.0 - smoothstep(-0.05, 0.12, y)),
		"mask": Vector2(hump * smoothstep(0.05, 0.55, rear), belly)}

## Rounded tapered limb along +Y, `length` long, radius r0 at the base and r1 at the tip.
static func limb_mesh(length: float, r0: float, r1: float) -> ArrayMesh:
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, -r0), Vector2(r0 * 0.72, -r0 * 0.70), Vector2(r0, 0.0),
		Vector2(lerpf(r0, r1, 0.5) * 1.04, length * 0.5),
		Vector2(r1, length), Vector2(r1 * 0.72, length + r1 * 0.70), Vector2(0.0, length + r1)])
	return lathe(points, 12)

## Transform placing a +Y limb so it runs from `from` to `to`.
static func limb_transform(from: Vector3, to: Vector3) -> Transform3D:
	var axis: Vector3 = (to - from).normalized()
	var helper: Vector3 = Vector3.FORWARD if absf(axis.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x: Vector3 = axis.cross(helper).normalized()
	var z: Vector3 = x.cross(axis).normalized()
	return Transform3D(Basis(x, axis, z), from)
