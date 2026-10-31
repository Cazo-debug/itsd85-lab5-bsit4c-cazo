class_name CoursePiece
extends Node3D

signal checkpoint_reached(player: FloatPlayer, distance: float)
signal finish_crossed(player: FloatPlayer)
signal bean_collected(player: FloatPlayer)

@export_enum("water", "bank", "island", "finish", "checkpoint", "bean") var kind: String = "bank"
@export var dimensions: Vector3 = Vector3(3, 1.2, 24)
@export var radius: float = 1.8
@export var course_width: float = 14.0
@export var distance: float = 0.0
var cooldown: float = 0.0
var animation_time: float = 0.0
var rim_size: Vector3 = Vector3.ZERO
var rim_at: Vector3 = Vector3.ZERO
var visual: MeshInstance3D

func _ready() -> void:
	match kind:
		"water": build_water()
		"bank": build_bank()
		"island": build_island()
		"finish": build_finish()
		"checkpoint": build_checkpoint()
		"bean": build_bean()
	var root_node: Node = self
	if root_node is StaticBody3D:
		var body: StaticBody3D = root_node as StaticBody3D
		body.collision_layer = 2
		body.collision_mask = 1
		var material: PhysicsMaterial = PhysicsMaterial.new()
		material.friction = 0.0
		body.physics_material_override = material
	if root_node is Area3D:
		var area: Area3D = root_node as Area3D
		area.collision_layer = 0
		area.collision_mask = 1
		area.body_entered.connect(_on_body_entered)

func mesh_part(mesh: PrimitiveMesh, color: Color, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = AvatarModel.material(color)
	part.position = at
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(part)
	return part

func box(size: Vector3, color: Color, at: Vector3) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return mesh_part(mesh, color, at)

func cylinder(size: Vector2, color: Color, at: Vector3) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.radial_segments = 16
	mesh.top_radius = size.x
	mesh.bottom_radius = size.x
	mesh.height = size.y
	return mesh_part(mesh, color, at)

func collision(shape: Shape3D) -> void:
	var collider: CollisionShape3D = CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)

func trigger(width: float, depth: float = 1.5) -> void:
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(width, 5.0, depth)
	collision(shape)

func build_water() -> void:
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(dimensions.x, dimensions.z)
	mesh.subdivide_width = maxi(1, ceili(dimensions.x / 1.5) - 1)
	mesh.subdivide_depth = maxi(1, ceili(dimensions.z / 1.5) - 1)
	visual = mesh_part(mesh, Color.WHITE)
	visual.material_override = SkyEnvironment.water()

func build_bank() -> void:
	var cliff: MeshInstance3D = box(Vector3(dimensions.x, 40.9, dimensions.z), Color.WHITE, Vector3(0, -19.55, 0))
	cliff.name = "Cliff"
	cliff.material_override = SkyEnvironment.cliff()
	var size: Vector3 = rim_size if rim_size != Vector3.ZERO else Vector3(0.7, 0.32, dimensions.z + 0.7)
	box(size, Color("7acb3b"), rim_at + Vector3(0, 0.91, 0)).name = "GrassRim"
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(dimensions.x, 2.9, dimensions.z)
	collision(shape)
	(get_child(-1) as CollisionShape3D).position.y = -0.55

func build_island() -> void:
	cylinder(Vector2(radius, 0.9), Color("ff9f45"), Vector3(0, 0.15, 0))
	cylinder(Vector2(radius + 0.04, 0.16), Color("ffa24c"), Vector3(0, 0.66, 0))
	var rim: TorusMesh = TorusMesh.new()
	rim.inner_radius = radius - 0.13
	rim.outer_radius = radius + 0.13
	rim.rings = 16
	rim.ring_segments = 8
	mesh_part(rim, Color("7acb3b"), Vector3(0, 0.68, 0))
	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = radius
	shape.height = 2.0
	collision(shape)

