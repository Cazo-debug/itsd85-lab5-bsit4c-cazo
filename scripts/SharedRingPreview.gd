class_name SharedRingPreview
extends Node3D

const SEAT_RADIUS: float = 1.9
var appearance: Dictionary = {}
var riders: Array[RiderModel] = []
var anchors: Array[Node3D] = []
var ring: Node3D

func mesh_part(parent: Node3D, mesh: PrimitiveMesh, color: Color, at: Vector3) -> MeshInstance3D:
	var part: MeshInstance3D = MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = AvatarModel.material(color)
	part.position = at
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(part)
	return part

func apply(avatar: Dictionary) -> void:
	# Single-profile creator compatibility helper.
	configure([avatar], [{"control": "local", "profile": 0, "owner": "local:0"}], 0)

func configure(profiles: Array[Dictionary], slots: Array[Dictionary], leader: int, edited: int = -1) -> void:
	for child: Node in get_children():
		child.free()
	riders.clear()
	anchors.clear()
	appearance = AvatarData.sanitize(profiles[leader] if leader >= 0 and leader < profiles.size() else {})
	ring = Node3D.new()
	ring.name = "SharedRing"
	add_child(ring)
	var style: String = AvatarData.FLOAT_STYLES[appearance.float_style]
	var color: Color = AvatarData.OUTFIT_COLORS[appearance.outfit]
	if style == "duck":
		color = Color("ffcf50")
	elif style == "lifebuoy":
		color = Color("ff625d")
	var tube: TorusMesh = TorusMesh.new()
	tube.inner_radius = 1.55
	tube.outer_radius = 2.45
	tube.rings = 32
	tube.ring_segments = 10
	mesh_part(ring, tube, color, Vector3.ZERO).scale.y = 0.72
	var platform: CylinderMesh = CylinderMesh.new()
	platform.top_radius = 1.78
	platform.bottom_radius = 1.78
	platform.height = 0.16
	platform.radial_segments = 32
	mesh_part(ring, platform, Color("fff1d5"), Vector3(0, -0.10, 0))
	if style in ["striped", "lifebuoy"]:
		for index: int in range(8):
			var angle: float = index * TAU / 8.0
			var stripe: CapsuleMesh = CapsuleMesh.new()
			stripe.radius = 0.33
			stripe.height = 0.92
			stripe.radial_segments = 8
			stripe.rings = 3
			var part: MeshInstance3D = mesh_part(ring, stripe, Color.WHITE, Vector3(sin(angle), 0.015, cos(angle)) * 2.0)
			part.rotation = Vector3(PI / 2.0, angle, 0)
	if style == "duck":
		var head: SphereMesh = SphereMesh.new()
		head.radius = 0.34
		head.height = 0.68
		head.radial_segments = 12
		head.rings = 6
		mesh_part(ring, head, color, Vector3(1.53, 0.42, 1.53))
		var beak: BoxMesh = BoxMesh.new()
		beak.size = Vector3(0.32, 0.13, 0.32)
		mesh_part(ring, beak, Color("ff9f45"), Vector3(1.76, 0.37, 1.76))
	var clean: Array[Dictionary] = CrewData.sanitize_slots(slots, profiles)
	for index: int in range(CrewData.MAX_RIDERS):
		var angle: float = index * TAU / 4.0
		var anchor: Node3D = Node3D.new()
		anchor.name = "Seat%d" % (index + 1)
		anchor.position = Vector3(sin(angle), 0, cos(angle)) * SEAT_RADIUS
		anchor.rotation.y = angle + PI
		add_child(anchor)
		anchors.append(anchor)
		var pad: CylinderMesh = CylinderMesh.new()
		pad.top_radius = 0.44
		pad.bottom_radius = 0.44
		pad.height = 0.07
		pad.radial_segments = 12
		var slot: Dictionary = clean[index]
		mesh_part(anchor, pad, Color("ffcf50") if edited >= 0 and slot.profile == edited else Color("bdedf1"), Vector3(0, 0.29, 0))
		if slot.control != "empty":
			var rider: RiderModel = RiderModel.new()
			rider.name = "Rider%d" % (index + 1)
			rider.scale = Vector3.ONE * 0.72
			rider.position.y = 0.26
			rider.apply(profiles[slot.profile])
			anchor.add_child(rider)
			riders.append(rider)
			if slot.profile == edited:
				var colors: Array[Color] = [Color("48a832"), Color("723ca8"), Color("f29cce"), Color("ffe76c")]
				for puff_index: int in range(3):
					var puff: SphereMesh = SphereMesh.new()
					puff.radius = 0.13 + puff_index * 0.035
					puff.height = puff.radius * 2.0
					puff.radial_segments = 8
					puff.rings = 4
					mesh_part(rider, puff, colors[rider.appearance.toot], Vector3(0, 0.1, -0.65 - puff_index * 0.35))
