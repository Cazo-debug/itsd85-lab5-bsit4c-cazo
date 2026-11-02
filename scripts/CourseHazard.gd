class_name CourseHazard
extends Node3D

var kind: String
var route_s: float
var lateral: float
var response: String = "push"
var period: float = 5.0
var moving: AnimatableBody3D
var pivot: Node3D
var base: Transform3D
var contacts: int = 0

func configure(data: Dictionary, path: CoursePath) -> void:
	kind = data.type
	name = kind.capitalize()
	route_s = data.fraction * path.length
	lateral = data.lateral
	var frame: Dictionary = path.sample(route_s)
	transform = Transform3D(Basis(frame.lateral, frame.normal, -frame.tangent), frame.position + frame.lateral * lateral)
	base = transform
	response = "flow" if kind == "current" else ("push" if kind == "bumper" else "tip")

func solid(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.mesh = box
	visual.material_override = AvatarModel.material(color)
	visual.position = at
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)
	if parent is PhysicsBody3D:
		var collision: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		collision.position = at
		parent.add_child(collision)
	return visual

func _ready() -> void:
	if kind == "current":
		for index: int in range(4):
			solid(self, Vector3(0.16, 0.03, 1.5), Vector3(-2.2 + index * 1.5, 0.03, 0), Color("a8f4ed")).rotation.y = -0.5
		return
	moving = AnimatableBody3D.new()
	moving.collision_layer = 2
	moving.collision_mask = 1
	moving.sync_to_physics = false
	add_child(moving)
	var material: PhysicsMaterial = PhysicsMaterial.new()
	material.bounce = 0.35
	material.friction = 0.15
	moving.physics_material_override = material
	match kind:
		"bumper":
			solid(moving, Vector3(2.0, 1.8, 2.0), Vector3(0, 0.65, 0), Color("f19dcd"))
			solid(self, Vector3(2.1, 0.2, 2.1), Vector3(0, 1.55, 0), Color("ffcf50"))
		"sweeper":
			period = 6.5
			solid(moving, Vector3(6.5, 0.65, 0.7), Vector3(0, 0.7, 0), Color("ab5dc5"))
			solid(self, Vector3(0.45, 2, 0.45), Vector3(0, 0.5, 0), Color("ffcf50"))
		"mallet":
			period = 5.5
			moving.position.y = 5.8
			solid(moving, Vector3(0.32, 4.5, 0.32), Vector3(0, -2.2, 0), Color("ffcf50"))
			solid(moving, Vector3(2.6, 1.6, 1.9), Vector3(0, -4.4, 0), Color("ef6b75"))
		"crossbar":
			period = 5.0
			solid(moving, Vector3(3.5, 1.1, 0.55), Vector3(0, 0.65, 0), Color("263740"))
			for index: int in range(6):
				var spike: MeshInstance3D = MeshInstance3D.new()
				var cone: CylinderMesh = CylinderMesh.new()
				cone.top_radius = 0
				cone.bottom_radius = 0.17
				cone.height = 0.5
				cone.radial_segments = 5
				spike.mesh = cone
				spike.material_override = AvatarModel.material(Color.WHITE)
				spike.position = Vector3(-1.4 + index * 0.56, 1.4, 0)
				spike.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				moving.add_child(spike)

func evaluate(time: float) -> Transform3D:
	var result: Transform3D = Transform3D.IDENTITY
	var angle: float = time * TAU / period
	match kind:
		"sweeper": result.basis = Basis(Vector3.UP, angle)
		"mallet":
			result.origin.y = 5.8
			result.basis = Basis(Vector3.FORWARD, sin(angle) * 0.85)
		"crossbar": result.origin.x = sin(angle) * 2.4
	return result

func update_time(time: float) -> void:
	if moving:
		moving.transform = evaluate(time)
