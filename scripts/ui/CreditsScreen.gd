extends "res://scripts/Screen.gd"

var notices: RichTextLabel

func build_menu() -> void:
	content.add_child(label("Credits", 0, "heading"))
	content.add_child(label("Game, art, icon, sound and music: Carlos Fidel G. Castro (Team Cazo), all original.\nFont: Fredoka Project Authors (SIL OFL).\nEngine: Godot Engine contributors (MIT)."))
	button("Read licenses", show_licenses)
	notices = RichTextLabel.new()
	notices.size_flags_vertical = Control.SIZE_EXPAND_FILL
	notices.add_theme_font_size_override("normal_font_size", 28)
	notices.bbcode_enabled = false
	notices.selection_enabled = true
	content.add_child(notices)
	notices.text = "All riders share one original ring.\nNo commercial game characters, models or recordings are bundled.\n\nDevelopment tests use GUT (MIT), excluded from game exports."
	back_button()

func show_licenses() -> void:
	notices.text = FileAccess.get_file_as_string("res://assets/licenses/NOTICE.txt") + "\n\nFREDOKA\n" + FileAccess.get_file_as_string("res://assets/fonts/OFL.txt") + "\n\nGODOT ENGINE\n" + Engine.get_license_text()
	var licenses: Dictionary = Engine.get_license_info()
	for license_name: String in licenses:
		notices.text += "\n\n" + license_name + "\n" + str(licenses[license_name])
	for component: Dictionary in Engine.get_copyright_info():
		notices.text += "\n\n" + str(component)
	notices.scroll_to_line(0)
