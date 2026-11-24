class_name RunPanels
extends Control

# Pause and result dialogs: a full-screen dim plus one centred card.
# Each action is [text, id, kind] where kind is "primary", "" (secondary) or "danger";
# an entry that is itself a list of actions is laid out as one row.
signal action_requested(action: String)
var panel: PanelContainer
var dim: ColorRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()

func make_action(item: Array, parent: Node) -> Button:
	var button: Button = Button.new()
	button.text = item[0]
	button.custom_minimum_size.y = 136 if item.size() > 2 and item[2] == "primary" else 120
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if item.size() > 2:
		button.theme_type_variation = {"primary": &"PrimaryButton", "danger": &"DangerButton"}.get(item[2], &"")
	button.pressed.connect(action_requested.emit.bind(item[1]))
	button.pressed.connect(Audio.play_sfx.bind("ui"))
	parent.add_child(button)
	return button

func show_panel(title: String, detail: String, actions: Array[Array], stars: int = -1) -> void:
	for old: Node in [panel, dim]:
		if old:
			# Keep retiring nodes parented until deferred deletion, including scene exit.
			old.hide()
			old.queue_free()
	dim = ColorRect.new()
	dim.color = Color(0.02, 0.08, 0.12, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP # touches never reach the game behind
	add_child(dim)
	# Bottom sheet: actions sit in the thumb zone; the card grows upward.
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 24
	panel.offset_right = -24
	panel.offset_bottom = -48
	panel.offset_top = -48
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(panel)
	var padding: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right"]:
		padding.add_theme_constant_override("margin_" + side, 32)
	for side: String in ["top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 36)
	panel.add_child(padding)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	padding.add_child(box)
	var heading: Label = Label.new()
	heading.text = title
	heading.theme_type_variation = &"HeadingLabel"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	if stars >= 0:
		var rating: Label = Label.new()
		rating.text = "★".repeat(stars) + "☆".repeat(3 - stars)
		rating.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rating.add_theme_font_size_override("font_size", 72)
		rating.add_theme_color_override("font_color", Color("ffcf50"))
		box.add_child(rating)
	var body: Label = Label.new()
	body.text = detail
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 28)
	body.add_theme_constant_override("outline_size", 0)
	body.add_theme_color_override("font_color", Color("d8eef7"))
	box.add_child(body)
	var gap: Control = Control.new()
	gap.custom_minimum_size.y = 8
	box.add_child(gap)
	for item: Array in actions:
		if not item.is_empty() and item[0] is Array:
			var line: HBoxContainer = HBoxContainer.new()
			line.add_theme_constant_override("separation", 16)
			box.add_child(line)
			for entry: Array in item:
				make_action(entry, line)
		else:
			make_action(item, box)
	show()

func show_pause(sound: bool, save_error: Error = OK, practice: bool = false) -> void:
	show_panel("Paused", "The clock is stopped." if save_error == OK else "Could not save sound. Check storage and retry.", [
		["Resume", "resume", "primary"],
		[["Restart", "retry", ""], ["Next area" if practice else "Recover crew", "recover", ""]],
		["Sound: %s" % ("On" if sound else "Off"), "sound", ""],
		["Quit to menu", "menu", "danger"]])

func show_result(result: Dictionary, course: String, next_available: bool) -> void:
	var detail: String = "%s  ·  %.1f s" % [course, result.time]
	if result.recoveries > 0:
		detail += "  ·  %d recover%s" % [result.recoveries, "y" if result.recoveries == 1 else "ies"]
	if not result.won:
		detail = "%s\nThe timer ran out. Try a different route!" % course
	detail += star_lines(result)
	if result.get("save_error", OK) != OK:
		detail += "\nProgress could not be saved. Check storage."
	var actions: Array[Array] = []
	if next_available:
		actions.append(["Next course", "next", "primary"])
		actions.append(["Retry", "retry", ""])
	else:
		actions.append(["Retry", "retry", "primary"])
		if result.won and result.level == LevelDefs.LEVELS.size() and not result.get("practice", false):
			detail += "\nAll five courses complete!"
	if result.get("save_error", OK) != OK:
		actions.append(["Retry saving", "save", ""])
	actions.append(["Menu", "menu", ""])
	show_panel(result_title(result), detail, actions, result.stars if result.won else -1)

## Headline: the winner in Versus and Teams, otherwise the usual crew result.
func result_title(result: Dictionary) -> String:
	if result.get("mode", "coop") != "coop":
		return str(result.get("headline", "Results"))
	return "Crew complete!" if result.get("won", false) else "Time's up"

## Standings (or the crew star tally) as extra lines for the result panel.
func star_lines(result: Dictionary) -> String:
	if not result.has("stars_total"):
		return ""
	var text: String = "\nStars: %d of %d" % [result.get("stars_collected", 0), result.get("stars_total", 0)]
	if result.get("mode", "coop") != "coop":
		for line: String in result.get("lines", []):
			text += "\n" + line
		if not result.get("won", false):
			text += "\n(Time ran out before the finish.)"
	return text

func show_online_pause(host: bool) -> void:
	var actions: Array[Array] = []
	if host:
		actions.append(["Resume crew", "resume", "primary"])
		actions.append(["Restart together", "retry", ""])
	actions.append(["Leave crew", "menu", "danger"])
	show_panel("Crew paused", "Only the host can resume.\nOffline progress stays unchanged.", actions)

func show_online_result(result: Dictionary, course: String, host: bool) -> void:
	var actions: Array[Array] = []
	if host:
		actions.append(["Rematch together", "retry", "primary"])
		actions.append(["Return crew to lobby", "lobby", ""])
	actions.append(["Leave crew", "menu", "danger"])
	var won: bool = result.get("won", false)
	var note: String = "One shared result for the whole crew." if result.get("mode", "coop") == "coop" else "The host decided the winner."
	show_panel(result_title(result), "%s  ·  %.1f s%s\n%s%s" % [course, result.get("time", 0.0), star_lines(result), note, "" if host else "\nWaiting for the host."], actions, result.get("stars", 0) if won else -1)
