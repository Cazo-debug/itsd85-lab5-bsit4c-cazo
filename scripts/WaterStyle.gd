class_name WaterStyle
extends Resource

# One profile drives shading and the support surface in every course.
@export var deep_color: Color = Color("087eaa")
@export var shallow_color: Color = Color("3ed8d5")
@export var foam_color: Color = Color("ecffff")
@export var wave_amplitude: float = 0.10
@export var wave_a: Vector4 = Vector4(0.70, 0.18, 1.8, 1.0)
@export var wave_b: Vector4 = Vector4(1.10, -0.35, -1.2, 0.45)

func displacement(distance: float, lateral: float, time: float) -> Vector3:
	var a: float = distance * wave_a.x + lateral * wave_a.y - time * wave_a.z
	var b: float = distance * wave_b.x + lateral * wave_b.y - time * wave_b.z
	return Vector3(
		wave_amplitude * (sin(a) * wave_a.w + sin(b) * wave_b.w),
		wave_amplitude * (cos(a) * wave_a.w * wave_a.x + cos(b) * wave_b.w * wave_b.x),
		wave_amplitude * (cos(a) * wave_a.w * wave_a.y + cos(b) * wave_b.w * wave_b.y))

func apply_to(material: ShaderMaterial) -> void:
	material.set_shader_parameter("deep_color", deep_color)
	material.set_shader_parameter("shallow_color", shallow_color)
	material.set_shader_parameter("foam_color", foam_color)
	material.set_shader_parameter("wave_amplitude", wave_amplitude)
	material.set_shader_parameter("wave_a", wave_a)
	material.set_shader_parameter("wave_b", wave_b)