func build_finish() -> void:
	trigger(course_width, 2.5)
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = course_width / 2.0 - 0.45
	ring.outer_radius = course_width / 2.0 + 0.45
	ring.rings = 40
	ring.ring_segments = 10
	var hoop: MeshInstance3D = mesh_part(ring, Color("ffd23a"))
	hoop.rotation.x = PI / 2.0
	box(Vector3(5, 1.25, 0.15), Color("ff7a3d"), Vector3(0, course_width / 2.0 + 1.1, 0))
	var sign: Label3D = Label3D.new()
	sign.text = "FINISH"
	sign.font = preload("res://assets/fonts/Fredoka.ttf")
	sign.font_size = 96
	sign.pixel_size = 0.01
	sign.outline_size = 5
	sign.position = Vector3(0, course_width / 2.0 + 1.1, 0.09)
	add_child(sign)
	build_checker(course_width)

func build_checker(width: float) -> void:
	for color_index: int in range(2):
		var mesh: PlaneMesh = PlaneMesh.new()
		mesh.size = Vector2(width / 8.0, 0.7)
		var tiles: MultiMesh = MultiMesh.new()
		tiles.transform_format = MultiMesh.TRANSFORM_3D
		tiles.mesh = mesh
		tiles.instance_count = 8
		var tile_index: int = 0
		for x: int in range(8):
			for z: int in range(2):
				if (x + z) % 2 == color_index:
					tiles.set_instance_transform(tile_index, Transform3D(Basis.IDENTITY, Vector3(-width / 2.0 + (x + 0.5) * width / 8.0, 0.14, (z - 0.5) * 0.7)))
					tile_index += 1
		var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		instance.multimesh = tiles
		instance.material_override = AvatarModel.material(Color("f6f6f2") if color_index == 0 else Color("1e2329"))
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)

func build_checkpoint() -> void:
	trigger(course_width)
	for side: float in [-1.0, 1.0]:
		var at: Vector3 = Vector3(side * (course_width / 2.0 - 0.6), 0.25, 0)
		var buoy: SphereMesh = SphereMesh.new()
		buoy.radius = 0.5
		buoy.height = 1.0
		buoy.radial_segments = 12
		buoy.rings = 8
		mesh_part(buoy, Color("e94040"), at)
		cylinder(Vector2(0.51, 0.18), Color("f6f6f2"), at + Vector3(0, 0.05, 0))

func build_bean() -> void:
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = 0.27
	capsule.height = 0.85
	capsule.radial_segments = 12
	capsule.rings = 4
	visual = mesh_part(capsule, Color("9f5b31"), Vector3(0, 0.8, 0))
	visual.rotation.z = 0.6
	var halo: TorusMesh = TorusMesh.new()
	halo.inner_radius = 0.55
	halo.outer_radius = 0.61
	halo.rings = 16
	halo.ring_segments = 6
	mesh_part(halo, Color("ffcf50"), Vector3(0, 0.16, 0))
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = 1.1
	collision(shape)

func _process(delta: float) -> void:
	if kind == "bean" and visual:
		animation_time += delta
		visual.position.y = 0.8 + sin(animation_time * 2.8) * 0.18
		visual.rotation.y += delta * 1.4

func _physics_process(delta: float) -> void:
	if kind != "bean" or cooldown <= 0.0:
		return
	cooldown = maxf(0.0, cooldown - delta)
	if cooldown == 0.0:
		show()
		set_deferred("monitoring", true)

func _on_body_entered(body: Node3D) -> void:
	if not body is FloatPlayer:
		return
	var player: FloatPlayer = body as FloatPlayer
	if not player.controls_enabled:
		return
	match kind:
		"finish": finish_crossed.emit(player)
		"checkpoint": checkpoint_reached.emit(player, distance)
		"bean":
			if cooldown > 0.0 or player.gas == FloatPlayer.MAX_GAS:
				return
			player.add_gas(1)
			cooldown = 8.0
			hide()
			set_deferred("monitoring", false)
			Audio.play_sfx("bean")
			bean_collected.emit(player)
