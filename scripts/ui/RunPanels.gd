class_name RunPanels
extends Control

signal action_requested(action: String)
var panel: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func show_panel(title: String, detail: String, actions: Array[Array]) -> void:
	if panel:
		remove_child(panel)
		panel.queue_free()
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 32
	panel.offset_right = -32
	panel.offset_top = 385
	panel.offset_bottom = -80
	add_child(panel)
	var padding: MarginContainer = MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(padding)
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	padding.add_child(box)
	for text: String in [title, detail]:
		var label: Label = Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 38 if text == title else 28)
		box.add_child(label)
	for item: Array in actions:
		var button: Button = Button.new()
		button.text = item[0]
		button.custom_minimum_size.y = 120
		button.pressed.connect(action_requested.emit.bind(item[1]))
		box.add_child(button)
	show()

func show_pause(sound: bool, save_error: Error = OK) -> void:
	show_panel("Paused", "The clock and all held inputs are stopped." if save_error == OK else "Could not save sound. Check storage and retry.", [
		["Resume", "resume"], ["Restart", "retry"], ["Sound: %s" % ("On" if sound else "Off"), "sound"], ["Quit to menu", "menu"]])

func show_result(result: Dictionary, course: String, next_available: bool) -> void:
	var detail: String = "%s\n%.1f s | %d stars | %d recoveries" % [course, result.time, result.stars, result.recoveries]
	if result.get("save_error", OK) != OK:
		detail += "\nProgress could not be saved. Check storage."
	var actions: Array[Array] = [["Retry", "retry"]]
	if next_available:
		actions.append(["Next course", "next"])
	elif result.won and result.level == LevelDefs.LEVELS.size() and not result.get("practice", false):
		detail += "\nAll five courses complete!"
	if result.get("save_error", OK) != OK:
		actions.append(["Retry saving", "save"])
	actions.append(["Menu", "menu"])
	show_panel("Crew complete!" if result.won else "Time's up", detail, actions)
