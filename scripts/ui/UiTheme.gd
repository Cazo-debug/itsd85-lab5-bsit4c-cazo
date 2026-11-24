class_name UiTheme
extends RefCounted

# One design system for every screen.
#
# Buttons, by importance (one Primary per screen):
#   PrimaryButton  - green, biggest text: the main action ("Play", "Start", "Save").
#   Button         - white card, blue text: normal choices.
#   GhostButton    - outline only: Back and minor actions.
#   DangerButton   - soft red: leaving or quitting.
#   HudButton      - translucent dark pill used over the 3D game.
# Type scale (720 x 1280 layout, body text never below 28 px):
#   TitleLabel 64 · HeadingLabel 42 · Label (body) 30 · CaptionLabel 28.

const PRIMARY: Color = Color("4cbf3a")
const PRIMARY_EDGE: Color = Color("2f8f22")
const INK: Color = Color("15435a")
const INK_SOFT: Color = Color("2c6b86")
const CARD: Color = Color("ffffff")
const CARD_EDGE: Color = Color("a9d8ec")
const DANGER: Color = Color("e5534b")
const OUTLINE: Color = Color("12303f")
const SIZE_TITLE: int = 64
const SIZE_HEADING: int = 42
const SIZE_BODY: int = 30
const SIZE_CAPTION: int = 28

static var cached: Theme

static func get_theme() -> Theme:
	if cached == null:
		cached = build()
	return cached

static func box(fill: Color, edge: Color = Color.TRANSPARENT, bottom: int = 0, border: int = 0, radius: int = 28) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(border)
	style.border_width_bottom = maxi(bottom, border)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.anti_aliasing = true
	return style

# normal / pressed (shifted down 4 px, no lip) / disabled.
static func button_styles(theme: Theme, kind: String, fill: Color, edge: Color, lip: int, border: int = 0) -> void:
	var normal: StyleBoxFlat = box(fill, edge, lip, border)
	var pressed: StyleBoxFlat = box(fill.darkened(0.1) if fill.a > 0.0 else Color(1, 1, 1, 0.18), edge, border, border)
	pressed.content_margin_top = 8 + lip
	var disabled: StyleBoxFlat = box(Color(fill, fill.a * 0.45) if fill.a > 0.0 else Color.TRANSPARENT, Color(edge, edge.a * 0.45), lip, border)
	theme.set_stylebox("normal", kind, normal)
	theme.set_stylebox("hover", kind, normal)
	theme.set_stylebox("pressed", kind, pressed)
	theme.set_stylebox("hover_pressed", kind, pressed)
	theme.set_stylebox("disabled", kind, disabled)
	var focus: StyleBoxFlat = box(Color.TRANSPARENT, Color("ffcf50"), 0, 4)
	theme.set_stylebox("focus", kind, focus)

