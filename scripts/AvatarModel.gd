class_name AvatarModel
extends Node3D

static var materials: Dictionary = {}
var appearance: Dictionary = {}

static func material(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		var shared: StandardMaterial3D = StandardMaterial3D.new()
		shared.albedo_color = color
		shared.roughness = 0.85
		materials[color] = shared
	return materials[color]

func _ready() -> void:
	if get_child_count() == 0:
		apply(AvatarData.default_avatar())

func part(mesh: PrimitiveMesh, color: Color, at: Vector3, stretch: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material(color)
	instance.position = at
	instance.scale = stretch
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func ball(color: Color, at: Vector3, stretch: Vector3) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 6
	return part(mesh, color, at, stretch)

func cylinder(color: Color, at: Vector3, bottom: float, top: float, height: float) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.radial_segments = 12
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	return part(mesh, color, at)

func apply(avatar: Dictionary) -> void:
	appearance = AvatarData.sanitize(avatar)
	for child: Node in get_children():
		child.free()
	var outfit: Color = AvatarData.OUTFIT_COLORS[appearance.outfit]
	var skin: Color = AvatarData.SKIN_TONES[appearance.skin]
	var style: String = AvatarData.FLOAT_STYLES[appearance.float_style]
	var puff_colors: Array[Color] = [Color("48a832"), Color("723ca8"), Color("f29cce"), Color("ffe76c")]
	for index: int in range(3):
		ball(puff_colors[appearance.toot], Vector3(0.16 * (index % 2), 0.10 + index * 0.10, -1.35 - index * 0.28), Vector3.ONE * (0.45 + index * 0.12))
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = 0.68
	ring.outer_radius = 1.3
	ring.rings = 16
	ring.ring_segments = 12
	part(ring, Color("ffcf50") if style == "duck" else outfit, Vector3.ZERO, Vector3(1, 0.8, 1))
	if style in ["striped", "lifebuoy"]:
		for index: int in range(16):
			var angle: float = TAU * index / 16.0
			var color: Color = Color.WHITE if index % 2 == 0 else (Color("ff625d") if style == "lifebuoy" else outfit)
			var segment: CapsuleMesh = CapsuleMesh.new()
			segment.radius = 0.31
			segment.height = 0.66
			segment.radial_segments = 12
			segment.rings = 4
			var piece: MeshInstance3D = part(segment, color, Vector3(cos(angle), 0, sin(angle)))
			piece.rotation = Vector3(PI / 2.0, -angle, 0)
	var body: CapsuleMesh = CapsuleMesh.new()
	body.radius = 0.42
	body.height = 0.95
	body.radial_segments = 12
	body.rings = 4
	part(body, outfit, Vector3(0, 0.62, 0))
	ball(skin, Vector3(0, 1.38, 0), Vector3(0.92, 0.85, 0.88))
	for side: float in [-1.0, 1.0]:
		ball(Color("1e2329"), Vector3(side * 0.16, 1.43, 0.40), Vector3(0.10, 0.07, 0.07))
		ball(skin, Vector3(side * 0.59, 0.5, 0.22), Vector3(0.34, 0.19, 0.4))
		ball(skin, Vector3(side * 0.35, 0.16, 0.55), Vector3(0.35, 0.22, 0.65))
	if style == "duck":
		ball(Color("ffcf50"), Vector3(0, 0.55, 1.05), Vector3(0.72, 0.45, 0.72))
		var beak: MeshInstance3D = cylinder(Color("ff9f45"), Vector3(0, 0.50, 1.55), 0.22, 0, 0.44)
		beak.rotation.x = PI / 2
		for side: float in [-1.0, 1.0]:
			ball(Color("1e2329"), Vector3(side * 0.22, 0.7, 1.29), Vector3(0.08, 0.05, 0.08))
	match AvatarData.HATS[appearance.hat]:
		"cap", "propeller":
			ball(outfit, Vector3(0, 1.77, 0), Vector3(1.0, 0.22, 0.95))
			ball(outfit.lightened(0.2), Vector3(0, 1.70, 0.35), Vector3(1.0, 0.05, 0.75))
			if appearance.hat == 3:
				cylinder(Color.WHITE, Vector3(0, 2.02, 0), 0.04, 0.04, 0.3)
				var blade: BoxMesh = BoxMesh.new()
				blade.size = Vector3(1.15, 0.06, 0.18)
				part(blade, Color("ffcf50"), Vector3(0, 2.18, 0))
		"crown":
			cylinder(Color("ffcf50"), Vector3(0, 1.85, 0), 0.42, 0.42, 0.25)
			for index: int in range(5):
				var angle: float = TAU * index / 5.0
				cylinder(Color("ffcf50"), Vector3(cos(angle) * 0.34, 2.08, sin(angle) * 0.34), 0.13, 0, 0.35)
		"bucket":
			cylinder(outfit, Vector3(0, 1.87, 0), 0.48, 0.35, 0.44)
			cylinder(outfit.lightened(0.2), Vector3(0, 1.67, 0), 0.58, 0.58, 0.08)
