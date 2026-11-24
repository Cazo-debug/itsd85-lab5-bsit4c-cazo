class_name SwimRing
extends RigidBody3D

signal fell
signal recovered
signal bumped
# Phase 5 can start attack/loop audio and release it from these transitions.
signal thrust_started(seat: int)
signal thrust_stopped(seat: int)
## Presentation only: one visual fart burst from a seat (camera kick, etc.).
signal fart_burst(seat: int)
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
var remote_replica: bool = false
var remote_playing: bool = false
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
var wake: CPUParticles3D
var tags: Array[Label3D] = []
var burst_pools: Array[Array] = []
# Two foam rings and two droplet bursts per seat, used alternately so overlapping bursts never cut each other.
var splashes: Array[CPUParticles3D] = []
var droplet_pools: Array[Array] = []
var splash_turn: Array[int] = [0, 0, 0, 0]
var big_splash: CPUParticles3D
var big_ring: CPUParticles3D
var low_effects: bool = false
## Presentation: the crew cheers after a shared finish (set by RunFeedback).
var celebrating: bool = false
var was_falling: bool = false
var seen_contacts: int = 0
var contact_direction: Vector3 = Vector3.ZERO
var airborne: bool = false
var descent: float = 0.0
var previous_height: float = 0.0
var vertical_speed: float = 0.0
var burst_timers: Array[float] = [0.0, 0.0, 0.0, 0.0]
var bursts_fired: Array[int] = [0, 0, 0, 0]
var splash_height: float = 0.0
var splash_height_valid: bool = false
var last_velocity: Vector3 = Vector3.ZERO
var smoothed_acceleration: Vector3 = Vector3.ZERO
# Visual-only randomness (sound pitch); never used by physics or hazards.
var visual_rng: RandomNumberGenerator = RandomNumberGenerator.new()

## World position of a rider's seat as drawn (used to award stars).
func seat_position(seat: int) -> Vector3:
	return global_transform * orbit.visual_offset(seat, SharedRingPreview.SEAT_RADIUS, 0.5)

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
	visual.driven = true
	add_child(visual)
	visual.configure(avatars, slots, leader)
	visual.bake_moving_parts()
	# Per rider: a small pool of one-shot burst emitters (the pool size is the hard puff cap).
	var config: FartConfig = FartConfig.current
	for index: int in range(MAX_RIDERS):
		var pool: Array[CPUParticles3D] = []
		for slot_index: int in range(config.emitters_per_rider()):
			var burst: CPUParticles3D = RaceEffects.fart_burst_emitter(gas_color(index), config, config.puffs_per_burst)
			add_child(burst)
			burst.top_level = true
			pool.append(burst)
		burst_pools.append(pool)
		jets.append(pool[0])
		var drops: Array[CPUParticles3D] = []
		for turn: int in range(2):
			var splash: CPUParticles3D = RaceEffects.splash_ring()
			add_child(splash)
			splash.top_level = true
			splashes.append(splash)
			var droplets: CPUParticles3D = RaceEffects.droplets(config.splash_droplets)
			add_child(droplets)
			droplets.top_level = true
			drops.append(droplets)
		droplet_pools.append(drops)
	big_splash = RaceEffects.droplets(22, 5.0)
	add_child(big_splash)
	big_splash.top_level = true
	big_ring = RaceEffects.splash_ring()
	big_ring.amount = 3
	big_ring.mesh = RaceEffects.foam_ring_mesh(5.5)
	add_child(big_ring)
	big_ring.top_level = true
	ripple = MeshInstance3D.new()
	ripple.mesh = RaceEffects.foam_ring_mesh(5.6)
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
	spray.mesh = RaceEffects.droplet_mesh()
	spray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(spray)
	spray.top_level = true
	wake = RaceEffects.wake_rings()
	add_child(wake)
	wake.top_level = true
	for index: int in range(MAX_RIDERS):
		var tag: Label3D = Label3D.new()
		tag.font = preload("res://assets/fonts/Fredoka.ttf")
		tag.font_size = 64
		tag.outline_size = 20
		tag.outline_modulate = Color("16324a")
		tag.pixel_size = 0.005
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.no_depth_test = true
		tag.fixed_size = false
		tag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tag)
		tag.top_level = true
		tags.append(tag)
	refresh_tags()
	body_entered.connect(_on_contact)
	prewarm.call_deferred()

## Compile the effect shaders during the intro instead of on the first fart (a ~0.6 s hitch on
## the test phone): throwaway bursts of each kind, hidden just under the water at the start.
## They never touch the per-rider pools, so the puff cap and burst counts are unaffected.
func prewarm() -> void:
	if not is_inside_tree():
		return
	var config: FartConfig = FartConfig.current
	for emitter: CPUParticles3D in [RaceEffects.fart_burst_emitter(gas_color(0), config, 2), RaceEffects.droplets(2), RaceEffects.splash_ring()]:
		add_child(emitter)
		emitter.top_level = true
		emitter.global_position = global_position - Vector3.UP * 1.2
		emitter.finished.connect(emitter.queue_free)
		emitter.restart()

