class_name RaceEffects
extends RefCounted

const PUFF_COLORS: Array[Color] = [Color("68cb43"), Color("723ca8"), Color("f29cce"), Color("ffe76c")]
static var puff_material: StandardMaterial3D
static var ripple_material: ShaderMaterial
static var shadow_material: ShaderMaterial

static func ring_material(shadow: bool = false) -> ShaderMaterial:
	if shadow and shadow_material:
		return shadow_material
	if not shadow and ripple_material:
		return ripple_material
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://shaders/ring.gdshader")
	material.set_shader_parameter("tint", Color(0.03, 0.13, 0.18, 0.20) if shadow else Color(1, 1, 1, 0.7))
	material.set_shader_parameter("filled", shadow)
	if shadow:
		shadow_material = material
	else:
		ripple_material = material
	return material

static func puff(parent: Node3D, at: Vector3, direction: Vector3, color_index: int) -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.emitting = false
	particles.amount = 14
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.7
	particles.local_coords = false
	particles.direction = -direction + Vector3.UP * 0.25
	particles.spread = 35.0
	particles.gravity = Vector3(0, 0.55, 0)
	particles.initial_velocity_min = 1.4
	particles.initial_velocity_max = 3.0
	particles.scale_amount_min = 0.22
	particles.scale_amount_max = 0.5
	var fade: Gradient = Gradient.new()
	var color: Color = PUFF_COLORS[clampi(color_index, 0, 3)]
	fade.colors = PackedColorArray([color, Color(color, 0.0)])
	particles.color_ramp = fade
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 4
	if puff_material == null:
		puff_material = StandardMaterial3D.new()
		puff_material.vertex_color_use_as_albedo = true
		puff_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		puff_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = puff_material
	particles.mesh = mesh
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(particles)
	particles.global_position = at
	particles.finished.connect(particles.queue_free)
	particles.emitting = true
	return particles

static func ripples() -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.emitting = false
	particles.amount = 6
	particles.lifetime = 0.8
	particles.local_coords = false
	particles.gravity = Vector3.ZERO
	particles.direction = Vector3.UP
	particles.initial_velocity_min = 0.0
	particles.initial_velocity_max = 0.0
	particles.scale_amount_min = 0.65
	particles.scale_amount_max = 0.65
	var growth: Curve = Curve.new()
	growth.add_point(Vector2(0, 0.45))
	growth.add_point(Vector2(1, 1.0))
	particles.scale_amount_curve = growth
	var fade: Gradient = Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	particles.color_ramp = fade
	var mesh: PlaneMesh = PlaneMesh.new()
	mesh.size = Vector2(2.8, 2.8)
	mesh.material = ring_material()
	particles.mesh = mesh
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles
