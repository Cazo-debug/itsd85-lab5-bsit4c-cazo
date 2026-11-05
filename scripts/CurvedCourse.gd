class_name CurvedCourse
extends Node3D

var path: CoursePath
var hazards: Array[CourseHazard] = []
var pickups: Array[Dictionary] = []
var checkpoints: Array[float] = []
var finish_s: float
var water: MeshInstance3D
var decor: SkyDecor
var builders: Dictionary = {}

func triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, uv_a: Vector2, uv_b: Vector2, uv_c: Vector2) -> void:
	var normal: Vector3 = (b - a).cross(c - a).normalized()
	for item: Array in [[a, uv_a], [b, uv_b], [c, uv_c]]:
		tool.set_normal(normal)
		tool.set_uv(item[1])
		if tool == builders["Water"]:
			var frame: Dictionary = path.sample(item[1].x)
			tool.set_color(Color(frame.tangent.x * 0.5 + 0.5, frame.tangent.y * 0.5 + 0.5, frame.tangent.z * 0.5 + 0.5))
			tool.set_uv2(Vector2(absf(item[1].y) / (frame.width * 0.5), frame.width * 0.5))
		tool.add_vertex(item[0])

func quad(key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv: Array) -> void:
	var tool: SurfaceTool = builders[key]
	triangle(tool, a, b, c, uv[0], uv[1], uv[2])
	triangle(tool, a, c, d, uv[0], uv[2], uv[3])

func build(definition: Dictionary) -> void:
	path = CoursePath.new()
	path.build(definition)
	for key: String in ["Water", "Cliffs", "Banks", "Rims", "Shafts"]:
		var tool: SurfaceTool = SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		builders[key] = tool
	var wall_body: StaticBody3D = StaticBody3D.new()
	wall_body.name = "GuardedBanks"
	wall_body.collision_layer = 2
	wall_body.collision_mask = 1
	add_child(wall_body)
	for index: int in range(path.frames.size() - 1):
		var a: Dictionary = path.frames[index]
		var b: Dictionary = path.frames[index + 1]
		for strip: int in range(6):
			var left: float = strip / 6.0 - 0.5
			var right: float = (strip + 1) / 6.0 - 0.5
			quad("Water", a.position + a.lateral * a.width * left, a.position + a.lateral * a.width * right, b.position + b.lateral * b.width * right, b.position + b.lateral * b.width * left, [Vector2(a.s, a.width * left), Vector2(a.s, a.width * right), Vector2(b.s, b.width * right), Vector2(b.s, b.width * left)])
		for side: float in [-1.0, 1.0]:
			var edge_a: Vector3 = a.position + a.lateral * (a.width / 2) * side
			var edge_b: Vector3 = b.position + b.lateral * (b.width / 2) * side
			var outer_a: Vector3 = edge_a + a.lateral * 1.0 * side
			var outer_b: Vector3 = edge_b + b.lateral * 1.0 * side
			quad("Banks", edge_a, outer_a, outer_b, edge_b, [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN])
			quad("Cliffs", outer_a, outer_b, outer_b - Vector3.UP * 30, outer_a - Vector3.UP * 30, [Vector2(a.s, 0), Vector2(b.s, 0), Vector2(b.s, 30), Vector2(a.s, 30)])
			var radius: float = 0.14 if path.exposed_at(a.s, side) else 0.32
			for ring_index: int in range(8):
				var angle: float = ring_index * TAU / 8.0
				var next_angle: float = (ring_index + 1) * TAU / 8.0
				var aa: Vector3 = edge_a + a.normal * radius + (a.lateral * cos(angle) + a.normal * sin(angle)) * radius
				var ab: Vector3 = edge_a + a.normal * radius + (a.lateral * cos(next_angle) + a.normal * sin(next_angle)) * radius
				var ba: Vector3 = edge_b + b.normal * radius + (b.lateral * cos(angle) + b.normal * sin(angle)) * radius
				var bb: Vector3 = edge_b + b.normal * radius + (b.lateral * cos(next_angle) + b.normal * sin(next_angle)) * radius
				quad("Rims", aa, ab, bb, ba, [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN])
			if not path.exposed_at(a.s, side):
				var shape: CollisionShape3D = CollisionShape3D.new()
				var box: BoxShape3D = BoxShape3D.new()
				box.size = Vector3(0.65, 1.35, edge_a.distance_to(edge_b) + 0.22)
				shape.shape = box
				shape.transform = Transform3D(Basis(a.lateral, a.normal, -a.tangent), (edge_a + edge_b) * 0.5 + a.normal * 0.30)
				wall_body.add_child(shape)
	for hole: Dictionary in path.holes:
		var frame: Dictionary = path.sample(hole.s)
		var center: Vector3 = frame.position + frame.lateral * hole.lateral
		for index: int in range(32):
			var angle: float = index * TAU / 32
			var next: float = (index + 1) * TAU / 32
			var a: Vector3 = center + (frame.lateral * cos(angle) + frame.tangent * sin(angle)) * hole.radius
			var b: Vector3 = center + (frame.lateral * cos(next) + frame.tangent * sin(next)) * hole.radius
			quad("Shafts", a, b, b - frame.normal * 9, a - frame.normal * 9, [Vector2(index, 0), Vector2(index + 1, 0), Vector2(index + 1, 9), Vector2(index, 9)])
		var rim_mesh: TorusMesh = TorusMesh.new()
		rim_mesh.inner_radius = hole.radius - 0.07
		rim_mesh.outer_radius = hole.radius + 0.09
		rim_mesh.rings = 32
		rim_mesh.ring_segments = 6
		mesh(rim_mesh, Color("eafbff"), Transform3D(Basis(frame.lateral, frame.normal, -frame.tangent), center + frame.normal * 0.03))
	var water_material: ShaderMaterial = ShaderMaterial.new()
	water_material.shader = preload("res://shaders/route_water.gdshader")
	path.water_style.apply_to(water_material)
	var holes: PackedVector3Array = PackedVector3Array()
	for hole: Dictionary in path.holes:
		holes.append(Vector3(hole.s, hole.lateral, hole.radius))
	while holes.size() < 8:
		holes.append(Vector3.ZERO)
	water_material.set_shader_parameter("holes", holes)
	water_material.set_shader_parameter("hole_count", path.holes.size())
	var cliff_material: ShaderMaterial = ShaderMaterial.new()
	cliff_material.shader = preload("res://shaders/route_cliff.gdshader")
	cliff_material.set_shader_parameter("cliff_tint", definition.get("cliff_tint", Color.WHITE))
	for key: String in builders:
		var instance: MeshInstance3D = MeshInstance3D.new()
		instance.name = key
		instance.mesh = builders[key].commit()
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.material_override = water_material if key == "Water" else (cliff_material if key in ["Cliffs", "Shafts"] else AvatarModel.material(Color("7acb3b") if key == "Rims" else definition.get("bank_color", Color("ffa24c"))))
		add_child(instance)
		if key == "Water":
			water = instance
	builders.clear()
	for definition_hazard: Dictionary in definition.hazards:
		var hazard: CourseHazard = CourseHazard.new()
		hazard.configure(definition_hazard, path)
		add_child(hazard)
		hazards.append(hazard)
	for fraction: float in definition.checkpoints:
		checkpoints.append(fraction * path.length)
		make_gate(fraction * path.length, Color("fff1ad"), false)
	finish_s = path.length - 8.0
	make_gate(finish_s, Color("ffffff"), true)
	for fraction: float in definition.beans:
		var at: Vector3 = path.sample(fraction * path.length).position + Vector3.UP * 0.8
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = 0.38
		sphere.height = 0.9
		sphere.radial_segments = 8
		sphere.rings = 4
		var instance: MeshInstance3D = mesh(sphere, Color("ffcf50"), Transform3D(Basis.IDENTITY, at))
		pickups.append({"s": fraction * path.length, "node": instance, "ready_at": 0.0})
	build_decor()

