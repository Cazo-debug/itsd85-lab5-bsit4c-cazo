class_name SwimRing
extends RigidBody3D

signal fell
signal recovered
signal bumped
# Phase 5 can start attack/loop audio and release it from these transitions.
signal thrust_started(seat: int)
signal thrust_stopped(seat: int)
const MAX_RIDERS: int = 4
var profile: RingPhysicsProfile = RingPhysicsProfile.new()
var path: CoursePath
var route_s: float = 3.0
var checkpoint_s: float = 3.0
var checkpoint: Transform3D
var gas: Array[float] = [1.0, 1.0, 1.0, 1.0]
var seat_control: Array[String] = ["empty", "empty", "empty", "empty"]
var aim: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var strength: Array[float] = [0.0, 0.0, 0.0, 0.0]
var held: Array[bool] = [false, false, false, false]
var firing: Array[bool] = [false, false, false, false]
var depleted: Array[bool] = [false, false, false, false]
var rested: Array[float] = [0.0, 0.0, 0.0, 0.0]
var simulate: bool = false
var falling: bool = false
var fall_time: float = 0.0
var unsupported_time: float = 0.0
var upside_down_time: float = 0.0
var recoveries: int = 0
var contact_count: int = 0
var visual: SharedRingPreview
var jets: Array[CPUParticles3D] = []
var ripple: MeshInstance3D
var avatars: Array[Dictionary] = []
var slots: Array[Dictionary] = []
var leader: int = 0
var force_seconds: Array[float] = [0.0, 0.0, 0.0, 0.0]
var peak_tilt: float = 0.0
var feedback_active: Array[bool] = [false, false, false, false]
var orbit: RiderOrbit = RiderOrbit.new()
var aiming: Array[bool] = [false, false, false, false]
var orbit_motion: Array[float] = [0.0, 0.0, 0.0, 0.0]
var spray: CPUParticles3D
var quiet_firing: Array[bool] = [false, false, false, false]
var quiet_motion: Array[float] = [0.0, 0.0, 0.0, 0.0]

func setup(course_path: CoursePath, profiles: Array[Dictionary], crew: Array[Dictionary], leader_profile: int) -> void:
	path = course_path
	avatars = profiles.duplicate(true)
	slots = CrewData.sanitize_slots(crew, avatars)
	leader = leader_profile
	for index: int in range(MAX_RIDERS):
		seat_control[index] = slots[index].control
	checkpoint = path.safe_transform(checkpoint_s)
	transform = checkpoint

func _ready() -> void:
	if path == null:
		var fallback: CoursePath = CoursePath.new()
		fallback.build(SkyGardenData.definition())
		var profiles: Array[Dictionary] = CrewData.default_profiles()
		profiles[0] = AvatarData.default_avatar()
		setup(fallback, profiles, CrewData.default_slots(), 0)
	mass = profile.mass
	linear_damp = 0.04
	angular_damp = profile.angular_drag
	continuous_cd = true
	can_sleep = false
	collision_layer = 1
	collision_mask = 2
	contact_monitor = true
	max_contacts_reported = 8
	freeze = true
	var physics: PhysicsMaterial = PhysicsMaterial.new()
	physics.bounce = 0.2
	physics.friction = 0.10
	physics_material_override = physics
	var collision: CollisionShape3D = CollisionShape3D.new()
	var cylinder: CylinderShape3D = CylinderShape3D.new()
	cylinder.radius = profile.radius
	cylinder.height = 0.60
	collision.shape = cylinder
	add_child(collision)
	visual = SharedRingPreview.new()
	add_child(visual)
	visual.configure(avatars, slots, leader)
	visual.bake_moving_parts()
	for index: int in range(MAX_RIDERS):
		var jet: CPUParticles3D = CPUParticles3D.new()
		jet.emitting = false
		jet.amount = 10
		jet.lifetime = 0.55
		jet.local_coords = false
		jet.spread = 20.0
		jet.gravity = Vector3(0, 0.4, 0)
		jet.initial_velocity_min = 3.0
		jet.initial_velocity_max = 5.0
		jet.scale_amount_min = 0.16
		jet.scale_amount_max = 0.38
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radial_segments = 8
		sphere.rings = 4
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.vertex_color_use_as_albedo = true
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sphere.material = material
		jet.mesh = sphere
		jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var fade: Gradient = Gradient.new()
		var color_index: int = avatars[slots[index].profile].toot if slots[index].control != "empty" else 0
		var color: Color = RaceEffects.PUFF_COLORS[color_index]
		fade.colors = PackedColorArray([color, Color(color, 0.0)])
		jet.color_ramp = fade
		add_child(jet)
		jet.top_level = true
		jets.append(jet)
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(5.6, 5.6)
	ripple = MeshInstance3D.new()
	ripple.mesh = plane
	ripple.material_override = RaceEffects.ring_material()
	ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ripple)
	ripple.top_level = true
	spray = CPUParticles3D.new()
	spray.amount = 24
	spray.lifetime = 0.50
	spray.emitting = false
	spray.local_coords = false
	spray.gravity = Vector3(0, -8, 0)
	spray.spread = 65
	spray.initial_velocity_min = 1.0
	spray.initial_velocity_max = 2.5
	spray.scale_amount_min = 0.04
	spray.scale_amount_max = 0.12
	var drop: SphereMesh = SphereMesh.new()
	drop.radial_segments = 6
	drop.rings = 3
	drop.material = AvatarModel.material(Color("c8faff"))
	spray.mesh = drop
	spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(spray)
	spray.top_level = true
	body_entered.connect(_on_contact)

