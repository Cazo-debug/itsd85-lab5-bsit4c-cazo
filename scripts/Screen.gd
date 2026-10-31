extends Control

@export var screen: String = "Title"
var content: VBoxContainer
var model: AvatarModel
var draft: Dictionary = {}
var name_field: LineEdit
var option_labels: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	theme = preload("res://assets/GameTheme.tres")
	var background: ColorRect = ColorRect.new()
	background.color = Color("3cc3e6")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margins: MarginContainer = MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left", "right"]:
		margins.add_theme_constant_override("margin_" + edge, 32)
	margins.add_theme_constant_override("margin_top", 88)
	margins.add_theme_constant_override("margin_bottom", 24)
	add_child(margins)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	margins.add_child(content)
	if screen == "AvatarCreator":
		build_creator()
	else:
		build_menu()

func label(text: String, size: int = 32) -> Label:
	var item: Label = Label.new()
	item.text = text
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size", size)
	return item

func button(text: String, action: Callable, parent: Node = content) -> Button:
	var item: Button = Button.new()
	item.text = text
	item.custom_minimum_size = Vector2(120, 120)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.pressed.connect(action)
	parent.add_child(item)
	return item

func go(destination: String) -> void:
	get_tree().change_scene_to_file("res://scenes/ui/%s.tscn" % destination)

func back() -> void:
	match screen:
		"Title": get_tree().quit()
		"MainMenu": go("Title")
		"AvatarCreator": go("MainMenu" if GameState.has_avatar() else "Title")
		_: go("MainMenu")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		back()
	elif screen == "Title" and ((event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)):
		start()

func start() -> void:
	go("MainMenu" if GameState.has_avatar() else "AvatarCreator")

func build_menu() -> void:
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	content.add_child(label("TOOT\nTUBES" if screen == "Title" else screen.capitalize(), 76 if screen == "Title" else 52))
	match screen:
		"Title":
			content.add_child(label("Small float. Big adventure."))
			button("Tap to start", start)
		"MainMenu":
			content.add_child(label("Ahoy, %s!" % GameState.avatar.get("name", "Player")))
			for entry: Array in [["Play", "ModeSelect"], ["Avatar", "AvatarCreator"], ["Settings", "Settings"], ["Credits", "Credits"]]:
				button(entry[0], go.bind(entry[1]))
		"ModeSelect":
			content.add_child(label("Lazy River\nToot to the finish ring in 75 seconds"))
			button("Play Level 1", play_level_one)
			if not GameState.last_result.is_empty():
				var result: Dictionary = GameState.last_result
				content.add_child(label("Last race: %d stars · %.1f s" % [result.stars, result.time] if result.won else "Time's up! Give it another go.", 28))
		"Settings": content.add_child(label("Settings controls arrive in Phase 5."))
		"Credits": content.add_child(label("Original primitive-mesh artwork\nFredoka — OFL\nGodot & GUT — MIT\nFull credits: docs/CREDITS.md"))
	var bottom_space: Control = Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(bottom_space)
	button("Exit" if screen == "Title" else "Back", back)

func play_level_one() -> void:
	GameState.mode = "offline"
	GameState.current_level = 1
	get_tree().change_scene_to_file(GameState.level_scene_path(1))

func build_creator() -> void:
	draft = AvatarData.sanitize(GameState.avatar)
	content.add_child(label("MAKE A SPLASH", 44))
	var preview: SubViewportContainer = SubViewportContainer.new()
	preview.stretch = true
	preview.custom_minimum_size.y = 340
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(preview)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(656, 480)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview.add_child(viewport)
	model = AvatarModel.new()
	viewport.add_child(model)
	model.apply(draft)
	var water: MeshInstance3D = MeshInstance3D.new()
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 2.6
	disc.bottom_radius = 2.6
	disc.height = 0.16
	disc.radial_segments = 32
	water.mesh = disc
	water.position.y = -0.36
	water.material_override = AvatarModel.material(Color("1a8fb8"))
	viewport.add_child(water)
	var camera: Camera3D = Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(3.7, 3.3, 5.5)
	camera.look_at(Vector3(0, 0.7, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.9
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.shadow_enabled = false
	viewport.add_child(light)
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	viewport.add_child(environment)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 280
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var options: VBoxContainer = VBoxContainer.new()
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation", 12)
	scroll.add_child(options)
	options.add_child(label("Swipe up for more options", 28))
	name_field = LineEdit.new()
	name_field.placeholder_text = "Your name"
	name_field.max_length = 12
	name_field.text = draft.name
	name_field.custom_minimum_size.y = 120
	name_field.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	options.add_child(name_field)
	for key: String in AvatarData.LIMITS:
		var row: HBoxContainer = HBoxContainer.new()
		options.add_child(row)
		button("◀", cycle.bind(key, -1), row).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var value_label: Label = label("")
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(value_label)
		option_labels[key] = value_label
		button("▶", cycle.bind(key, 1), row).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	refresh_labels()
	var actions: HBoxContainer = HBoxContainer.new()
	content.add_child(actions)
	button("Randomize", randomize_avatar, actions)
	button("Save", save_avatar, actions)
	button("Back", back)

func refresh_labels() -> void:
	for key: String in option_labels:
		var value: String = str(int(draft[key]) + 1)
		match key:
			"float_style": value = AvatarData.FLOAT_STYLES[draft[key]].capitalize()
			"hat": value = AvatarData.HATS[draft[key]].capitalize()
			"toot": value = AvatarData.TOOT_COLORS[draft[key]].capitalize()
		option_labels[key].text = "%s\n%s" % [key.replace("_", " ").capitalize(), value]

func cycle(key: String, direction: int) -> void:
	draft[key] = posmod(int(draft[key]) + direction, AvatarData.LIMITS[key])
	model.apply(draft)
	refresh_labels()

func randomize_avatar() -> void:
	draft = AvatarData.random_avatar(rng)
	model.apply(draft)
	refresh_labels()

func save_avatar() -> void:
	draft.name = name_field.text
	GameState.avatar = AvatarData.sanitize(draft)
	GameState.save_progress(GameState.persistence_path)
	go("MainMenu")

func _process(delta: float) -> void:
	if is_instance_valid(model):
		model.rotation.y += delta * 0.35
