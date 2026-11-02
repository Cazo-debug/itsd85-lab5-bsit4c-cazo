class_name RiderModel
extends Node3D

var appearance: Dictionary = {}
var body_root: Node3D
var charge_material: StandardMaterial3D
var thrust_heat: float = 0.0
var pose_clock: float = 0.0

static func material(color: Color) -> StandardMaterial3D:
	return AvatarModel.material(color)

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
	body_root.add_child(instance)
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
	body_root = Node3D.new()
	add_child(body_root)
	var outfit: Color = AvatarData.OUTFIT_COLORS[appearance.outfit]
	var skin: Color = AvatarData.SKIN_TONES[appearance.skin]
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
	# A clothed rear panel, kept separate from the static batch for charge color.
	var rear: MeshInstance3D = MeshInstance3D.new()
	var rear_mesh: SphereMesh = SphereMesh.new()
	rear_mesh.radial_segments = 12
	rear_mesh.rings = 6
	rear.mesh = rear_mesh
	rear.position = Vector3(0, 0.39, -0.28)
	rear.scale = Vector3(0.90, 0.55, 0.68)
	charge_material = StandardMaterial3D.new()
	charge_material.albedo_color = outfit
	charge_material.roughness = 0.65
	charge_material.emission_enabled = true
	rear.material_override = charge_material
	rear.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rear)

func animate_activity(delta: float, thrusting: bool, stepping: float) -> void:
	thrust_heat = move_toward(thrust_heat, 1.0 if thrusting else 0.0, delta * (5.5 if thrusting else 2.8))
	pose_clock += delta * 12.0
	var outfit: Color = AvatarData.OUTFIT_COLORS[appearance.outfit]
	charge_material.albedo_color = outfit.lerp(Color("ff384c"), thrust_heat)
	charge_material.emission = Color("ff243e") * thrust_heat * 0.14
	body_root.rotation.x = -thrust_heat * 0.16
	body_root.rotation.z = sin(pose_clock) * minf(stepping, 1.0) * 0.055
	body_root.position.y = absf(sin(pose_clock)) * minf(stepping, 1.0) * 0.035
