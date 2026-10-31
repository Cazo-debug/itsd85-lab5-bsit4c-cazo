class_name CourseHole
extends Node3D

@export var radius: float = 1.8

func _ready() -> void:
	var shaft: CylinderMesh = CylinderMesh.new()
	shaft.top_radius = radius
	shaft.bottom_radius = radius
	shaft.height = 7.0
	shaft.radial_segments = 28
	shaft.cap_top = false
	shaft.cap_bottom = false
	add_mesh(shaft, SkyEnvironment.cliff(), Vector3(0, -3.5, 0))
	var rim: TorusMesh = TorusMesh.new()
	rim.inner_radius = radius - 0.17
	rim.outer_radius = radius + 0.17
	rim.rings = 28
	rim.ring_segments = 6
	add_mesh(rim, AvatarModel.material(Color("eafbff")), Vector3(0, 0.12, 0))

func add_mesh(mesh: PrimitiveMesh, material: Material, at: Vector3) -> void:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = at
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(part)

func contains_center(point: Vector3) -> bool:
	return Vector2(point.x - global_position.x, point.z - global_position.z).length() < radius - 0.2
