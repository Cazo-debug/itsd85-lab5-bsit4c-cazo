class_name RaceCamera
extends Camera3D

var target: FloatPlayer
var shake_amount: float = 0.0
var shake_time: float = 0.0
var follow_position: Vector3 = Vector3.ZERO
var look_position: Vector3 = Vector3.ZERO
var overview: bool = false

func _ready() -> void:
	fov = 55.0
	near = 0.5
	far = 800.0
	current = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func play_position(at: Vector3) -> Vector3:
	return Vector3(at.x * 0.85, 14.0, at.z + 12.0)

func play_look(at: Vector3) -> Vector3:
	return Vector3(at.x * 0.9, 0, at.z - 7.0)

func snap_to_player() -> void:
	if target == null:
		return
	follow_position = target.global_position
	global_position = play_position(follow_position)
	look_position = play_look(follow_position)
	look_at(look_position)

func show_overview(length: float) -> void:
	overview = true
	global_position = Vector3(0, length * 1.12 + 24, -length * 0.3)
	look_position = Vector3(0, 0, -length * 0.5)
	look_at(look_position)

func shake() -> void:
	shake_amount = 0.13

func _process(delta: float) -> void:
	if not is_instance_valid(target) or overview:
		return
	var at: Vector3 = target.get_global_transform_interpolated().origin
	var blend: float = 1.0 - exp(-4.5 * delta)
	follow_position = at
	shake_time += delta * 55.0
	shake_amount = move_toward(shake_amount, 0, delta * 1.6)
	global_position = global_position.lerp(play_position(at), blend)
	look_position = look_position.lerp(play_look(at), blend)
	look_at(look_position)
	h_offset = sin(shake_time) * shake_amount
	v_offset = cos(shake_time * 1.3) * shake_amount
