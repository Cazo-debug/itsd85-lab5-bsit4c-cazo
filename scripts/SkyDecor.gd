class_name SkyDecor
extends Node3D

# Decorative geometry is batched by mesh/material, never given collision bodies.
const ACCENTS: Array[Color] = [Color("ff6b5a"), Color("2bb3a3"), Color("ffd23a"), Color("8f7cf6")]
var batches: Dictionary = {}
var clouds: MultiMeshInstance3D
var cloud_cards: MultiMeshInstance3D
var balloons: Node3D
var animation_time: float = 0.0
static var flag_material: ShaderMaterial
static var bob_material: ShaderMaterial
static var cloud_card_material: StandardMaterial3D
static var pennant: ArrayMesh

func add_part(key: String, mesh: Mesh, material: Material, at: Vector3, size: Vector3 = Vector3.ONE, rotation_z: float = 0.0) -> void:
	add_instance(key, mesh, material, Transform3D(Basis(Vector3.FORWARD, rotation_z).scaled(size), at))

## One MultiMesh instance; `color` / `custom` turn on per-instance colour / custom data for the batch.
func add_instance(key: String, mesh: Mesh, material: Material, transform: Transform3D, color: Variant = null, custom: Variant = null) -> void:
	if not batches.has(key):
		batches[key] = {"mesh": mesh, "material": material, "transforms": [], "colors": [], "customs": []}
	batches[key].transforms.append(transform)
	if color != null:
		batches[key].colors.append(color)
	if custom != null:
		batches[key].customs.append(custom)

func flush(parent: Node3D) -> void:
	for key: String in batches:
		var batch: Dictionary = batches[key]
		var multi: MultiMesh = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = not batch.colors.is_empty()
		multi.use_custom_data = not batch.customs.is_empty()
		multi.mesh = batch.mesh
		multi.instance_count = batch.transforms.size()
		for index: int in range(multi.instance_count):
			multi.set_instance_transform(index, batch.transforms[index])
			if multi.use_colors:
				multi.set_instance_color(index, batch.colors[index])
			if multi.use_custom_data:
				multi.set_instance_custom_data(index, batch.customs[index])
		var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instance.name = key
		instance.multimesh = multi
		instance.material_override = batch.material
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(instance)
		if key == "Clouds":
			clouds = instance
		elif key == "CloudCards":
			cloud_cards = instance
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

## Pennant along +X (UV.x 0 at the pole -> 1 at the tip), subdivided so flag.gdshader can wave it.
static func pennant_mesh() -> ArrayMesh:
	if pennant == null:
		var builder: SurfaceTool = SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var segments: int = 6
		for index: int in range(segments):
			var a: float = float(index) / segments
			var b: float = float(index + 1) / segments
			var corners: Array[Vector3] = [Vector3(a * 1.5, 0.36 * a, 0), Vector3(b * 1.5, 0.36 * b, 0), Vector3(b * 1.5, 0.72 - 0.36 * b, 0), Vector3(a * 1.5, 0.72 - 0.36 * a, 0)]
			for corner: int in [0, 1, 2, 0, 2, 3]:
				builder.set_uv(Vector2(corners[corner].x / 1.5, 0))
				builder.set_normal(Vector3.BACK)
				builder.add_vertex(corners[corner])
		pennant = builder.commit()
	return pennant

static func flag_shader() -> ShaderMaterial:
	if flag_material == null:
		flag_material = ShaderMaterial.new()
		flag_material.shader = preload("res://shaders/flag.gdshader")
	return flag_material

static func bob_shader() -> ShaderMaterial:
	if bob_material == null:
		bob_material = ShaderMaterial.new()
		bob_material.shader = preload("res://shaders/bob.gdshader")
	return bob_material

## Pole and waving pennant on a bank. All pennants stream with the same breeze (+X world).
func flag(at: Vector3, color: Color) -> void:
	add_part("FlagPoles", cylinder(1, 1, 6), AvatarModel.material(Color("f6f6f2")), at + Vector3(0, 1.55, 0), Vector3(0.06, 3.1, 0.06))
	add_part("FlagTops", sphere(6, 3), AvatarModel.material(Color("ffd23a")), at + Vector3(0, 3.15, 0), Vector3.ONE * 0.12)
	add_instance("Pennants", pennant_mesh(), flag_shader(), Transform3D(Basis.IDENTITY, at + Vector3(0, 2.35, 0)), color)