func set_rider_avatar(seat: int, avatar: Dictionary) -> void:
	if seat < 0 or seat >= MAX_RIDERS or seat_control[seat] == "empty":
		return
	avatars[slots[seat].profile] = AvatarData.sanitize(avatar)
	visual.configure(avatars, slots, leader)
	visual.bake_moving_parts()
	for index: int in range(jets.size()):
		if seat_control[index] != "empty":
			var color: Color = RaceEffects.PUFF_COLORS[avatars[slots[index].profile].toot]
			jets[index].color_ramp.colors = PackedColorArray([color, Color(color, 0.0)])

func set_aim_input(seat: int, direction_world: Vector3) -> bool:
	if seat < 0 or seat >= MAX_RIDERS or seat_control[seat] == "empty" or not simulate or falling:
		return false
	if not direction_world.is_finite() or direction_world.length_squared() < 0.001:
		return false
	aim[seat] = direction_world.normalized()
	aiming[seat] = true
	return true

func set_thrust_input(seat: int, direction_world: Vector3, requested_strength: float, requested_held: bool) -> bool:
	if seat < 0 or seat >= MAX_RIDERS or seat_control[seat] == "empty":
		return false
	if not requested_held:
		held[seat] = false
		strength[seat] = 0
		if direction_world.is_finite() and direction_world.length_squared() > 0.001:
			set_aim_input(seat, direction_world)
		return true
	if not simulate or falling or not direction_world.is_finite() or not is_finite(requested_strength):
		return false
	if direction_world.length_squared() < 0.001:
		return false
	set_aim_input(seat, direction_world)
	strength[seat] = clampf(requested_strength, 0, 1)
	held[seat] = true
	return true

func release_all_inputs() -> void:
	for index: int in range(MAX_RIDERS):
		held[index] = false
		aiming[index] = false
		strength[index] = 0
		firing[index] = false
		if feedback_active[index]:
			feedback_active[index] = false
			thrust_stopped.emit(index)
	for jet: CPUParticles3D in jets:
		jet.emitting = false
	if is_instance_valid(spray):
		spray.emitting = false

