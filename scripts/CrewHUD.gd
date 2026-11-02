class_name CrewHUD
extends CanvasLayer

signal back_requested
signal pause_requested
signal reset_requested
var controls: CrewInput
var root: Control
var timer_label: Label
var progress: ProgressBar
var banner: Label
var hint: Label
var seats: Array[Label] = []
var pause_button: Button
var reset_button: Button

func make_label(text: String, font_size: int = 28) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func make_button(text: String, callback: Callable, parent: Node) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 120)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = preload("res://assets/GameTheme.tres")
	add_child(root)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_top", 88)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	root.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	var row: HBoxContainer = HBoxContainer.new()
	box.add_child(row)
	make_button("Back", back_requested.emit, row)
	pause_button = make_button("Pause", pause_requested.emit, row)
	reset_button = make_button("Recover", reset_requested.emit, row)
	timer_label = make_label("Sky Garden", 32)
	box.add_child(timer_label)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 14
	progress.show_percentage = false
	box.add_child(progress)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	box.add_child(grid)
	for index: int in range(4):
		var seat: Label = make_label("")
		seat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seat.clip_text = true
		grid.add_child(seat)
		seats.append(seat)
	banner = make_label("SKY GARDEN", 46)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	banner.offset_left = -320
	banner.offset_right = 320
	banner.offset_top = -100
	banner.offset_bottom = 90
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(banner)
	hint = make_label("Aim + hold to fart\nWASD + Space on desktop", 28)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -340
	hint.offset_bottom = -264
	root.add_child(hint)
	controls = CrewInput.new()
	root.add_child(controls)

func update_status(ring: SwimRing, time: float, section: String, practice: bool) -> void:
	timer_label.text = "%s / %s" % [section, "Practice" if practice else "%d s" % ceili(time)]
	progress.value = ring.route_s / ring.path.length * 100
	for index: int in range(4):
		if ring.seat_control[index] == "empty":
			seats[index].text = "%d Empty" % (index + 1)
		else:
			var title: String = ring.avatars[ring.slots[index].profile].name
			seats[index].text = "%d %s %d%%" % [index + 1, title, roundi(ring.gas[index] * 100)]
			seats[index].modulate = Color("ffcf50") if ring.firing[index] else Color.WHITE