## Hot-air balloon that bobs and drifts (bob.gdshader); all parts share one phase.
func hot_air_balloon(at: Vector3, color: Color, phase: float) -> void:
	var custom: Color = Color(phase, 1.3, 0.0, 0.0)
	var shader: ShaderMaterial = bob_shader()
	add_instance("BalloonEnvelopes", sphere(16, 12), shader, Transform3D(Basis.from_scale(Vector3(3.4, 3.9, 3.4)), at), color, custom)
	add_instance("BalloonBands", cylinder(1, 1, 16), shader, Transform3D(Basis.from_scale(Vector3(3.46, 0.8, 3.46)), at + Vector3(0, 0.3, 0)), Color("f6f6f2"), custom)
	add_instance("BalloonBaskets", cylinder(0.85, 1.0, 10), shader, Transform3D(Basis.from_scale(Vector3(0.75, 1.0, 0.75)), at - Vector3(0, 5.3, 0)), Color("9a5e34"), custom)
	for side: float in [-1.0, 1.0]:
		add_instance("BalloonRopes", cylinder(1, 1, 5), shader, Transform3D(Basis.from_scale(Vector3(0.04, 2.0, 0.04)), at + Vector3(side * 0.55, -4.0, 0)), Color("6b4428"), custom)

## A small bunch of party balloons on strings above `at` (gate tops).
func party_balloons(at: Vector3, first_color: int, phase: float) -> void:
	var shader: ShaderMaterial = bob_shader()
	for index: int in range(3):
		var offset: Vector3 = Vector3((index - 1) * 0.42, 1.1 + (index % 2) * 0.35, (index % 2) * 0.25 - 0.1)
		var custom: Color = Color(phase + index * 0.9, 0.22, 0.8, 0.0)
		add_instance("PartyBalloons", sphere(10, 6), shader, Transform3D(Basis.from_scale(Vector3(0.42, 0.52, 0.42)), at + offset), ACCENTS[(first_color + index) % ACCENTS.size()], custom)
		add_instance("PartyStrings", cylinder(1, 1, 4), shader, Transform3D(Basis.from_scale(Vector3(0.02, offset.y - 0.4, 0.02)), at + Vector3(offset.x * 0.5, (offset.y - 0.4) * 0.5, offset.z * 0.5)), Color("f6f6f2"), custom)

## Big soft cumulus (generated): flat-ish bottom, shaded underside, soft edge.
static func cloud_texture() -> ImageTexture:
	var width: int = 128
	var height: int = 64
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var lobes: Array[Vector3] = [Vector3(0.24, 0.62, 0.20), Vector3(0.42, 0.42, 0.27), Vector3(0.62, 0.48, 0.24), Vector3(0.78, 0.64, 0.17), Vector3(0.52, 0.70, 0.22)]
	for y: int in range(height):
		for x: int in range(width):
			var p: Vector2 = Vector2((x + 0.5) / width, (y + 0.5) / height)
			var inside: float = 0.0
			for lobe: Vector3 in lobes:
				inside = maxf(inside, 1.0 - Vector2((p.x - lobe.x) * 2.0, p.y - lobe.y).length() / lobe.z)
			var bottom: float = 1.0 - smoothstep(0.74, 0.84, p.y)
			var alpha: float = smoothstep(0.0, 0.22, inside) * bottom
			var shade: float = lerpf(1.0, 0.80, smoothstep(0.45, 0.85, p.y))
			image.set_pixel(x, y, Color(shade, shade * 1.02, minf(shade * 1.08, 1.0), alpha))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)

## Camera-facing cloud card (distant layers). Low quality hides them.
func cloud_card(at: Vector3, size: float) -> void:
	if cloud_card_material == null:
		cloud_card_material = StandardMaterial3D.new()
		cloud_card_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cloud_card_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cloud_card_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		cloud_card_material.billboard_keep_scale = true
		cloud_card_material.albedo_texture = cloud_texture()
		cloud_card_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var card: Mesh = batches["CloudCards"].mesh if batches.has("CloudCards") else null
	if card == null:
		var quad: QuadMesh = QuadMesh.new()
		quad.size = Vector2(2.0, 1.0)
		card = quad
	add_instance("CloudCards", card, cloud_card_material, Transform3D(Basis.from_scale(Vector3.ONE * size), at))

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
