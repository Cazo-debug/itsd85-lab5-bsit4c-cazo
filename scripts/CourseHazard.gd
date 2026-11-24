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
var phase: float = 0.0
var travel: float = 2.4

func configure(data: Dictionary, path: CoursePath) -> void:
	kind = data.type
	name = kind.capitalize()
	route_s = data.fraction * path.length
	lateral = data.lateral
	var frame: Dictionary = path.sample(route_s)
	transform = Transform3D(Basis(frame.lateral, frame.normal, -frame.tangent), frame.position + frame.lateral * lateral)
	base = transform
	response = "flow" if kind == "current" else ("push" if kind == "bumper" else "tip")
	if kind == "whirlpool":
		response = "flow"
	period = float(data.get("period", {"sweeper": 6.5, "mallet": 5.5}.get(kind, 5.0)))
	phase = float(data.get("phase", 0.0))
	travel = float(data.get("travel", 2.4))

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
		var marks: Array[Transform3D] = []
		for index: int in range(4):
			marks.append(Transform3D(Basis(Vector3.UP, -0.5), Vector3(-2.2 + index * 1.5, 0.03, 0)))
		mark_batch(self, Vector3(0.16, 0.03, 1.5), marks, Color("a8f4ed"))
		return
	if kind == "whirlpool":
		pivot = Node3D.new()
		add_child(pivot)
		var marks: Array[Transform3D] = []
		for index: int in range(6):
			var angle: float = index * TAU / 6.0
			marks.append(Transform3D(Basis(Vector3.UP, angle + 0.7), Vector3(sin(angle) * 3.3, 0.12, cos(angle) * 3.3)))
		mark_batch(pivot, Vector3(0.18, 0.04, 2.1), marks, Color("eafbff"))
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
			solid(moving, Vector3(6.5, 0.65, 0.7), Vector3(0, 0.7, 0), Color("ab5dc5"))
			solid(self, Vector3(0.45, 2, 0.45), Vector3(0, 0.5, 0), Color("ffcf50"))
		"mallet":
			moving.position.y = 5.8
			solid(moving, Vector3(0.32, 4.5, 0.32), Vector3(0, -2.2, 0), Color("ffcf50"))
			solid(moving, Vector3(2.6, 1.6, 1.9), Vector3(0, -4.4, 0), Color("ef6b75"))
		"crossbar":
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
		"gate":
			solid(moving, Vector3(4.0, 1.3, 0.65), Vector3(0, 0.75, 0), Color("263740"))
			var spikes: MultiMeshInstance3D = MultiMeshInstance3D.new()
			var cone: CylinderMesh = CylinderMesh.new()
			cone.top_radius = 0
			cone.bottom_radius = 0.18
			cone.height = 0.5
			cone.radial_segments = 5
			cone.material = AvatarModel.material(Color("fff1ad"))
			var batch: MultiMesh = MultiMesh.new()
			batch.transform_format = MultiMesh.TRANSFORM_3D
			batch.mesh = cone
			batch.instance_count = 7
			for index: int in range(7):
				batch.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(-1.65 + index * 0.55, 1.65, 0)))
			spikes.multimesh = batch
			spikes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			moving.add_child(spikes)
		"crusher":
			solid(moving, Vector3(3.0, 1.0, 2.2), Vector3.ZERO, Color("ef6b75"))
			solid(self, Vector3(0.4, 7.5, 0.4), Vector3(2.0, 3.5, 0), Color("ffcf50"))
			solid(self, Vector3(4.8, 0.35, 0.5), Vector3(0, 7.0, 0), Color("263740"))
		"boulder":
			var sphere: SphereMesh = SphereMesh.new()
			sphere.radius = 1.2
			sphere.height = 2.4
			sphere.radial_segments = 12
			sphere.rings = 6
			var stone: MeshInstance3D = MeshInstance3D.new()
			stone.mesh = sphere
			stone.material_override = AvatarModel.material(Color("8875ae"))
			stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			moving.add_child(stone)
			var shape: SphereShape3D = SphereShape3D.new()
			shape.radius = 1.2
			var collision: CollisionShape3D = CollisionShape3D.new()
			collision.shape = shape
			moving.add_child(collision)
			solid(moving, Vector3(0.12, 1.8, 1.6), Vector3(0.95, 0, 0), Color("c9b8e2"))

func mark_batch(parent: Node3D, size: Vector3, poses: Array[Transform3D], color: Color) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = AvatarModel.material(color)
	var batch: MultiMesh = MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = poses.size()
	for index: int in range(poses.size()):
		batch.set_instance_transform(index, poses[index])
	var visual: MultiMeshInstance3D = MultiMeshInstance3D.new()
	visual.multimesh = batch
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visual)

func evaluate(time: float) -> Transform3D:
	var result: Transform3D = Transform3D.IDENTITY
	var angle: float = (time + phase) * TAU / period
	match kind:
		"sweeper": result.basis = Basis(Vector3.UP, angle)
		"mallet":
			result.origin.y = 5.8
			result.basis = Basis(Vector3.FORWARD, sin(angle) * 0.85)
		"crossbar": result.origin.x = sin(angle) * 2.4
		"gate": result.origin.x = sin(angle) * travel
		"crusher": result.origin.y = 0.6 + (sin(angle) * 0.5 + 0.5) * 5.2
		"boulder":
			result.origin = Vector3(sin(angle) * travel, 1.0, 0)
			result.basis = Basis(Vector3.FORWARD, angle)
		"whirlpool": result.basis = Basis(Vector3.UP, angle)
	return result

## Foam circle where this hazard meets the water, in route space (s, lateral, radius).
## Radius <= 0 when the moving part is lifted clear of the water. Presentation only.
func water_foam() -> Vector3:
	var radius: float = {"bumper": 1.35, "sweeper": 0.45, "crossbar": 1.05, "gate": 1.3, "boulder": 1.2,
		"crusher": 1.5, "mallet": 1.2, "whirlpool": 3.4}.get(kind, 0.0)
	var offset: float = lateral
	if moving:
		offset += moving.position.x
		if kind == "crusher" and moving.position.y > 1.6:
			return Vector3(route_s, offset, -1.0)
		if kind == "mallet":
			var head: Vector3 = moving.transform * Vector3(0, -4.4, 0)
			if head.y > 1.9:
				return Vector3(route_s, offset, -1.0)
			offset = lateral + head.x
	return Vector3(route_s, offset, radius)

func update_time(time: float) -> void:
	if moving:
		moving.transform = evaluate(time)
	elif pivot:
		pivot.transform = evaluate(time)
