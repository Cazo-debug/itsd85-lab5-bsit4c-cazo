class_name RaceHUD
extends CanvasLayer

signal back_requested
var root: Control
var timer_label: Label
var goal_label: Label
var big_goal: Label
var countdown_label: Label
var hint_label: Label
var hint_arrow: Label
var gas_icons: Array[GasIcon] = []
var progress: RaceProgress
var hint_time: float = 0.0

class GasIcon:
	extends Control
	var full: bool = true
	func _draw() -> void:
		var color: Color = Color("ffcf50") if full else Color(0.06, 0.30, 0.38, 0.45)
		draw_style_box(bean_style(Color("69412d")), Rect2(Vector2(3, 4), size - Vector2(6, 8)))
		draw_style_box(bean_style(color), Rect2(Vector2(6, 5), size - Vector2(12, 14)))
	func bean_style(color: Color) -> StyleBoxFlat:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(18)
		return style

class RaceProgress:
	extends Control
	var ratio: float = 0.0
	func _draw() -> void:
		var start: Vector2 = Vector2(16, size.y / 2.0)
		var end: Vector2 = Vector2(size.x - 16, size.y / 2.0)
		draw_line(start, end, Color("15556c"), 12, true)
		draw_line(start, start.lerp(end, ratio), Color("7acb3b"), 12, true)
		draw_circle(start.lerp(end, ratio), 13.0, Color.WHITE)
		draw_circle(end, 8, Color("ffcf50"))

func text(value: String, font_size: int = 32) -> Label:
	var item: Label = Label.new()
	item.text = value
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_font_size_override("font_size", font_size)
	return item

func _ready() -> void:
	root = Control.new()
	root.theme = preload("res://assets/GameTheme.tres")
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var top: MarginContainer = MarginContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 88
	top.offset_left = 24
	top.offset_right = -24
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 10)
	top.add_child(stack)
	var header: HBoxContainer = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(header)
	var back: Button = Button.new()
	back.name = "Back"
	back.text = "Back"
	back.custom_minimum_size = Vector2(120, 120)
	back.pressed.connect(func() -> void: back_requested.emit())
	header.add_child(back)
	timer_label = text("75", 54)
	timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(timer_label)
	var pause: Button = Button.new()
	pause.text = "Ⅱ"
	pause.name = "Pause"
	pause.custom_minimum_size = Vector2(120, 120)
	pause.disabled = true
	pause.add_theme_stylebox_override("disabled", preload("res://assets/GameTheme.tres").get_stylebox("normal", "Button"))
	header.add_child(pause)
	goal_label = text("Lazy River", 28)
	stack.add_child(goal_label)
	var gas_row: HBoxContainer = HBoxContainer.new()
	gas_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gas_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_child(gas_row)
	var gas_text: Label = text("GAS", 28)
	gas_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	gas_text.custom_minimum_size = Vector2(75, 48)
	gas_row.add_child(gas_text)
	for index: int in range(3):
		var icon: GasIcon = GasIcon.new()
		icon.custom_minimum_size = Vector2(46, 48)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gas_icons.append(icon)
		gas_row.add_child(icon)
	progress = RaceProgress.new()
	progress.custom_minimum_size.y = 32
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(progress)
	big_goal = text("", 40)
	big_goal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	big_goal.offset_left = -310
	big_goal.offset_right = 310
	big_goal.offset_top = -210
	big_goal.offset_bottom = -30
	root.add_child(big_goal)
	countdown_label = text("3", 110)
	countdown_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	countdown_label.offset_left = -300
	countdown_label.offset_right = 300
	countdown_label.offset_top = -80
	countdown_label.offset_bottom = 70
	root.add_child(countdown_label)
	hint_label = text("Tap the water to toot that way!", 32)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_left = 32
	hint_label.offset_right = -32
	hint_label.offset_top = -150
	hint_label.offset_bottom = -40
	root.add_child(hint_label)
	hint_arrow = text("↑", 64)
	hint_arrow.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hint_arrow.offset_left = -50
	hint_arrow.offset_right = 50
	hint_arrow.offset_top = 150
	hint_arrow.offset_bottom = 240
	root.add_child(hint_arrow)

func update_race(time_left: float, gas: int, ratio: float, racing: bool) -> void:
	timer_label.text = "%02d" % ceili(maxf(time_left, 0.0))
	timer_label.add_theme_color_override("font_color", Color("ff625d") if time_left < 10.0 else Color.WHITE)
	for index: int in range(gas_icons.size()):
		gas_icons[index].full = index < gas
		gas_icons[index].queue_redraw()
	progress.ratio = clampf(ratio, 0.0, 1.0)
	progress.queue_redraw()
	if not racing:
		hint_arrow.hide()

func _process(delta: float) -> void:
	hint_time += delta
	if hint_arrow:
		hint_arrow.position.y += sin(hint_time * 4.0) * delta * 22.0
