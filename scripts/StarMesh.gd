class_name StarMesh
extends RefCounted

# A chunky five-point star drawn from code (no downloaded models). Built once and shared.
static var cached: ArrayMesh

static func build(outer: float = 0.75, inner: float = 0.34, half_thickness: float = 0.16) -> ArrayMesh:
	if cached != null:
		return cached
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim: Array[Vector2] = []
	for index: int in range(10):
		var angle: float = PI * 0.5 + index * PI / 5.0
		var radius: float = outer if index % 2 == 0 else inner
		rim.append(Vector2(cos(angle), sin(angle)) * radius)
	var front: Vector3 = Vector3(0, 0, half_thickness * 1.6)
	var back: Vector3 = Vector3(0, 0, -half_thickness * 1.6)
	for index: int in range(10):
		var a: Vector2 = rim[index]
		var b: Vector2 = rim[(index + 1) % 10]
		var af: Vector3 = Vector3(a.x, a.y, half_thickness)
		var bf: Vector3 = Vector3(b.x, b.y, half_thickness)
		var ab: Vector3 = Vector3(a.x, a.y, -half_thickness)
		var bb: Vector3 = Vector3(b.x, b.y, -half_thickness)
		_triangle(tool, front, af, bf)
		_triangle(tool, back, bb, ab)
		_triangle(tool, af, ab, bb)
		_triangle(tool, af, bb, bf)
	tool.generate_normals()
	cached = tool.commit()
	return cached

static func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)
