class_name RaceEffects
extends RefCounted

const PUFF_COLORS: Array[Color] = [Color("9be23a"), Color("a066e8"), Color("ff92d0"), Color("ffe04a")]
const PATTERN_SIZE: int = 128
static var puff_material: StandardMaterial3D
static var billboard_materials: Dictionary = {}
static var puff_quad: QuadMesh
static var pattern_texture: ImageTexture
static var drop_mesh: SphereMesh
static var foam_rings: Dictionary = {}

## Flat annulus (faces +Y) with the same UVs as a PlaneMesh of `size`, for the foam-ring
## shader. Only the visible band is rasterised: ~45% fewer pixels than a full quad, which
## matters on the phone GPU because wake and splash rings cover a lot of screen.
static func foam_ring_mesh(size: float) -> ArrayMesh:
	if not foam_rings.has(size):
		var builder: SurfaceTool = SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var segments: int = 28
		for index: int in range(segments):
			var a: float = TAU * index / segments
			var b: float = TAU * (index + 1) / segments
			var corners: Array[Vector2] = [Vector2(cos(a), sin(a)) * 0.27, Vector2(cos(a), sin(a)) * 0.5, Vector2(cos(b), sin(b)) * 0.5, Vector2(cos(b), sin(b)) * 0.27]
			for corner: int in [0, 2, 1, 0, 3, 2]:
				builder.set_uv(corners[corner] + Vector2(0.5, 0.5))
				builder.set_normal(Vector3.UP)
				builder.add_vertex(Vector3(corners[corner].x, 0.0, corners[corner].y) * size)
		builder.set_material(ring_material())
		foam_rings[size] = builder.commit()
	return foam_rings[size]

# Shaded cartoon puff (lumpy outline, lit top-left, darker underside), generated, no image file.
static func puff_texture(color: Color) -> ImageTexture:
	var size: int = 64
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var light: Vector3 = Vector3(-0.5, 0.62, 0.6).normalized()
	for y: int in range(size):
		for x: int in range(size):
			var p: Vector2 = Vector2((x + 0.5) / size * 2.0 - 1.0, (y + 0.5) / size * 2.0 - 1.0)
			var angle: float = atan2(p.y, p.x)
			var outline: float = 0.92 + 0.04 * sin(angle * 3.0 + 0.6) + 0.02 * sin(angle * 5.0 + 2.1)
			var r: float = p.length() / outline
			if r >= 1.0:
				image.set_pixel(x, y, Color(color, 0.0))
				continue
			var normal: Vector3 = Vector3(p.x / outline, -p.y / outline, sqrt(maxf(0.0, 1.0 - r * r))).normalized()
			var lit: float = clampf(normal.dot(light), 0.0, 1.0)
			# Soft round shading with a gentle highlight: reads as a fluffy cloud, not a flat disc.
			var shade: float = lerpf(0.76, 1.0, smoothstep(-0.1, 0.65, lit)) + 0.12 * pow(lit, 8.0)
			var tone: Color = Color(color.r * shade, color.g * shade, color.b * shade).lerp(Color.WHITE, 0.25 * pow(lit, 5.0))
			image.set_pixel(x, y, Color(tone, 1.0 - smoothstep(0.55, 1.0, r)))
	return ImageTexture.create_from_image(image)

