extends "res://scripts/Screen.gd"

# Layout and user intent only. CampaignFlow owns validation/progression/settings.
var message: Label
var sound_button: Button

func build_menu() -> void:
	content.add_child(label("Choose a course" if screen == "LevelSelect" else "Settings", 0, "heading"))
	message = label("Clear a course to unlock the next one" if screen == "LevelSelect" else "Sound preference is saved on this device.", 0, "caption")
	content.add_child(message)
	if screen == "LevelSelect":
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		content.add_child(scroll)
		var list: VBoxContainer = VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 12)
		scroll.add_child(list)
		var lock: ImageTexture = UiTheme.lock_icon()
		for card: Dictionary in CampaignFlow.course_cards(GameState):
			# R4: locked courses show a lock icon and cannot be opened.
			var detail: String = "Locked - clear course %d first" % (card.number - 1)
			if card.unlocked:
				detail = "★".repeat(card.stars) + "☆".repeat(3 - card.stars)
				if card.time > 0:
					detail += "   Best %.1f s" % card.time
			var item: Button = button("%d. %s\n%s" % [card.number, card.name, detail], launch.bind(card.number), list)
			item.disabled = not card.unlocked
			item.custom_minimum_size.y = 132
			item.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if not card.unlocked:
				item.icon = lock
				item.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	else:
		sound_button = button("", toggle_sound)
		refresh_sound()
		spacer()
	back_button()

func launch(number: int) -> void:
	var error: String = CampaignFlow.launch_error(GameState, number)
	if not error.is_empty():
		message.text = error
		return
	var destination: String = CampaignFlow.prepare_launch(GameState, number)
	get_tree().change_scene_to_file(destination)

func toggle_sound() -> void:
	var error: Error = CampaignFlow.toggle_sound(GameState)
	message.text = "Sound preference saved." if error == OK else "Could not save. Check storage and try again."
	refresh_sound()

func refresh_sound() -> void:
	sound_button.text = "Sound: %s" % ("On" if GameState.settings.sound else "Off")

func back() -> void:
	go("CrewSetup" if screen == "LevelSelect" else "MainMenu")
