class_name RaceCamera
extends Camera3D

var target: FloatPlayer
var shake_amount: float = 0.0
var shake_time: float = 0.0
var follow_position: Vector3 = Vector3.ZERO
const OFFSET: Vector3 = Vector3(0, 13.5, 10.5)

func _ready() -> void:
	fov = 55.0
	far = 110.0
	current = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func snap_to_player() -> void:
	if target == null:
		return
	follow_position = target.global_position
	global_position = follow_position + OFFSET
	look_at(follow_position + Vector3(0, 0, -3.0))

func shake() -> void:
	shake_amount = 0.13

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var at: Vector3 = target.get_global_transform_interpolated().origin
	follow_position = follow_position.lerp(at, 1.0 - exp(-8.0 * delta))
	shake_time += delta * 55.0
	shake_amount = move_toward(shake_amount, 0, delta * 0.6)
	global_position = follow_position + OFFSET + Vector3(sin(shake_time), cos(shake_time * 1.3), 0) * shake_amount
	look_at(follow_position + Vector3(0, 0, -3.0))
