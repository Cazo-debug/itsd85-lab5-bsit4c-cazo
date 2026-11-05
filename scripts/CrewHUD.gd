class_name CrewHUD
extends CanvasLayer

signal back_requested
signal pause_requested
signal reset_requested
signal action_requested(action: String)
var controls: CrewInput
var root: Control
var timer_label: Label
var progress: ProgressBar
var banner: Label
var hint: Label
var seats: Array[Label] = []
var pause_button: Button
var reset_button: Button
var panels: RunPanels
var panel_key: String = ""

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
	panels = RunPanels.new()
	root.add_child(panels)
	panels.action_requested.connect(action_requested.emit)

func invalidate_panels() -> void:
	panel_key = ""

# This is the stable view contract: UI reads a detached snapshot, never a body/save.
func present(view: Dictionary) -> void:
	timer_label.text = "%s / %s" % [view.section, "Practice" if view.practice else "%d s" % ceili(view.time_left)]
	timer_label.modulate = Color("ff8b94") if not view.practice and view.time_left < 10 else Color.WHITE
	progress.value = view.progress * 100
	hint.text = view.hint + "\nAIM + HOLD / WASD + Space"
	hint.visible = view.state not in ["PAUSED", "FINISHED"]
	controls.visible = view.state not in ["PAUSED", "FINISHED"]
	pause_button.text = "Resume" if view.state == "PAUSED" else ("Again" if view.state == "FINISHED" else "Pause")
	reset_button.text = "Next area" if view.practice else "Recover"
	var online: bool = view.get("online", false)
	var host: bool = view.get("host", true)
	pause_button.disabled = online and not host and view.state in ["PAUSED", "FINISHED"]
	reset_button.disabled = online and not host
	for index: int in range(4):
		var seat: Dictionary = view.crew[index]
		if not seat.occupied:
			seats[index].text = "%d Empty" % (index + 1)
		else:
			seats[index].text = "%d %s %d%%" % [index + 1, seat.name, roundi(seat.gas * 100)]
		seats[index].modulate = Color("ffcf50") if seat.firing else Color.WHITE
	banner.visible = view.state in ["INTRO", "COUNTDOWN"] or view.falling or (view.state == "RACING" and view.race_time < 0.8)
	if view.state == "INTRO":
		banner.text = "WAITING FOR CREW" if view.get("waiting", false) else view.course.to_upper()
	elif view.state == "COUNTDOWN":
		banner.text = "READY, CREW?\n%d" % view.countdown
	elif view.falling:
		banner.text = "CREW OVERBOARD!\nReturning to checkpoint"
	else:
		banner.text = "LET'S TOOT!"
	var key: String = "%s/%s" % [view.state, view.sound]
	if key != panel_key:
		panel_key = key
		if view.state == "PAUSED":
			if online:
				panels.show_online_pause(host)
			else:
				panels.show_pause(view.sound, view.settings_save_error)
		elif view.state == "FINISHED":
			if online:
				panels.show_online_result(view.result, view.course, host)
			else:
				panels.show_result(view.result, view.course, view.next_available)
		else:
			panels.hide()
