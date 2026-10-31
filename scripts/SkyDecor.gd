class_name SkyDecor
extends Node3D

# Decorative geometry is batched by mesh/material, never given collision bodies.
const ACCENTS: Array[Color] = [Color("ff6b5a"), Color("2bb3a3"), Color("ffd23a"), Color("8f7cf6")]
var batches: Dictionary = {}
var clouds: MultiMeshInstance3D
var balloons: Node3D
var animation_time: float = 0.0

func add_part(key: String, mesh: PrimitiveMesh, material: Material, at: Vector3, size: Vector3 = Vector3.ONE, rotation_z: float = 0.0) -> void:
	if not batches.has(key):
		batches[key] = {"mesh": mesh, "material": material, "transforms": []}
	var basis: Basis = Basis(Vector3.FORWARD, rotation_z).scaled(size)
	batches[key].transforms.append(Transform3D(basis, at))

func flush(parent: Node3D) -> void:
	for key: String in batches:
		var batch: Dictionary = batches[key]
		var multi: MultiMesh = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = batch.mesh
		multi.instance_count = batch.transforms.size()
		for index: int in range(multi.instance_count):
			multi.set_instance_transform(index, batch.transforms[index])
		var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instance.name = key
		instance.multimesh = multi
		instance.material_override = batch.material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(instance)
		if key == "Clouds":
			clouds = instance
	batches.clear()

func sphere(radial: int = 12, rings: int = 8) -> SphereMesh:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = radial
	mesh.rings = rings
	return mesh

func cylinder(top: float = 1.0, bottom: float = 1.0, radial: int = 16) -> CylinderMesh:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = 1.0
	mesh.radial_segments = radial
	return mesh

func torus() -> TorusMesh:
	var mesh: TorusMesh = TorusMesh.new()
	mesh.inner_radius = 0.94
	mesh.outer_radius = 1.06
	mesh.rings = 20
	mesh.ring_segments = 6
	return mesh

func umbrella(at: Vector3, accent: int, tilt: float = 0.0) -> void:
	add_part("UmbrellaPoles", cylinder(1, 1, 6), AvatarModel.material(Color("f6f6f2")), at + Vector3(0, 1.0, 0), Vector3(0.06, 2.2, 0.06))
	add_part("Canopy%d" % accent, cylinder(0, 1, 10), AvatarModel.material(ACCENTS[accent]), at + Vector3(0, 2.1, 0), Vector3(1.3, 0.55, 1.3), tilt)

func build(segments: Array = [], course_length: float = 150.0) -> void:
	for child: Node in get_children():
		child.free()
	batches.clear()
	animation_time = 0.0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var cloud_material: StandardMaterial3D = StandardMaterial3D.new()
	cloud_material.albedo_color = Color.WHITE
	cloud_material.roughness = 1.0
	cloud_material.emission_enabled = true
	cloud_material.emission = Color("50606a")
	var cloud_mesh: SphereMesh = sphere(10, 8)
	for cluster: int in range(32):
		var at: Vector3
		var size: float = rng.randf_range(1.5, 4.0)
		if cluster < 22:
			at = Vector3(rng.randf_range(-65, 65), rng.randf_range(-34, -14), rng.randf_range(-course_length - 40, 20))
		else:
			var side: float = -1.0 if cluster % 2 == 0 else 1.0
			at = Vector3(side * rng.randf_range(45, 105), rng.randf_range(2, 24), rng.randf_range(-course_length - 40, 10))
		for lobe: int in range(4):
			var offset: Vector3 = Vector3((lobe - 1.5) * 1.6 * size, (lobe % 2) * 0.6 * size, rng.randf_range(-0.75, 0.75) * size)
			add_part("Clouds", cloud_mesh, cloud_material, at + offset, Vector3(1.6, rng.randf_range(1, 1.4), 1.3) * size)
	for index: int in range(9):
		var side: float = -1.0 if index % 2 == 0 else 1.0
		var at: Vector3 = Vector3(side * rng.randf_range(24, 64), rng.randf_range(-6, 8), 10.0 - index * (course_length + 40) / 8.0 - rng.randf_range(0, 10))
		var radius: float = rng.randf_range(2.5, 5.5)
		add_part("IslandTops", cylinder(), AvatarModel.material(Color("ffa24c")), at, Vector3(radius, 1.2, radius))
		add_part("IslandRims", torus(), AvatarModel.material(Color("7acb3b")), at + Vector3(0, 0.6, 0), Vector3(radius, 1.0, radius))
		add_part("IslandCliffs", cylinder(1, 0), SkyEnvironment.cliff(), at - Vector3(0, 0.6 + radius * 1.1, 0), Vector3(radius, radius * 2.2, radius))
		umbrella(at + Vector3(radius * 0.3, 0.6, 0), index % 4)
	for index: int in range(segments.size()):
		var segment: Dictionary = segments[index]
		var side: float = -1.0 if index % 2 == 0 else 1.0
		umbrella(Vector3(segment.x + side * (segment.width / 2.0 + 1.7), 0.9, -segment.d - segment.length * 0.55), index % 4, side * 0.12)
	flush(self)
	balloons = Node3D.new()
	balloons.name = "Balloons"
	add_child(balloons)
	var positions: Array[Vector3] = [Vector3(-42, 16, -60), Vector3(48, 22, -120), Vector3(-55, 10, -175)]
	for index: int in range(3):
		var at: Vector3 = positions[index]
		add_part("Envelope%d" % index, sphere(16, 12), AvatarModel.material(ACCENTS[index]), at, Vector3(3.4, 3.91, 3.4))
		add_part("WhiteBands", cylinder(), AvatarModel.material(Color("f6f6f2")), at, Vector3(3.42, 0.85, 3.42))
		var basket: BoxMesh = BoxMesh.new()
		basket.size = Vector3.ONE
		add_part("Baskets", basket, AvatarModel.material(Color("7a4a2c")), at - Vector3(0, 5.4, 0), Vector3(1.4, 1.1, 1.4))
		for side: float in [-1.0, 1.0]:
			add_part("Ropes", cylinder(1, 1, 6), AvatarModel.material(Color("7a4a2c")), at + Vector3(side * 0.55, -4, 0), Vector3(0.04, 2.4, 0.04))
	flush(balloons)

func _process(delta: float) -> void:
	animation_time += delta
	if is_instance_valid(clouds):
		clouds.position.x = sin(animation_time * 0.035) * 8.0
	if is_instance_valid(balloons):
		balloons.position.y = sin(animation_time * 0.35) * 1.2