func add_gas_all(amount: float) -> void:
	if not is_finite(amount) or amount <= 0:
		return
	for index: int in range(MAX_RIDERS):
		if seat_control[index] != "empty":
			gas[index] = minf(1.0, gas[index] + amount)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if path == null or not simulate:
		return
	var delta: float = state.step
	var center: Vector3 = state.transform.origin
	var frame: Dictionary = path.project(center, route_s)
	route_s = frame.s
	if falling:
		fall_time += delta
		return
	var previous_angles: Array[float] = orbit.angles.duplicate()
	orbit.advance(aim, aiming, seat_control, state.transform.basis, profile.rider_orbit_speed, delta)
	visual.place_riders(orbit)
	for seat: int in range(MAX_RIDERS):
		orbit_motion[seat] = absf(angle_difference(previous_angles[seat], orbit.angles[seat])) / maxf(delta * profile.rider_orbit_speed, 0.0001)
	var surface: Dictionary = path.surface_at(center, route_s)
	unsupported_time = 0.0 if surface.valid else unsupported_time + delta
	upside_down_time = upside_down_time + delta if state.transform.basis.y.dot(Vector3.UP) < 0.2 else 0.0
	peak_tilt = maxf(peak_tilt, acos(clampf(state.transform.basis.y.dot(Vector3.UP), -1, 1)))
	if unsupported_time > 0.14 or center.y < frame.position.y - 3.0 or upside_down_time > 2.5:
		enter_fall()
		return
	var support: int = 0
	for index: int in range(4):
		var offset: Vector3 = state.transform.basis * Vector3(sin(index * TAU / 4) * 1.65, 0, cos(index * TAU / 4) * 1.65)
		var point: Vector3 = center + offset
		var local_surface: Dictionary = path.surface_at(point, route_s)
		if local_surface.valid and point.y > local_surface.height - 2.5 and point.y < local_surface.height + 2.5:
			support += 1
			var normal: Vector3 = local_surface.normal
			var velocity: Vector3 = state.linear_velocity + state.angular_velocity.cross(offset)
			var error: float = (local_surface.position + normal * 0.28 - point).dot(normal)
			var acceleration: float = 9.8 + error * profile.support_spring - velocity.dot(normal) * profile.support_damping
			state.apply_force(normal * clampf(acceleration, 0, 60) * mass / 4.0, offset)
	if support > 0:
		var horizontal: Vector3 = state.linear_velocity.slide(frame.normal)
		state.apply_central_force(-horizontal * mass * profile.water_drag + surface.flow * mass)
		var load: Vector3 = Vector3.ZERO
		var riders: int = MAX_RIDERS - seat_control.count("empty")
		for seat: int in range(MAX_RIDERS):
			if seat_control[seat] != "empty":
				load += state.transform.basis * orbit.offset(seat, SharedRingPreview.SEAT_RADIUS) / maxf(riders, 1)
		state.apply_torque(load.cross(Vector3.DOWN * mass * 9.8) * profile.rider_load_shift)
	var occupied: int = MAX_RIDERS - seat_control.count("empty")
	for index: int in range(MAX_RIDERS):
		firing[index] = false
		if seat_control[index] == "empty":
			continue
		if not held[index] and gas[index] >= profile.rearm_threshold:
			depleted[index] = false
		if held[index] and not depleted[index] and strength[index] > 0 and support > 0:
			var direction: Vector3 = aim[index].slide(frame.normal).normalized()
			var burn: float = minf(gas[index], profile.gas_drain * strength[index] * delta)
			var available: float = burn / maxf(profile.gas_drain * strength[index] * delta, 0.000001)
			var force: Vector3 = direction * mass * profile.thrust_acceleration * strength[index] * available / pow(float(occupied), 0.72)
			var offset: Vector3 = state.transform.basis * orbit.offset(index, SharedRingPreview.SEAT_RADIUS, 0.08)
			state.apply_force(force, offset)
			gas[index] -= burn
			force_seconds[index] += delta * available
			rested[index] = 0
			firing[index] = burn > 0
			if gas[index] < 0.00001:
				gas[index] = 0
				depleted[index] = true
		else:
			rested[index] += delta
			if rested[index] > profile.recovery_delay:
				gas[index] = minf(1, gas[index] + profile.gas_recovery * delta)
	var planar: Vector3 = state.linear_velocity.slide(Vector3.UP)
	if planar.length() > profile.max_speed:
		planar = planar.limit_length(profile.max_speed)
		state.linear_velocity = Vector3(planar.x, state.linear_velocity.y, planar.z)
	state.angular_velocity = state.angular_velocity.limit_length(profile.max_spin)

func enter_fall() -> void:
	if falling or not simulate:
		return
	falling = true
	fall_time = 0
	release_all_inputs()
	fell.emit()

func respawn_at_checkpoint() -> void:
	if not simulate:
		return
	release_all_inputs()
	orbit.reset()
	orbit_motion.fill(0.0)
	visual.place_riders(orbit)
	global_transform = checkpoint
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	route_s = checkpoint_s
	falling = false
	fall_time = 0
	unsupported_time = 0
	upside_down_time = 0
	recoveries += 1
	reset_physics_interpolation()
	recovered.emit()

func _process(delta: float) -> void:
	var pose: Transform3D = get_global_transform_interpolated()
	visual.animate_riders(firing if simulate and not falling else quiet_firing, orbit_motion if simulate and not falling else quiet_motion, delta)
	for index: int in range(jets.size()):
		jets[index].global_position = pose * orbit.offset(index, 1.70, 0.44)
		jets[index].direction = -aim[index] + Vector3.UP * 0.15
		jets[index].emitting = firing[index] and simulate and not falling
		var active: bool = jets[index].emitting and held[index]
		if active != feedback_active[index]:
			feedback_active[index] = active
			if active:
				thrust_started.emit(index)
			else:
				thrust_stopped.emit(index)
	if path != null:
		var at: Vector3 = pose.origin
		var frame: Dictionary = path.surface_at(at, route_s)
		ripple.visible = frame.valid and not falling and absf(at.y - frame.height) < 1.4
		ripple.global_transform = Transform3D(Basis.looking_at(frame.tangent, frame.normal), Vector3(at.x, frame.height + 0.04, at.z))
		var velocity: Vector3 = linear_velocity.slide(frame.normal)
		spray.global_position = Vector3(at.x, frame.height + 0.12, at.z) - velocity.normalized() * 2.3
		spray.direction = (-velocity.normalized() + Vector3.UP * 1.4).normalized()
		spray.emitting = ripple.visible and simulate and velocity.length() > 2.0

func _on_contact(_body: Node) -> void:
	contact_count += 1
	bumped.emit()