func update_water(time: float, ring: SwimRing) -> void:
	path.water_time = time
	var material: ShaderMaterial = water.material_override
	material.set_shader_parameter("water_time", time)
	var frame: Dictionary = path.project(ring.position, ring.route_s)
	material.set_shader_parameter("ring_uv", Vector2(frame.s, frame.offset))
	var velocity: Vector2 = Vector2(ring.linear_velocity.dot(frame.tangent), ring.linear_velocity.dot(frame.lateral))
	material.set_shader_parameter("wake_velocity", velocity if not ring.falling else Vector2.ZERO)
	material.set_shader_parameter("ring_supported", not ring.falling and path.surface_at(ring.position, ring.route_s).valid and absf(ring.position.y - frame.position.y) < 1.5)

func mesh(geometry: PrimitiveMesh, color: Color, at: Transform3D) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = geometry
	instance.material_override = AvatarModel.material(color)
	instance.transform = at
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func make_gate(distance: float, color: Color, finish: bool) -> void:
	var frame: Dictionary = path.sample(distance)
	for side: float in [-1, 1]:
		var pole: CylinderMesh = CylinderMesh.new()
		pole.top_radius = 0.13
		pole.bottom_radius = 0.13
		pole.height = 4.4
		pole.radial_segments = 8
		mesh(pole, color, Transform3D(Basis.IDENTITY, frame.position + frame.lateral * (frame.width / 2 + 0.5) * side + Vector3.UP * 2.2))
	var banner: BoxMesh = BoxMesh.new()
	banner.size = Vector3(frame.width + 1, 0.8, 0.12)
	mesh(banner, Color("403156") if finish else Color("2bb3a3"), Transform3D(Basis(frame.lateral, frame.normal, -frame.tangent), frame.position + Vector3.UP * 4.2))
	var label: Label3D = Label3D.new()
	label.text = "FINISH TOGETHER" if finish else "CHECKPOINT"
	label.font = preload("res://assets/fonts/Fredoka.ttf")
	label.font_size = 64
	label.pixel_size = 0.012
	label.position = frame.position + Vector3.UP * 4.25 - frame.tangent * 0.10
	label.basis = Basis(frame.lateral, frame.normal, -frame.tangent)
	label.no_depth_test = false
	add_child(label)

func build_decor() -> void:
	decor = SkyDecor.new()
	add_child(decor)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 23
	for index: int in range(42):
		var frame: Dictionary = path.sample(path.length * index / 41.0)
		var side: float = -1 if index % 2 == 0 else 1
		var at: Vector3 = frame.position + frame.lateral * side * (frame.width / 2 + 10 + rng.randf_range(0, 12)) - Vector3.UP * rng.randf_range(10, 22)
		for lobe: int in range(3):
			decor.add_part("Clouds", decor.sphere(8, 3), AvatarModel.material(Color("effaff")), at + Vector3(lobe * 3, lobe % 2, 0), Vector3(4.5, 1.4, 2.8))
		if index % 4 == 0:
			var island: Vector3 = frame.position + frame.lateral * side * (frame.width / 2 + 10) - Vector3.UP * 4
			decor.add_part("Islets", decor.cylinder(1, 0.2, 8), AvatarModel.material(Color("ef8071")), island - Vector3.UP * 4, Vector3(3.5, 8, 3.5))
			decor.add_part("Grass", decor.cylinder(1, 1, 10), AvatarModel.material(Color("7acb3b")), island, Vector3(3.6, 0.4, 3.6))
			decor.umbrella(island, index % 4)
		if index % 3 == 0:
			var bank: Vector3 = frame.position + frame.lateral * side * (frame.width / 2 + 1.1)
			decor.add_part("Shrubs", decor.sphere(8, 4), AvatarModel.material(Color("68b93d")), bank + Vector3.UP * 0.6, Vector3(0.75, 0.8, 0.75))
	decor.flush(decor)