func refresh_tags() -> void:
	for index: int in range(tags.size()):
		var occupied: bool = seat_control[index] != "empty"
		tags[index].text = String(avatars[slots[index].profile].get("name", "")) if occupied else ""
		tags[index].modulate = Color.WHITE if index == 0 else Color(1, 1, 1, 0.92)

func set_rider_avatar(seat: int, avatar: Dictionary) -> void:
	if seat < 0 or seat >= MAX_RIDERS or seat_control[seat] == "empty":
		return
	avatars[slots[seat].profile] = AvatarData.sanitize(avatar)
	visual.configure(avatars, slots, leader)
	visual.bake_moving_parts()
	for index: int in range(burst_pools.size()):
		for burst: CPUParticles3D in burst_pools[index]:
			RaceEffects.set_burst_color(burst, gas_color(index))
	refresh_tags()

func gas_color(seat: int) -> Color:
	var colors: Array[Color] = FartConfig.current.colors
	var index: int = avatars[slots[seat].profile].toot if seat_control[seat] != "empty" else 0
	return colors[clampi(index, 0, colors.size() - 1)]

## Puffs per burst (quality setting). Changes every pooled emitter of every rider.
func set_puff_count(puffs: int) -> void:
	for pool: Array[CPUParticles3D] in burst_pools:
		for burst: CPUParticles3D in pool:
			burst.amount = maxi(puffs, 1)

## Presentation quality: Low skips droplet bursts and trims the big splash.
func set_effects_quality(low: bool) -> void:
	low_effects = low
	big_splash.amount = 10 if low else 22

## Fire one burst from `seat`'s rear, pointing away from the float centre.
func emit_burst(seat: int, pose: Transform3D) -> void:
	var idle_emitter: CPUParticles3D = null
	for burst: CPUParticles3D in burst_pools[seat]:
		if not burst.emitting:
			idle_emitter = burst
			break
	if idle_emitter == null:
		return # Hard cap reached: skip this burst rather than spawn more puffs.
	var config: FartConfig = FartConfig.current
	var outward: Vector3 = (pose.basis * orbit.visual_offset(seat, 1.0)).slide(Vector3.UP).normalized()
	var rear: Vector3 = pose * orbit.visual_offset(seat, SharedRingPreview.SEAT_RADIUS + 0.62, 0.55)
	idle_emitter.global_position = rear
	idle_emitter.direction = (outward + Vector3.UP * 0.4).normalized()
	# The cloud is blown back against the float's motion, so it streams behind and bends in turns.
	idle_emitter.gravity = Vector3(0, config.puff_rise, 0) - linear_velocity.slide(Vector3.UP) * config.puff_drag
	idle_emitter.restart()
	bursts_fired[seat] += 1
	visual.burst(seat, pose.basis.inverse() * outward)
	if config.splash and splash_height_valid:
		# Where the cloud pushes off the water: a foam ring and a few droplets.
		var turn: int = splash_turn[seat]
		splash_turn[seat] = 1 - turn
		var spot: Vector3 = rear + outward * 0.9
		var at: Vector3 = Vector3(spot.x, splash_height + 0.06, spot.z)
		var splash: CPUParticles3D = splashes[seat * 2 + turn]
		splash.global_position = at
		splash.restart()
		if not low_effects and config.splash_droplets > 0:
			var droplets: CPUParticles3D = droplet_pools[seat][turn]
			droplets.global_position = at
			droplets.restart()
	if config.burst_sound:
		Audio.play_sfx("attack", (0.91 + seat * 0.07) * (1.0 + visual_rng.randf_range(-config.sound_pitch_jitter, config.sound_pitch_jitter)))
	fart_burst.emit(seat)

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
	# Bursts already in the air finish and fade on their own; just stop new ones.
	burst_timers.fill(0.0)
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
			var force: Vector3 = direction * mass * profile.thrust_acceleration * FartConfig.current.push_scale * strength[index] * available / pow(float(occupied), 0.72)
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

## Big splash where the float hits the water (landing, bottom of a drop, falling in).
func splash_at(at: Vector3, strength: float) -> void:
	big_splash.global_position = at
	big_splash.initial_velocity_max = 3.0 + 3.0 * strength
	big_splash.restart()
	big_ring.global_position = at
	big_ring.restart()

func celebrate() -> void:
	celebrating = true

