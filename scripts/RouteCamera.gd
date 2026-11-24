class_name RouteCamera
extends Camera3D

var ring: SwimRing
var path: CoursePath
var overview: bool = true
var look_position: Vector3
var heading: Vector3 = Vector3.FORWARD
var reduced_motion: bool = true
var kick_amount: float = 0.0
var kick_clock: float = 0.0
## After a shared finish the camera swings in front of the crew and frames the
## cheering riders in the upper half, above the result card.
var celebrating: bool = false

func celebrate() -> void:
	celebrating = true

## Light shake on a fart burst; Reduced Motion (the default) turns it off.
func kick(_seat: int = 0) -> void:
	if not reduced_motion:
		kick_amount = maxf(kick_amount, FartConfig.current.camera_kick)

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

# Low chase view close behind the crew, so the animals and farts read large on a phone.
const BACK: float = 11.5
const HEIGHT: float = 9.0
const AHEAD: float = 2.5

func snap() -> void:
	var frame: Dictionary = path.sample(ring.route_s)
	heading = frame.tangent.slide(Vector3.UP).normalized()
	position = ring.position - heading * BACK + Vector3.UP * HEIGHT
	look_position = ring.position + heading * AHEAD + Vector3.UP
	look_at(look_position)

func _process(delta: float) -> void:
	if overview or ring == null:
		return
	if celebrating:
		var crew: Vector3 = ring.get_global_transform_interpolated().origin
		var side: Vector3 = heading.cross(Vector3.UP).normalized()
		position = position.lerp(crew + heading * 13.5 + side * 3.0 + Vector3.UP * 8.5, 1.0 - exp(-2.4 * delta))
		look_position = look_position.lerp(crew - Vector3.UP * 2.6, 1.0 - exp(-3.0 * delta))
		look_at(look_position)
		h_offset = 0.0
		v_offset = 0.0
		return
	var frame: Dictionary = path.sample(ring.route_s + 5)
	var tangent: Vector3 = frame.tangent.slide(Vector3.UP).normalized()
	# No impact shake. Reduced motion also softens yaw at tight bends.
	heading = heading.slerp(tangent, 1.0 - exp(-(1.8 if reduced_motion else 2.8) * delta)).normalized()
	var at: Vector3 = ring.get_global_transform_interpolated().origin
	# Keep the camera above the route during a fall so the drop stays visible.
	var camera_base: Vector3 = Vector3(at.x, maxf(at.y, frame.position.y), at.z)
	var target: Vector3 = camera_base - heading * BACK + Vector3.UP * HEIGHT
	position = position.lerp(target, 1.0 - exp(-5.0 * delta))
	look_position = look_position.lerp(camera_base + heading * AHEAD + Vector3.UP, 1.0 - exp(-5.5 * delta))
	look_at(look_position)
	kick_clock += delta * 48.0
	kick_amount = move_toward(kick_amount, 0.0, delta * 0.5)
	h_offset = sin(kick_clock) * kick_amount
	v_offset = cos(kick_clock * 1.3) * kick_amount
