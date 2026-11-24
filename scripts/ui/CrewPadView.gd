extends RefCounted

# Pad layout/style only. Hit testing and physics consume these same rectangles.
var font: Font = preload("res://assets/fonts/Fredoka.ttf")
var panel: StyleBoxFlat = StyleBoxFlat.new()

func _init() -> void:
	panel.bg_color = Color(0.06, 0.22, 0.31, 0.90)
	panel.set_corner_radius_all(32)

func stick_rect(size: Vector2) -> Rect2:
	return Rect2(32, size.y - 252, 256, 210)

func gas_rect(size: Vector2) -> Rect2:
	return Rect2(size.x - 288, size.y - 252, 256, 210)

func draw(canvas: Control, stick: Vector2, firing: bool) -> void:
	var aim: Rect2 = stick_rect(canvas.size)
	var gas: Rect2 = gas_rect(canvas.size)
	for rect: Rect2 in [aim, gas]:
		canvas.draw_style_box(panel, rect)
	canvas.draw_circle(aim.get_center(), 69, Color("3b839f"))
	canvas.draw_circle(aim.get_center() + stick * 46, 28, Color("eafbff"))
	canvas.draw_string(font, aim.position + Vector2(0, 36), "AIM", HORIZONTAL_ALIGNMENT_CENTER, aim.size.x, 28, Color(1, 1, 1, 0.85))
	canvas.draw_circle(gas.get_center(), 65, Color("ffcf50") if firing else Color("7acb3b"))
	canvas.draw_string(font, Vector2(gas.position.x, gas.get_center().y + 11), "HOLD", HORIZONTAL_ALIGNMENT_CENTER, gas.size.x, 32, Color("183441"))
	canvas.draw_string(font, gas.position + Vector2(0, 36), "FART", HORIZONTAL_ALIGNMENT_CENTER, gas.size.x, 28, Color(1, 1, 1, 0.85))