static func build() -> Theme:
	var theme: Theme = Theme.new()
	var font: FontVariation = FontVariation.new()
	font.base_font = preload("res://assets/fonts/Fredoka.ttf")
	font.variation_opentype = {2003265652: 600.0}
	theme.default_font = font
	theme.default_font_size = SIZE_BODY
	# Secondary (default) button: white card, blue text.
	button_styles(theme, "Button", CARD, CARD_EDGE, 6)
	for state: String in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color", "font_pressed_color"]:
		theme.set_color(state, "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color(INK, 0.45))
	theme.set_constant("outline_size", "Button", 0)
	theme.set_font_size("font_size", "Button", SIZE_BODY)
	# Primary: green, larger, white text with an outline.
	theme.set_type_variation("PrimaryButton", "Button")
	button_styles(theme, "PrimaryButton", PRIMARY, PRIMARY_EDGE, 8)
	for state: String in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color", "font_pressed_color"]:
		theme.set_color(state, "PrimaryButton", Color.WHITE)
	theme.set_color("font_outline_color", "PrimaryButton", Color(0.1, 0.32, 0.06))
	theme.set_constant("outline_size", "PrimaryButton", 6)
	theme.set_font_size("font_size", "PrimaryButton", 38)
	# Ghost: outline only, for Back and minor actions on menu screens.
	theme.set_type_variation("GhostButton", "Button")
	button_styles(theme, "GhostButton", Color(1, 1, 1, 0.35), Color(INK, 0.55), 3, 3)
	for state: String in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color", "font_pressed_color"]:
		theme.set_color(state, "GhostButton", INK)
	theme.set_font_size("font_size", "GhostButton", 28)
	# HUD: translucent dark pills that sit quietly over the 3D game.
	theme.set_type_variation("HudButton", "Button")
	button_styles(theme, "HudButton", Color(0.05, 0.18, 0.26, 0.72), Color(1, 1, 1, 0.35), 2, 2)
	for state: String in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color", "font_pressed_color"]:
		theme.set_color(state, "HudButton", Color.WHITE)
	theme.set_font_size("font_size", "HudButton", 28)
	# Danger: leaving or quitting.
	theme.set_type_variation("DangerButton", "Button")
	button_styles(theme, "DangerButton", Color("fff1ef"), Color("f2b3ad"), 6)
	for state: String in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color", "font_pressed_color"]:
		theme.set_color(state, "DangerButton", DANGER.darkened(0.15))
	theme.set_font_size("font_size", "DangerButton", SIZE_BODY)
	# Labels: white with a dark outline so they read over the sky and the 3D game.
	theme.set_color("font_color", "Label", Color.WHITE)
	theme.set_color("font_outline_color", "Label", OUTLINE)
	theme.set_constant("outline_size", "Label", 6)
	theme.set_font_size("font_size", "Label", SIZE_BODY)
	for item: Array in [["TitleLabel", SIZE_TITLE, 10], ["HeadingLabel", SIZE_HEADING, 8]]:
		theme.set_type_variation(item[0], "Label")
		theme.set_font_size("font_size", item[0], item[1])
		theme.set_constant("outline_size", item[0], item[2])
	# Captions: quieter dark-blue text, no outline.
	theme.set_type_variation("CaptionLabel", "Label")
	theme.set_font_size("font_size", "CaptionLabel", SIZE_CAPTION)
	theme.set_color("font_color", "CaptionLabel", INK)
	theme.set_constant("outline_size", "CaptionLabel", 0)
	# Text inputs look like inputs, not buttons.
	var field: StyleBoxFlat = box(CARD, Color("7fc6e3"), 3, 3, 20)
	var field_focus: StyleBoxFlat = box(CARD, Color("ffb627"), 4, 4, 20)
	theme.set_stylebox("normal", "LineEdit", field)
	theme.set_stylebox("focus", "LineEdit", field_focus)
	theme.set_stylebox("read_only", "LineEdit", field)
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", Color(INK, 0.45))
	theme.set_color("caret_color", "LineEdit", INK)
	theme.set_font_size("font_size", "LineEdit", SIZE_BODY)
	# Dialog cards (pause, results).
	var card: StyleBoxFlat = box(Color("103a4f"), Color("2b7fa3"), 4, 4, 36)
	card.shadow_color = Color(0, 0, 0, 0.35)
	card.shadow_size = 18
	theme.set_stylebox("panel", "PanelContainer", card)
	theme.set_color("font_color", "RichTextLabel", INK)
	theme.set_font_size("normal_font_size", "RichTextLabel", SIZE_CAPTION)
	return theme

## Small procedural padlock icon for locked levels (R4: "locked levels show a lock icon").
static func lock_icon(size: int = 44) -> ImageTexture:
	var image: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var ink: Color = Color("4d6f80")
	var body_top: int = int(size * 0.45)
	image.fill_rect(Rect2i(int(size * 0.14), body_top, int(size * 0.72), size - body_top - 2), ink)
	var center: Vector2 = Vector2(size * 0.5, body_top)
	var outer: float = size * 0.27
	var inner: float = size * 0.15
	for y: int in range(0, body_top):
		for x: int in range(size):
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
			if distance <= outer and distance >= inner and y + 0.5 <= center.y:
				image.set_pixel(x, y, ink)
	for y: int in range(int(size * 0.62), int(size * 0.82)):
		for x: int in range(int(size * 0.45), int(size * 0.55)):
			image.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(image)
