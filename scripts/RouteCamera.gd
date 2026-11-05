class_name RouteCamera
extends Camera3D

var ring: SwimRing
var path: CoursePath
var overview: bool = true
var look_position: Vector3
var heading: Vector3 = Vector3.FORWARD

func _ready() -> void:
	current = true
	fov = 58
	near = 0.3
	far = 650
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	show_overview()

func show_overview() -> void:
	overview = true
	var bounds: AABB = AABB(path.frames[0].position, Vector3.ZERO)
	for frame: Dictionary in path.frames:
		bounds = bounds.expand(frame.position)
	look_position = bounds.get_center()
	var span: float = maxf(bounds.size.x * 1.7, bounds.size.z)
	position = look_position + Vector3(0, span * 1.15, span * 0.8)
	look_at(look_position)

func snap() -> void:
	var frame: Dictionary = path.sample(ring.route_s)
	heading = frame.tangent.slide(Vector3.UP).normalized()
	position = ring.position - heading * 14 + Vector3.UP * 18
	look_position = ring.position + heading * 6
	look_at(look_position)

func _process(delta: float) -> void:
	if overview or ring == null:
		return
	var frame: Dictionary = path.sample(ring.route_s + 5)
	var tangent: Vector3 = frame.tangent.slide(Vector3.UP).normalized()
	heading = heading.slerp(tangent, 1.0 - exp(-2.8 * delta)).normalized()
	var at: Vector3 = ring.get_global_transform_interpolated().origin
	# Keep the camera above the route during a fall so the drop stays visible.
	var camera_base: Vector3 = Vector3(at.x, maxf(at.y, frame.position.y), at.z)
	var target: Vector3 = camera_base - heading * 14 + Vector3.UP * 18
	position = position.lerp(target, 1.0 - exp(-5.0 * delta))
	look_position = look_position.lerp(camera_base + heading * 6, 1.0 - exp(-5.5 * delta))
	look_at(look_position)
