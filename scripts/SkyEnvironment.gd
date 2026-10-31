class_name SkyEnvironment
extends RefCounted

static var water_material: ShaderMaterial
static var cliff_material: ShaderMaterial

static func water() -> ShaderMaterial:
	if water_material == null:
		water_material = ShaderMaterial.new()
		water_material.shader = preload("res://shaders/water.gdshader")
	return water_material

static func cliff() -> ShaderMaterial:
	if cliff_material == null:
		cliff_material = ShaderMaterial.new()
		cliff_material.shader = preload("res://shaders/cliff.gdshader")
	return cliff_material

static func install(parent: Node) -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "SkySun"
	sun.rotation_degrees = Vector3(-60, -30, 0)
	sun.light_energy = 0.5
	sun.shadow_enabled = false
	parent.add_child(sun)
	var world: WorldEnvironment = WorldEnvironment.new()
	world.name = "SkyEnvironment"
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky: Sky = Sky.new()
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = preload("res://shaders/sky.gdshader")
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.6
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = environment
	parent.add_child(world)