func _process(delta: float) -> void:
	var pose: Transform3D = get_global_transform_interpolated()
	var presenting: bool = simulate or (remote_replica and remote_playing)
	var to_local: Basis = pose.basis.inverse()
	if delta > 0.0:
		var acceleration: Vector3 = ((linear_velocity - last_velocity) / delta).limit_length(25.0)
		last_velocity = linear_velocity
		smoothed_acceleration = smoothed_acceleration.lerp(acceleration, 1.0 - exp(-8.0 * delta))
		# Split the float's acceleration into surge (along its motion) and turn (sideways):
		# riders lean back on surges and into turns, the float dips the other way.
		var planar: Vector3 = linear_velocity.slide(Vector3.UP)
		var flat: Vector3 = smoothed_acceleration.slide(Vector3.UP)
		var heading: Vector3 = planar.normalized() if planar.length() > 0.6 else Vector3.ZERO
		var surge_part: Vector3 = heading * flat.dot(heading)
		visual.set_float_motion(to_local * (-surge_part * 0.9 + (flat - surge_part) * 0.8))
	if contact_count != seen_contacts:
		if contact_count > seen_contacts and not falling:
			var hit: Vector3 = contact_direction if contact_direction.length_squared() > 0.01 else linear_velocity.slide(Vector3.UP)
			var from: Vector3 = to_local * hit.normalized() if hit.length_squared() > 0.01 else Vector3.ZERO
			visual.impact(from, clampf(linear_velocity.length() / 6.0, 0.5, 1.2))
		seen_contacts = contact_count
	visual.set_mood("panic" if falling else ("cheer" if celebrating else "ride"))
	visual.animate_riders(firing if presenting and not falling else quiet_firing, orbit_motion if presenting and not falling else quiet_motion, delta)
	var interval: float = 1.0 / maxf(FartConfig.current.burst_rate, 0.1)
	for index: int in range(MAX_RIDERS):
		# Only a seat that is really firing (its own input, its own gas) puffs.
		var live: bool = firing[index] and presenting and not falling
		var active: bool = live and held[index]
		if active != feedback_active[index]:
			feedback_active[index] = active
			if active:
				thrust_started.emit(index)
				burst_timers[index] = 0.0
			else:
				thrust_stopped.emit(index)
		if live:
			burst_timers[index] -= delta
			if burst_timers[index] <= 0.0:
				emit_burst(index, pose)
				burst_timers[index] = maxf(burst_timers[index] + interval, interval * 0.5)
		else:
			burst_timers[index] = 0.0
		tags[index].visible = seat_control[index] != "empty" and not falling
		tags[index].global_position = pose.origin + (pose.basis * orbit.visual_offset(index, SharedRingPreview.SEAT_RADIUS - 0.35)).slide(Vector3.UP) + Vector3.UP * 2.55
	if path != null:
		var at: Vector3 = pose.origin
		var frame: Dictionary = path.surface_at(at, route_s)
		ripple.visible = frame.valid and not falling and absf(at.y - frame.height) < 1.4
		if falling and not was_falling and splash_height_valid:
			splash_at(Vector3(at.x, splash_height + 0.05, at.z), 1.0)
		was_falling = falling
		splash_height = frame.height
		splash_height_valid = ripple.visible
		# Waves: the float dips toward the downhill side and bobs; plus its own motion dip.
		var wave: Vector3 = path.water_style.displacement(frame.s, frame.offset, path.water_time)
		var uphill: Vector3 = frame.tangent * wave.y + frame.lateral * wave.z
		visual.set_dip(to_local * (-smoothed_acceleration.slide(Vector3.UP) * 0.012 - uphill * 0.9), wave.x * 0.35 if ripple.visible else 0.0)
		if delta > 0.0:
			# Landings and the bottom of steep drops throw a big splash and bounce the crew.
			vertical_speed = lerpf(vertical_speed, (at.y - previous_height) / delta, 1.0 - exp(-20.0 * delta))
			previous_height = at.y
			var above: float = at.y - frame.height
			if vertical_speed < -3.0:
				descent = minf(descent, vertical_speed)
			if frame.valid and above > 0.75:
				airborne = true
			elif ripple.visible and presenting and ((airborne and above < 0.45) or (descent < -3.0 and vertical_speed > -0.8)):
				var strength: float = clampf(-minf(descent, vertical_speed) / 6.0, 0.3, 1.2)
				splash_at(Vector3(at.x, frame.height + 0.05, at.z), strength)
				visual.land(strength)
				airborne = false
				descent = 0.0
			if not ripple.visible:
				descent = 0.0
		ripple.global_transform = Transform3D(Basis.looking_at(frame.tangent, frame.normal), Vector3(at.x, frame.height + 0.04, at.z))
		var velocity: Vector3 = linear_velocity.slide(frame.normal)
		spray.global_position = Vector3(at.x, frame.height + 0.12, at.z) - velocity.normalized() * 2.3
		spray.direction = (-velocity.normalized() + Vector3.UP * 1.4).normalized()
		spray.emitting = ripple.visible and presenting and velocity.length() > 2.0
		wake.global_position = Vector3(at.x, frame.height + 0.05, at.z)
		wake.emitting = ripple.visible and presenting and velocity.length() > 1.2

func _on_contact(body: Node) -> void:
	# Presentation: remember which side was hit (a moving hazard, or the nearest bank).
	if body is AnimatableBody3D:
		contact_direction = ((body as Node3D).global_position - global_position).slide(Vector3.UP)
	elif path != null:
		var frame: Dictionary = path.project(global_position, route_s)
		contact_direction = frame.lateral * signf(frame.offset)
	contact_count += 1
	bumped.emit()
