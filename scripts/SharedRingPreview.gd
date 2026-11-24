class_name SharedRingPreview
extends Node3D

const SEAT_RADIUS: float = 1.9
const RIDER_SCALE: float = 0.94 # big enough that four riders nearly fill the float
const MAX_TILT: float = 0.21 # radians; the float never visibly tips past ~12 degrees
var appearance: Dictionary = {}
var seat_bases: Array[Transform3D] = []
var baked_hull: bool = false
var riders: Array[RiderModel] = []
var anchors: Array[Node3D] = []
var ring: Node3D
# Visual-only feel of the float (never physics): springs for tilt (x pitch, y roll),
# heave, surge (local xz) and squash. Driven by rider weight, turns, waves, bursts and hits.
var tilt: Vector2 = Vector2.ZERO
var tilt_velocity: Vector2 = Vector2.ZERO
var heave: float = 0.0
var heave_velocity: float = 0.0
var surge: Vector2 = Vector2.ZERO
var surge_velocity: Vector2 = Vector2.ZERO
var squash: float = 0.0
var squash_velocity: float = 0.0
## Where the float dips from its own motion and the waves (ring-local, length = radians).
var dip: Vector3 = Vector3.ZERO
var wave_heave: float = 0.0
## True while a SwimRing animates the riders; menus animate idle life themselves.
var driven: bool = false

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
	baked_hull = false
	tilt = Vector2.ZERO
	tilt_velocity = Vector2.ZERO
	heave = 0.0
	heave_velocity = 0.0
	surge = Vector2.ZERO
	surge_velocity = Vector2.ZERO
	squash = 0.0
	squash_velocity = 0.0
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
	seat_bases.clear()
	for index: int in range(CrewData.MAX_RIDERS):
		# Drawn opposite the physics seat (see RiderOrbit.visual_offset).
		var angle: float = index * TAU / 4.0 + PI
		var anchor: Node3D = Node3D.new()
		anchor.name = "Seat%d" % (index + 1)
		anchor.position = Vector3(sin(angle), 0, cos(angle)) * SEAT_RADIUS
		anchor.rotation.y = angle
		add_child(anchor)
		anchors.append(anchor)
		seat_bases.append(anchor.transform)
		var slot: Dictionary = clean[index]
		seat_fixture(anchor, edited >= 0 and slot.profile == edited, slot.control != "empty")
		if slot.control != "empty":
			var rider: RiderModel = RiderModel.new()
			rider.name = "Rider%d" % (index + 1)
			rider.scale = Vector3.ONE * RIDER_SCALE
			rider.position.y = 0.30
			rider.rotation.y = PI # face the hub, rear to the outside
			rider.apply(profiles[slot.profile])
			rider.setup_motion(index)
			anchor.add_child(rider)
			riders.append(rider)
			rider.bake()
			if slot.profile == edited:
				var colors: Array[Color] = FartConfig.current.colors
				for puff_index: int in range(3):
					var puff: QuadMesh = QuadMesh.new()
					puff.size = Vector2.ONE * (0.55 + puff_index * 0.2)
					puff.material = RaceEffects.puff_billboard(colors[rider.appearance.toot])
					var cloud: MeshInstance3D = MeshInstance3D.new()
					cloud.mesh = puff
					cloud.position = Vector3(0.1 * (puff_index % 2), 0.35 + puff_index * 0.12, -0.75 - puff_index * 0.38)
					cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					rider.add_child(cloud)

# One fixture per seat: a soft blob shadow on the tube and the two grab handles.
func seat_fixture(anchor: Node3D, highlighted: bool, occupied: bool = true) -> void:
	var fixture: Node3D = Node3D.new()
	fixture.name = "Fixture"
	anchor.add_child(fixture)
	var blob: MeshInstance3D = MeshInstance3D.new()
	blob.visible = occupied # no shadow on an empty seat
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(1.5, 1.5)
	blob.mesh = plane
	blob.material_override = highlight_material() if highlighted else RaceEffects.ring_material(true)
	blob.position = Vector3(0, 0.33, -0.05)
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fixture.add_child(blob)
	for side: float in [-1.0, 1.0]:
		var loop: TorusMesh = TorusMesh.new()
		loop.inner_radius = 0.07
		loop.outer_radius = 0.14
		loop.rings = 12
		loop.ring_segments = 6
		var handle: MeshInstance3D = mesh_part(fixture, loop, Color("f4f1e6"), Vector3(side * 0.85, 0.36, -0.40))
		handle.rotation.z = PI / 2.0
		handle.visible = occupied

func highlight_material() -> ShaderMaterial:
	var glow: ShaderMaterial = ShaderMaterial.new()
	glow.shader = preload("res://shaders/ring.gdshader")
	glow.set_shader_parameter("tint", Color(1.0, 0.81, 0.31, 0.55))
	glow.set_shader_parameter("filled", true)
	return glow

func bake_moving_parts() -> void:
	# Keep each rider independently movable; only static subassemblies are baked.
	if not baked_hull:
		var hull: MeshInstance3D = MeshBatch.bake(ring)
		hull.material_override.roughness = 0.28
		baked_hull = true
	for rider: RiderModel in riders:
		rider.bake()

func update_riders(orbit: RiderOrbit, active: Array[bool], moving: Array[float], delta: float) -> void:
	place_riders(orbit)
	animate_riders(active, moving, delta)

