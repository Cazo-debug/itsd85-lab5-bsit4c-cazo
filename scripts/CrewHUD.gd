class_name CrewHUD
extends CanvasLayer

signal back_requested
signal pause_requested
signal reset_requested
signal action_requested(action: String)
var controls: CrewInput
var root: Control
var top_row: HBoxContainer
var back_button: Button
var timer_label: Label
var section_label: Label
var progress: ProgressBar
var banner: Label
var count_label: Label
var hint: Label
var seats: Array[Label] = []
var pause_button: Button
var reset_button: Button
var panels: RunPanels
var panel_key: String = ""
var fps_label: Label

func make_label(text: String, font_size: int = 28) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

# Small translucent pills: present, but quiet over the 3D game.
func make_button(text: String, callback: Callable, parent: Node) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.theme_type_variation = &"HudButton"
	button.custom_minimum_size = Vector2(150, 120)
	button.pressed.connect(callback)
	button.pressed.connect(Audio.play_sfx.bind("ui"))
	parent.add_child(button)
	return button

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UiTheme.get_theme()
	add_child(root)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_top", 88)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)
	# Top bar: Back (left) and Pause (right) far apart; the timer is the focus.
	top_row = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(top_row)
	back_button = make_button("Back", back_requested.emit, top_row)
	var center: VBoxContainer = VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 0)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(center)
	timer_label = make_label("Sky Garden", 44)
	center.add_child(timer_label)
	section_label = make_label("", 28)
	section_label.clip_text = true
	center.add_child(section_label)
	pause_button = make_button("Pause", pause_requested.emit, top_row)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 12
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track: StyleBoxFlat = UiTheme.box(Color(0.05, 0.18, 0.26, 0.45), Color.TRANSPARENT, 0, 0, 6)
	var fill: StyleBoxFlat = UiTheme.box(Color("ffcf50"), Color.TRANSPARENT, 0, 0, 6)
	track.set_content_margin_all(0)
	fill.set_content_margin_all(0)
	progress.add_theme_stylebox_override("background", track)
	progress.add_theme_stylebox_override("fill", fill)
	box.add_child(progress)
	var gas_row: HBoxContainer = HBoxContainer.new()
	gas_row.alignment = BoxContainer.ALIGNMENT_CENTER
	gas_row.add_theme_constant_override("separation", 28)
	gas_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(gas_row)
	for index: int in range(4):
		var seat: Label = make_label("")
		gas_row.add_child(seat)
		seats.append(seat)
	# Practice only: jump to the next practice area.
	reset_button = make_button("Next area", reset_requested.emit, box)
	reset_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reset_button.custom_minimum_size.x = 220
	fps_label = make_label("", 28)
	box.add_child(fps_label)
	banner = make_label("SKY GARDEN", 42)
	banner.theme_type_variation = &"HeadingLabel"
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	banner.offset_left = -330
	banner.offset_right = 330
	banner.offset_top = -190
	banner.offset_bottom = 10
	banner.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(banner)
	count_label = make_label("", 120)
	count_label.theme_type_variation = &"TitleLabel"
	count_label.add_theme_font_size_override("font_size", 120)
	count_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	count_label.offset_left = -300
	count_label.offset_right = 300
	count_label.offset_top = 20
	count_label.offset_bottom = 180
	root.add_child(count_label)
	hint = make_label("Aim + hold to fart", 28)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -330
	hint.offset_bottom = -270
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	var in_dialog: bool = view.state in ["PAUSED", "FINISHED"]
	var online: bool = view.get("online", false)
	var host: bool = view.get("host", true)
	fps_label.visible = view.get("show_fps", false)
	fps_label.text = "%d FPS" % view.get("fps", 0)
	timer_label.text = "Practice" if view.practice else "%d s" % ceili(view.time_left)
	timer_label.modulate = Color("ff8b94") if not view.practice and view.time_left < 10 else Color.WHITE
	section_label.text = "%s  ·  ★ %d/%d" % [view.section, view.get("stars_collected", 0), view.get("stars_total", 0)]
	progress.value = view.progress * 100
	hint.text = view.hint if DisplayServer.is_touchscreen_available() else view.hint + "\nWASD + Space on desktop"
	hint.visible = not in_dialog
	controls.visible = not in_dialog
	# Dialogs own the screen: hide the top bar so nothing is duplicated behind them.
	back_button.visible = not in_dialog
	pause_button.visible = not in_dialog
	pause_button.disabled = online and not host and in_dialog
	reset_button.visible = view.practice and not in_dialog
	reset_button.disabled = online and not host
	for index: int in range(4):
		var seat: Dictionary = view.crew[index]
		seats[index].visible = seat.occupied
		seats[index].text = "P%d  ★%d\n%d%%" % [index + 1, seat.get("stars", 0), roundi(seat.gas * 100)]
		seats[index].modulate = Color("ffcf50") if seat.firing else (Color("ff8b94") if seat.gas < 0.15 else Color.WHITE)
	# R2: the level goal is shown at the start of every level.
	var goal: String = "Practice: no time limit" if view.practice else String(view.get("goal", ""))
	banner.visible = view.state in ["INTRO", "COUNTDOWN"] or view.falling
	count_label.visible = view.state == "COUNTDOWN" or (view.state == "RACING" and view.race_time < 0.8 and not view.falling)
	if view.state == "INTRO":
		banner.text = "WAITING FOR CREW" if view.get("waiting", false) else "%s\n%s\n%s" % [view.course.to_upper(), goal, view.get("rules", "")]
	elif view.state == "COUNTDOWN":
		banner.text = goal
		count_label.text = str(view.countdown)
	elif view.falling:
		banner.text = "CREW OVERBOARD!\nBack to the checkpoint"
	else:
		count_label.text = "GO!"
	var key: String = "%s/%s" % [view.state, view.sound]
	if key != panel_key:
		panel_key = key
		if view.state == "PAUSED":
			if online:
				panels.show_online_pause(host)
			else:
				panels.show_pause(view.sound, view.settings_save_error, view.practice)
		elif view.state == "FINISHED":
			if online:
				panels.show_online_result(view.result, view.course, host)
			else:
				panels.show_result(view.result, view.course, view.next_available)
		else:
			panels.hide()
