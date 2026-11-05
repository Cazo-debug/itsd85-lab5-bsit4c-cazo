extends "res://scripts/Screen.gd"

var message: Label
var sound_button: Button
var volume_label: Label
var toggles: Dictionary = {}

func build_menu() -> void:
	content.add_child(label("Settings", 44))
	message = label("Preferences are saved on this device.\nSwipe up for more options.", 28)
	content.add_child(message)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var options: VBoxContainer = VBoxContainer.new()
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation", 16)
	scroll.add_child(options)
	sound_button = button("", toggle_sound, options)
	var volume: HBoxContainer = HBoxContainer.new()
	options.add_child(volume)
	button("-", adjust_volume.bind(-0.1), volume).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volume_label = label("", 28)
	volume_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	volume.add_child(volume_label)
	button("+", adjust_volume.bind(0.1), volume).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for key: String in ["quality", "vibration", "reduced_motion", "show_fps"]:
		toggles[key] = button("", toggle.bind(key), options)
	options.add_child(label("Low quality reduces decorative clouds and particles.\nReduced motion softens camera turns; impact shake stays off.\nFPS is shown during gameplay.", 28))
	button("Back", back)
	refresh()

func save_setting(key: String, value: Variant) -> void:
	var error: Error = SettingsFlow.update(GameState, key, value)
	Audio.apply_settings()
	message.text = "Preference saved. Swipe up for more." if error == OK else "Could not save. Check storage and retry."
	refresh()

func toggle_sound() -> void:
	save_setting("sound", not GameState.settings.sound)

func adjust_volume(step: float) -> void:
	save_setting("music_volume", snappedf(GameState.settings.music_volume + step, 0.1))

func toggle(key: String) -> void:
	var value: Variant = ("low" if GameState.settings.quality == "high" else "high") if key == "quality" else not GameState.settings.get(key, key == "reduced_motion")
	save_setting(key, value)

func refresh() -> void:
	sound_button.text = "Sound: %s" % ("On" if GameState.settings.sound else "Off")
	volume_label.text = "Music\n%d%%" % roundi(GameState.settings.music_volume * 100)
	toggles.quality.text = "Quality: %s" % GameState.settings.quality.capitalize()
	for key: String in ["vibration", "reduced_motion", "show_fps"]:
		toggles[key].text = "%s: %s" % [key.replace("_", " ").capitalize(), "On" if GameState.settings.get(key, key == "reduced_motion") else "Off"]
