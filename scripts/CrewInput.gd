class_name CrewInput
extends Control

var ring: SwimRing
var camera: Camera3D
var active_seat: int = 0
var enabled: bool = false
var stick_id: int = -1
var gas_id: int = -1
var stick: Vector2 = Vector2(0, -1)
var keyboard_armed: bool = true
var last_keyboard_fire: Array[bool] = [false, false, false, false]
const KEYS: Array = [[KEY_A, KEY_D, KEY_W, KEY_S, KEY_SPACE], [KEY_J, KEY_L, KEY_I, KEY_K, KEY_U], [KEY_F, KEY_H, KEY_T, KEY_G, KEY_R], [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_ENTER]]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func stick_rect() -> Rect2:
	return Rect2(32, size.y - 252, 256, 210)

func gas_rect() -> Rect2:
	return Rect2(size.x - 288, size.y - 252, 256, 210)

func clear() -> void:
	stick_id = -1
	gas_id = -1
	keyboard_armed = false
	last_keyboard_fire = [false, false, false, false]
	if ring:
		ring.release_all_inputs()
	queue_redraw()

func world_direction(value: Vector2) -> Vector3:
	var right: Vector3 = camera.global_basis.x
	var forward: Vector3 = -camera.global_basis.z
	right.y = 0
	forward.y = 0
	return (right.normalized() * value.x - forward.normalized() * value.y).normalized()

func handle_touch(index: int, point: Vector2, pressed: bool) -> void:
	if not pressed:
		if index == stick_id:
			stick_id = -1
		if index == gas_id:
			gas_id = -1
			if ring:
				ring.set_thrust_input(active_seat, Vector3.ZERO, 0, false)
		queue_redraw()
		return
	if not enabled or ring == null or not ring.simulate or ring.falling:
		return
	if stick_rect().has_point(point) and stick_id < 0:
		stick_id = index
		stick = ((point - stick_rect().get_center()) / 80.0).limit_length(1.0)
	elif gas_rect().has_point(point) and gas_id < 0:
		gas_id = index
	queue_redraw()

func handle_drag(index: int, point: Vector2) -> void:
	if index == stick_id:
		stick = ((point - stick_rect().get_center()) / 80.0).limit_length(1.0)
	if index == gas_id and not gas_rect().has_point(point):
		handle_touch(index, point, false)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var owned: bool = event.index in [stick_id, gas_id] or stick_rect().has_point(event.position) or gas_rect().has_point(event.position)
		handle_touch(event.index, event.position, event.pressed)
		if owned:
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		handle_drag(event.index, event.position)
	elif not Input.emulate_touch_from_mouse and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		handle_touch(100, event.position, event.pressed)
	elif not Input.emulate_touch_from_mouse and event is InputEventMouseMotion:
		handle_drag(100, event.position)

func _physics_process(_delta: float) -> void:
	if ring == null or not enabled or not ring.simulate or ring.falling:
		return
	var any_fire: bool = false
	for keys: Array in KEYS:
		any_fire = any_fire or Input.is_physical_key_pressed(keys[4])
	if not any_fire:
		keyboard_armed = true
	for binding: int in range(4):
		var seat: int = active_seat if binding == 0 else binding
		if ring.seat_control[seat] != "local" or (binding > 0 and seat == active_seat):
			continue
		var keys: Array = KEYS[binding]
		var value: Vector2 = Vector2(float(Input.is_physical_key_pressed(keys[1])) - float(Input.is_physical_key_pressed(keys[0])), float(Input.is_physical_key_pressed(keys[3])) - float(Input.is_physical_key_pressed(keys[2])))
		var pressed: bool = keyboard_armed and Input.is_physical_key_pressed(keys[4])
		if binding == 0:
			if value.length_squared() > 0:
				stick = value.normalized()
			var mouse_aim: Vector3 = world_direction(stick)
			ring.set_thrust_input(seat, mouse_aim, stick.length(), (pressed or gas_id >= 0) and stick.length() >= 0.15)
		elif pressed or last_keyboard_fire[binding]:
			ring.set_thrust_input(seat, world_direction(value if value.length_squared() > 0 else Vector2(0, -1)), 1.0, pressed)
		last_keyboard_fire[binding] = pressed
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		clear()

func _draw() -> void:
	var font: Font = preload("res://assets/fonts/Fredoka.ttf")
	for rect: Rect2 in [stick_rect(), gas_rect()]:
		draw_style_box(panel_style(Color(0.06, 0.22, 0.31, 0.90)), rect)
	draw_circle(stick_rect().get_center(), 69, Color("3b839f"))
	draw_circle(stick_rect().get_center() + stick * 46, 28, Color("eafbff"))
	draw_string(font, stick_rect().position + Vector2(68, 34), "AIM", HORIZONTAL_ALIGNMENT_LEFT, -1, 28)
	draw_circle(gas_rect().get_center(), 65, Color("ffcf50") if gas_id >= 0 else Color("7acb3b"))
	draw_string(font, gas_rect().get_center() + Vector2(-49, 10), "HOLD", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("183441"))
	draw_string(font, gas_rect().position + Vector2(55, 34), "TO FART", HORIZONTAL_ALIGNMENT_LEFT, -1, 28)

func panel_style(color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(32)
	return style
