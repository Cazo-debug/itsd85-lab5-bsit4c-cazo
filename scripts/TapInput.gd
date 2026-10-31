class_name TapInput
extends Node

var player: FloatPlayer
var camera: Camera3D
var enabled: bool = false

func point_on_water(screen_point: Vector2) -> Variant:
	if camera == null:
		return null
	var ray_origin: Vector3 = camera.project_ray_origin(screen_point)
	var ray_direction: Vector3 = camera.project_ray_normal(screen_point)
	return Plane(Vector3.UP, 0.0).intersects_ray(ray_origin, ray_direction)

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or player == null or camera == null:
		return
	# Mouse presses become ScreenTouch events through the project setting.
	# Handling both would spend two charges for a single click.
	if event is InputEventScreenTouch and event.pressed:
		var target: Variant = point_on_water(event.position)
		if target is Vector3:
			player.toot_toward(target)
		get_viewport().set_input_as_handled()