## Camera-facing, semi-transparent, unlit puff material (one per gas colour).
static func puff_billboard(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html()
	if not billboard_materials.has(key):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		material.billboard_keep_scale = true
		material.vertex_color_use_as_albedo = true
		material.albedo_texture = puff_texture(color)
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		billboard_materials[key] = material
	return billboard_materials[key]

## One burst emitter: a few soft puffs that start small, swell 2-3x, merge, drift up and fade out.
static func fart_burst_emitter(color: Color, config: FartConfig, puffs: int) -> CPUParticles3D:
	var burst: CPUParticles3D = CPUParticles3D.new()
	burst.emitting = false
	burst.one_shot = true
	burst.explosiveness = 0.82
	burst.randomness = 0.4
	burst.amount = maxi(puffs, 1)
	burst.lifetime = config.puff_lifetime
	burst.local_coords = false
	burst.draw_order = CPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	burst.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	burst.emission_sphere_radius = 0.25
	burst.spread = 34.0
	burst.initial_velocity_min = config.puff_speed_min
	burst.initial_velocity_max = config.puff_speed_max
	burst.damping_min = 2.2
	burst.damping_max = 3.4
	burst.gravity = Vector3(0, config.puff_rise, 0)
	burst.scale_amount_min = config.puff_size_min
	burst.scale_amount_max = config.puff_size_max
	var swell: Curve = Curve.new()
	swell.add_point(Vector2(0.0, 1.0 / maxf(config.puff_growth, 1.0)))
	swell.add_point(Vector2(0.22, 0.86))
	swell.add_point(Vector2(1.0, 1.1))
	burst.scale_amount_curve = swell
	var fade: Gradient = Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.10, 0.55, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, config.puff_alpha), Color(1, 1, 1, config.puff_alpha * 0.75), Color(1, 1, 1, 0.0)])
	burst.color_ramp = fade
	if puff_quad == null:
		puff_quad = QuadMesh.new()
		puff_quad.size = Vector2.ONE
	var quad: QuadMesh = puff_quad.duplicate()
	quad.material = puff_billboard(color)
	burst.mesh = quad
	burst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return burst

static func set_burst_color(burst: CPUParticles3D, color: Color) -> void:
	(burst.mesh as QuadMesh).material = puff_billboard(color)

## Small one-shot foam ring where the gas cloud meets the water.
static func splash_ring() -> CPUParticles3D:
	var splash: CPUParticles3D = ripples()
	splash.one_shot = true
	splash.explosiveness = 0.75
	splash.amount = 2
	splash.lifetime = 0.8
	var growth: Curve = Curve.new()
	growth.add_point(Vector2(0, 0.35))
	growth.add_point(Vector2(1, 1.25))
	splash.scale_amount_curve = growth
	splash.mesh = foam_ring_mesh(2.2)
	return splash

## Water droplets thrown up by a burst, a landing or a drop (cheap shared low-poly spheres).
static func droplets(amount: int, speed: float = 3.6) -> CPUParticles3D:
	var particles: CPUParticles3D = CPUParticles3D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = maxi(amount, 1)
	particles.lifetime = 0.6
	particles.local_coords = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.45
	particles.direction = Vector3.UP
	particles.spread = 42.0
	particles.initial_velocity_min = speed * 0.65
	particles.initial_velocity_max = speed * 1.25
	particles.gravity = Vector3(0, -14, 0)
	particles.scale_amount_min = 0.09
	particles.scale_amount_max = 0.19
	var shrink: Curve = Curve.new()
	shrink.add_point(Vector2(0, 1.0))
	shrink.add_point(Vector2(1, 0.35))
	particles.scale_amount_curve = shrink
	particles.mesh = droplet_mesh()
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles

## Shared bright, unlit low-poly droplet.
static func droplet_mesh() -> SphereMesh:
	if drop_mesh == null:
		drop_mesh = SphereMesh.new()
		drop_mesh.radial_segments = 6
		drop_mesh.rings = 3
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("e4fbff")
		drop_mesh.material = material
	return drop_mesh

# Expanding white foam rings left behind on the water.
static func wake_rings() -> CPUParticles3D:
	var particles: CPUParticles3D = ripples()
	particles.amount = 8
	particles.lifetime = 1.6
	var growth: Curve = Curve.new()
	growth.add_point(Vector2(0, 0.6))
	growth.add_point(Vector2(1, 1.75))
	particles.scale_amount_curve = growth
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 1.0
	var fade: Gradient = Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 1, 0.95), Color(1, 1, 1, 0)])
	particles.color_ramp = fade
	particles.mesh = foam_ring_mesh(4.8)
	return particles
static var ripple_material: ShaderMaterial
static var shadow_material: ShaderMaterial

static func ring_material(shadow: bool = false) -> ShaderMaterial:
	if shadow and shadow_material:
		return shadow_material
	if not shadow and ripple_material:
		return ripple_material
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://shaders/ring.gdshader")
	material.set_shader_parameter("tint", Color(0.03, 0.13, 0.18, 0.20) if shadow else Color(1, 1, 1, 0.8))
	material.set_shader_parameter("filled", shadow)
	material.set_shader_parameter("wobble", 0.0 if shadow else 1.0)
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
	particles.mesh = foam_ring_mesh(2.8)
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles

## Tiling water pattern, built once from math (no image file). Smooth fields, so the
## water shader can sharpen them with smoothstep at any distance:
## R caustic web, G downstream flow streaks (across = x, along = y), B foam noise, A sparkle dots.
static func water_pattern() -> ImageTexture:
	if pattern_texture != null:
		return pattern_texture
	var size: int = PATTERN_SIZE
	var data: PackedByteArray = PackedByteArray()
	data.resize(size * size * 4)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 85
	# Nine streak lanes across the tile; each has its own dash rhythm down the flow.
	# Lanes never overlap, so each column only needs its nearest lane.
	var lane_count: int = 9
	var lane_of: PackedInt32Array = PackedInt32Array()
	var ridge_of: PackedFloat32Array = PackedFloat32Array()
	var dash_of: PackedFloat32Array = PackedFloat32Array()
	var centres: PackedFloat32Array = PackedFloat32Array()
	for lane: int in range(lane_count):
		centres.append((lane + rng.randf_range(0.2, 0.8)) / lane_count)
		var frequency: float = float(rng.randi_range(1, 3))
		var phase: float = rng.randf()
		var fill: float = rng.randf_range(0.25, 0.6)
		for y: int in range(size):
			dash_of.append(clampf((0.5 + 0.5 * cos(TAU * (float(y) / size * frequency + phase)) - (1.0 - fill)) / fill, 0.0, 1.0))
	for x: int in range(size):
		var best: int = 0
		var nearest: float = 1.0
		for lane: int in range(lane_count):
			var across: float = absf(fposmod(float(x) / size - centres[lane] + 0.5, 1.0) - 0.5)
			if across < nearest:
				nearest = across
				best = lane
		lane_of.append(best)
		ridge_of.append(clampf(1.0 - nearest * lane_count * 3.2, 0.0, 1.0))
	var dots: Array[Vector2] = []
	for dot: int in range(46):
		dots.append(Vector2(rng.randf() * size, rng.randf() * size))
	for y: int in range(size):
		var v: float = float(y) / size
		var q: float = v * TAU
		var warp_v: float = 1.3 * sin(3.0 * q) + 0.4
		var foam_v: float = sin(3.0 * q)
		for x: int in range(size):
			var u: float = float(x) / size
			var p: float = u * TAU
			var w1: float = absf(sin(2.0 * p + warp_v))
			var w2: float = absf(sin(2.0 * q + 1.2 * sin(3.0 * p + 1.7)))
			var w3: float = absf(sin(3.0 * p + 3.0 * q + 0.9 * sin(2.0 * p - q)))
			var web: float = 1.0 - minf(w1, minf(w2, w3))
			var streak: float = ridge_of[x] * dash_of[lane_of[x] * size + y]
			var foam: float = 0.5 + 0.2 * sin(2.0 * p + foam_v) + 0.15 * sin(5.0 * q + 1.3 + 0.8 * sin(4.0 * p)) + 0.15 * sin(7.0 * p + 3.0 * q + 0.5)
			var index: int = (y * size + x) * 4
			data[index] = int(clampf(web, 0.0, 1.0) * 255.0)
			data[index + 1] = int(streak * 255.0)
			data[index + 2] = int(clampf(foam, 0.0, 1.0) * 255.0)
			data[index + 3] = 0
	for dot: Vector2 in dots:
		for dy: int in range(-3, 4):
			for dx: int in range(-3, 4):
				var px: int = posmod(int(dot.x) + dx, size)
				var py: int = posmod(int(dot.y) + dy, size)
				var value: int = int(clampf(1.0 - Vector2(dx, dy).length() / 3.2, 0.0, 1.0) * 255.0)
				var index: int = (py * size + px) * 4 + 3
				data[index] = maxi(data[index], value)
	var image: Image = Image.create_from_data(size, size, false, Image.FORMAT_RGBA8, data)
	image.generate_mipmaps()
	pattern_texture = ImageTexture.create_from_image(image)
	return pattern_texture
