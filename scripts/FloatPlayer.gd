class_name FloatPlayer
extends RigidBody3D

signal tooted(direction: Vector3)
signal popped
signal finished
signal bumped
signal fell
signal respawned

const MAX_GAS: int = 3
const REFILL_TIME: float = 1.5
const TOOT_IMPULSE: float = 9.0
const MAX_SPEED: float = 14.0
var gas: int = MAX_GAS
var is_local_controlled: bool = true
var controls_enabled: bool = true
var checkpoint: Vector3 = Vector3.ZERO
var refill_elapsed: float = 0.0
var avatar: Dictionary = AvatarData.default_avatar()
var model: AvatarModel
var trail: CPUParticles3D
var visual_time: float = 0.0
var pulse: float = 0.0
var bump_cooldown: float = 0.0
var falling: bool = false
var fall_elapsed: float = 0.0
var fall_velocity: Vector3 = Vector3.ZERO
var shadow: MeshInstance3D
const FALL_DURATION: float = 0.9

func _ready() -> void:
	gravity_scale = 0.0
	axis_lock_linear_y = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	linear_damp = 1.1
	angular_damp = 8.0
	continuous_cd = true
	collision_layer = 1
	collision_mask = 3
	contact_monitor = true
	max_contacts_reported = 4
	var physics_material: PhysicsMaterial = PhysicsMaterial.new()
	physics_material.bounce = 0.5
	physics_material.friction = 0.0
	physics_material_override = physics_material
	var shape: CollisionShape3D = CollisionShape3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.9
	shape.shape = sphere
	add_child(shape)
	model = preload("res://scenes/actors/AvatarModel.tscn").instantiate() as AvatarModel
	model.show_puff_preview = false
	add_child(model)
	model.apply(avatar)
	trail = RaceEffects.ripples()
	trail.position.y = 0.14
	add_child(trail)
	shadow = MeshInstance3D.new()
	var quad: PlaneMesh = PlaneMesh.new()
	quad.size = Vector2(2.8, 2.8)
	shadow.mesh = quad
	shadow.material_override = RaceEffects.ring_material(true)
	shadow.position.y = 0.09
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)
	body_entered.connect(_on_body_entered)

func toot_toward(world_point: Vector3) -> bool:
	if not controls_enabled or freeze or gas == 0 or not world_point.is_finite():
		return false
	var direction: Vector3 = world_point - global_position
	direction.y = 0
	if direction.length_squared() < 0.09:
		return false
	direction = direction.normalized()
	apply_central_impulse(direction * TOOT_IMPULSE)
	# The solver applies pending impulses before _integrate_forces caps velocity.
	# Writing linear_velocity here would overwrite an impulse not yet integrated.
	gas -= 1
	pulse = 1.0
	if is_inside_tree():
		RaceEffects.puff(get_parent_node_3d(), global_position - direction * 1.0 + Vector3.UP * 0.35, direction, avatar.toot)
		Audio.play_sfx("toot_%d" % randi_range(1, 4), randf_range(0.9, 1.15))
		if is_local_controlled and GameState.settings.get("vibration", true) and OS.has_feature("android"):
			Input.vibrate_handheld(30)
	tooted.emit(direction)
	return true

func add_gas(amount: int) -> void:
	gas = clampi(gas + amount, 0, MAX_GAS)
	if gas == MAX_GAS:
		refill_elapsed = 0.0

func advance_gas(delta: float) -> void:
	if gas == MAX_GAS:
		refill_elapsed = 0.0
		return
	refill_elapsed += delta
	while refill_elapsed >= REFILL_TIME and gas < MAX_GAS:
		refill_elapsed -= REFILL_TIME
		gas += 1
	if gas == MAX_GAS:
		refill_elapsed = 0.0

func _physics_process(delta: float) -> void:
	if falling:
		fall_elapsed += delta
		if fall_elapsed >= FALL_DURATION:
			respawn()
		return
	if not freeze:
		advance_gas(delta)
	bump_cooldown = maxf(0.0, bump_cooldown - delta)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	state.linear_velocity = state.linear_velocity.limit_length(MAX_SPEED)

func _process(delta: float) -> void:
	if model == null:
		return
	if falling:
		var t: float = minf(fall_elapsed / FALL_DURATION, 1.0)
		model.position = fall_velocity * fall_elapsed + Vector3(0, -10.0 * t * t, 0)
		model.scale = Vector3.ONE * lerpf(1.0, 0.3, t)
		return
	visual_time += delta
	pulse = move_toward(pulse, 0.0, delta * 4.0)
	model.position.y = 0.12 + sin(visual_time * 3.0) * 0.065
	model.scale = Vector3(1.0 + pulse * 0.13, 1.0 - pulse * 0.16, 1.0 + pulse * 0.13)
	if linear_velocity.length_squared() > 0.3:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(linear_velocity.x, linear_velocity.z), 1.0 - exp(-8.0 * delta))
	model.rotation.z = lerpf(model.rotation.z, -linear_velocity.x * 0.015, 1.0 - exp(-8.0 * delta))
	model.rotation.x = lerpf(model.rotation.x, -linear_velocity.z * 0.008, 1.0 - exp(-8.0 * delta))
	trail.emitting = not freeze and linear_velocity.length() > 1.5

func apply_avatar(data: Dictionary) -> void:
	avatar = AvatarData.sanitize(data)
	if model:
		model.apply(avatar)

func _on_body_entered(_body: Node) -> void:
	if linear_velocity.length() > 1.5 and bump_cooldown <= 0.0:
		bump_cooldown = 0.2
		pulse = 0.7
		bumped.emit()

func pop() -> void:
	# Spike/respawn behavior is added with the obstacles in Phase 3.
	popped.emit()

func fall_into_hole() -> bool:
	if falling or freeze or not controls_enabled:
		return false
	falling = true
	fall_elapsed = 0.0
	fall_velocity = linear_velocity * 0.2
	linear_velocity = Vector3.ZERO
	freeze = true
	controls_enabled = false
	trail.emitting = false
	trail.hide()
	shadow.hide()
	fell.emit()
	return true

func respawn() -> void:
	if not falling:
		return
	global_position = checkpoint + Vector3(0, 0, -3.0)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	cancel_fall()
	freeze = false
	sleeping = false
	controls_enabled = true
	reset_physics_interpolation()
	respawned.emit()

func cancel_fall() -> void:
	falling = false
	fall_elapsed = 0.0
	model.position = Vector3.ZERO
	model.scale = Vector3.ONE
	model.rotation = Vector3.ZERO
	trail.show()
	shadow.show()
