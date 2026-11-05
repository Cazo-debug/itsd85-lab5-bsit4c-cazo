extends "res://scripts/Screen.gd"

# Layout and user intent only. CampaignFlow owns validation/progression/settings.
var message: Label
var sound_button: Button

func build_menu() -> void:
	content.add_child(label("Choose a course" if screen == "LevelSelect" else "Settings", 44))
	message = label("One ring. Finish together." if screen == "LevelSelect" else "Sound preference is saved on this device.", 28)
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
		for card: Dictionary in CampaignFlow.course_cards(GameState):
			var detail: String = "Locked - finish course %d" % (card.number - 1)
			if card.unlocked:
				detail = "%d / 3 stars" % card.stars
				if card.time > 0:
					detail += "  |  Best %.1f s" % card.time
			var item: Button = button("%d. %s\n%s" % [card.number, card.name, detail], launch.bind(card.number), list)
			item.disabled = not card.unlocked
			item.add_theme_font_size_override("font_size", 28)
	else:
		sound_button = button("", toggle_sound)
		refresh_sound()
		var spacer: Control = Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(spacer)
	button("Back", back)

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