func place_riders(orbit: RiderOrbit) -> void:
	var feel: Transform3D = feel_transform()
	for seat: int in range(4):
		seat_bases[seat] = Transform3D(Basis(Vector3.UP, orbit.visual_angle(seat)), orbit.visual_offset(seat, SEAT_RADIUS))
		anchors[seat].transform = feel * seat_bases[seat]

## Rider lean target in the ring's local frame (riders lean back on surges, into turns).
func set_float_motion(lean_toward: Vector3) -> void:
	for seat: int in range(4):
		for child: Node in anchors[seat].get_children():
			if child is RiderModel:
				var local: Vector3 = (anchors[seat].basis * child.basis).inverse() * lean_toward
				child.set_float_motion(Vector2(local.z, local.x))

## Dip direction from turning/acceleration and the wave slope (ring-local, radians), plus wave heave.
func set_dip(direction: Vector3, wave_lift: float) -> void:
	dip = direction.limit_length(MAX_TILT)
	wave_heave = wave_lift

func set_mood(mood: String) -> void:
	for rider: RiderModel in riders:
		rider.set_mood(mood)

## A burst from `seat`: rider squash-and-stretch, the seat dips and the float kicks away from the gas.
func burst(seat: int, outward: Vector3) -> void:
	for child: Node in anchors[seat].get_children():
		if child is RiderModel:
			child.burst()
	var away: Vector3 = outward.slide(Vector3.UP)
	if away.length_squared() > 0.0001:
		push_tilt(away.normalized(), deg_to_rad(FartConfig.current.wobble_degrees) * 7.0)
		surge_velocity -= Vector2(away.x, away.z).normalized() * 0.8
		heave_velocity -= 0.22

## Obstacle contact from `direction` (ring-local): the float rocks, squashes and slides away; arms flail.
func impact(direction: Vector3, strength: float = 1.0) -> void:
	var from: Vector3 = direction.slide(Vector3.UP)
	if from.length_squared() > 0.0001:
		push_tilt(-from.normalized(), 1.6 * strength)
		surge_velocity -= Vector2(from.x, from.z).normalized() * 0.9 * strength
	squash_velocity += 2.2 * strength
	for rider: RiderModel in riders:
		rider.flail(strength)

## Back on the water after a drop: heave down, squash, splash-bounce the riders.
func land(strength: float) -> void:
	heave_velocity -= 1.6 * strength
	squash_velocity += 3.0 * strength
	for rider: RiderModel in riders:
		rider.bump(strength)

## Tilt impulse that dips the float toward `toward` (ring-local, horizontal).
func push_tilt(toward: Vector3, speed: float) -> void:
	tilt_velocity += Vector2(toward.z, -toward.x) * speed

func feel_transform(with_squash: bool = false) -> Transform3D:
	var basis: Basis = Basis.from_euler(Vector3(tilt.x, 0.0, tilt.y))
	if with_squash:
		basis = basis * Basis.from_scale(Vector3(1.0 + squash * 0.45, 1.0 - squash, 1.0 + squash * 0.45))
	return Transform3D(basis, Vector3(surge.x, heave - (0.0 if with_squash else squash * 0.22), surge.y))

func step_feel(delta: float) -> void:
	var step: float = minf(delta, 1.0 / 30.0)
	# The float dips toward where the riders are drawn (their weight), plus motion and waves.
	var weight: Vector3 = Vector3.ZERO
	var aboard: int = 0
	for anchor_index: int in range(anchors.size()):
		for child: Node in anchors[anchor_index].get_children():
			if child is RiderModel:
				weight += seat_bases[anchor_index].origin / SEAT_RADIUS
				aboard += 1
	var goal_dip: Vector3 = weight / maxf(aboard, 1) * deg_to_rad(7.0) + dip
	var goal: Vector2 = Vector2(goal_dip.z, -goal_dip.x).limit_length(MAX_TILT)
	tilt_velocity += ((goal - tilt) * 55.0 - tilt_velocity * 6.5) * step
	tilt = (tilt + tilt_velocity * step).limit_length(MAX_TILT * 1.4)
	heave_velocity += ((wave_heave - heave) * 70.0 - heave_velocity * 7.0) * step
	heave = clampf(heave + heave_velocity * step, -0.35, 0.35)
	surge_velocity += (-surge * 40.0 - surge_velocity * 6.0) * step
	surge = (surge + surge_velocity * step).limit_length(0.45)
	squash_velocity += (-squash * 190.0 - squash_velocity * 9.0) * step
	squash = clampf(squash + squash_velocity * step, -0.18, 0.22)

func animate_riders(active: Array[bool], moving: Array[float], delta: float) -> void:
	step_feel(delta)
	ring.transform = feel_transform(true)
	var feel: Transform3D = feel_transform()
	for seat: int in range(4):
		var anchor: Node3D = anchors[seat]
		anchor.transform = feel * seat_bases[seat]
		for child: Node in anchor.get_children():
			if child is RiderModel:
				child.animate_activity(delta, active[seat], moving[seat])

const QUIET_ACTIVE: Array[bool] = [false, false, false, false]
const QUIET_MOTION: Array[float] = [0.0, 0.0, 0.0, 0.0]

func _process(delta: float) -> void:
	# Menus and previews: idle life (blinks, glances, breathing). A race drives riders itself.
	if not driven and not anchors.is_empty() and anchors.size() == 4 and seat_bases.size() == 4:
		animate_riders(QUIET_ACTIVE, QUIET_MOTION, delta)
