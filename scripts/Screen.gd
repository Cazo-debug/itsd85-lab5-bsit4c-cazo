extends Control

@export var screen: String = "Title"
var content: VBoxContainer
var model: SharedRingPreview
var draft: Dictionary = {}
var name_field: LineEdit
var option_labels: Dictionary = {}
var selected_seat: int = 0
var crew_buttons: Array[Button] = []
var crew_status: Label
var crew_profile_label: Label
var crew_control_button: Button
var save_status: Label
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	theme = preload("res://assets/GameTheme.tres")
	var background: TextureRect = TextureRect.new()
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([Color("6ec6f0"), Color("bdebfb"), Color("eef9ff")])
	gradient.offsets = PackedFloat32Array([0.0, 0.65, 1.0])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0)
	texture.fill_to = Vector2(0.5, 1)
	background.texture = texture
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
	elif screen == "CrewSetup":
		build_crew()
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
		"AvatarCreator": go(GameState.creator_return if GameState.has_avatar() else "Title")
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
	if not GameState.has_avatar():
		GameState.selected_profile = 0
		GameState.creator_return = "MainMenu"
	go("MainMenu" if GameState.has_avatar() else "AvatarCreator")

func build_menu() -> void:
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	content.add_child(label("TOOT\nTUBES" if screen == "Title" else screen.capitalize(), 76 if screen == "Title" else 52))
	match screen:
		"Title":
			content.add_child(label("A little float. A sky-high adventure."))
			button("Tap to start", start)
		"MainMenu":
			content.add_child(label("Ahoy, %s!" % GameState.avatar.get("name", "Player")))
			for entry: Array in [["Play", "CrewSetup"], ["Avatar", "AvatarCreator"], ["Settings", "Settings"], ["Credits", "Credits"]]:
				button(entry[0], open_avatar if entry[1] == "AvatarCreator" else go.bind(entry[1]))
		"ModeSelect":
			content.add_child(label("Legacy solo prototype\nThe shared-ring course arrives in Phase 2"))
			button("Play legacy Level 1", play_level_one)
			button("Crew setup", go.bind("CrewSetup"))
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
	GameState.selected_profile = clampi(GameState.selected_profile, 0, CrewData.MAX_RIDERS - 1)
	draft = AvatarData.sanitize(GameState.local_profiles[GameState.selected_profile])
	content.add_child(label("MAKE A SPLASH", 44))
	content.add_child(label("Profile %d / %s" % [GameState.selected_profile + 1, creator_seat_label()], 28))
	build_preview(280)
	refresh_creator_preview()
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
	options.add_child(label("Previewing this rider's ring style", 28))
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
	save_status = label("", 28)
	save_status.visible = false
	content.add_child(save_status)
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
	refresh_creator_preview()
	refresh_labels()

func randomize_avatar() -> void:
	draft = AvatarData.random_avatar(rng)
	name_field.text = draft.name
	refresh_creator_preview()
	refresh_labels()

func save_avatar() -> void:
	draft.name = name_field.text
	var previous_profiles: Array[Dictionary] = GameState.local_profiles.duplicate(true)
	var previous_slots: Array[Dictionary] = GameState.crew_slots.duplicate(true)
	GameState.set_profile(GameState.selected_profile, draft)
	if GameState.save_progress(GameState.persistence_path) != OK:
		GameState.local_profiles = previous_profiles
		GameState.crew_slots = previous_slots
		save_status.text = "Could not save. Check available storage and retry."
		save_status.show()
		return
	go(GameState.creator_return)

func _process(delta: float) -> void:
	if is_instance_valid(model):
		model.rotation.y += delta * 0.35

func open_avatar() -> void:
	GameState.selected_profile = 0
	GameState.creator_return = "MainMenu"
	go("AvatarCreator")

func creator_seat_label() -> String:
	for index: int in range(CrewData.MAX_RIDERS):
		if GameState.crew_slots[index].control != "empty" and GameState.crew_slots[index].profile == GameState.selected_profile:
			return "seat %d" % (index + 1)
	return "unassigned seat preview"

func refresh_creator_preview() -> void:
	var profiles: Array[Dictionary] = GameState.local_profiles.duplicate(true)
	profiles[GameState.selected_profile] = draft.duplicate(true)
	var slots: Array[Dictionary] = GameState.crew_slots.duplicate(true)
	var present: bool = false
	for slot: Dictionary in slots:
		if slot.control != "empty" and slot.profile == GameState.selected_profile:
			present = true
	if not present:
		# Temporary preview only: editing does not change crew assignment.
		slots = [CrewData.make_slot("local", GameState.selected_profile), CrewData.empty_slot(), CrewData.empty_slot(), CrewData.empty_slot()]
	model.configure(profiles, slots, GameState.selected_profile, GameState.selected_profile)
	# Creator keeps the edited style visible; crew uses the chosen leader's style.

func build_crew() -> void:
	content.add_theme_constant_override("separation", 12)
	content.add_child(label("ONE RING. YOUR CREW.", 44))
	content.add_child(label("Shared-ring play arrives in Phase 2", 28))
	build_preview(220)
	var seats: GridContainer = GridContainer.new()
	seats.columns = 2
	seats.add_theme_constant_override("h_separation", 12)
	seats.add_theme_constant_override("v_separation", 8)
	content.add_child(seats)
	for index: int in range(CrewData.MAX_RIDERS):
		var seat_button: Button = button("", select_seat.bind(index), seats)
		seat_button.add_theme_font_size_override("font_size", 28)
		seat_button.clip_text = true
		crew_buttons.append(seat_button)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size.y = 180
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	var options: VBoxContainer = VBoxContainer.new()
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation", 12)
	scroll.add_child(options)
	crew_status = label("", 28)
	options.add_child(crew_status)
	var profile_row: HBoxContainer = HBoxContainer.new()
	options.add_child(profile_row)
	button("<", cycle_crew_profile.bind(-1), profile_row).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	crew_profile_label = label("", 28)
	crew_profile_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_row.add_child(crew_profile_label)
	button(">", cycle_crew_profile.bind(1), profile_row).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	crew_control_button = button("", cycle_control, options)
	var actions: HBoxContainer = HBoxContainer.new()
	options.add_child(actions)
	button("Edit rider", edit_crew_profile, actions)
	button("Make leader", make_leader, actions)
	options.add_child(label("Scroll for rider options. Assistants move in Phase 2.\nThe leader chooses the shared ring style.", 28))
	button("Modes / legacy prototype", go.bind("ModeSelect"))
	button("Back", back)
	refresh_crew()

func select_seat(index: int) -> void:
	selected_seat = index
	refresh_crew()

func selected_crew_profile() -> int:
	var slot: Dictionary = GameState.crew_slots[selected_seat]
	return slot.profile if slot.control != "empty" else selected_seat

func refresh_crew() -> void:
	GameState.validate_leader()
	model.configure(GameState.local_profiles, GameState.crew_slots, GameState.leader_profile)
	for index: int in range(CrewData.MAX_RIDERS):
		var slot: Dictionary = GameState.crew_slots[index]
		var title: String = "Empty"
		var detail: String = "Tap to choose"
		if slot.control != "empty":
			title = GameState.local_profiles[slot.profile].get("name", "Player")
			detail = "Assistant" if slot.control == "assist" else "Local rider"
			if slot.profile == GameState.leader_profile:
				detail += " · Leader"
		crew_buttons[index].text = "%d · %s\n%s" % [index + 1, title, detail]
		crew_buttons[index].modulate = Color("fff1ad") if index == selected_seat else Color.WHITE
	var slot: Dictionary = GameState.crew_slots[selected_seat]
	crew_status.text = "Seat %d selected · scroll for options" % (selected_seat + 1)
	crew_profile_label.text = "Profile %d\n%s" % [selected_crew_profile() + 1, GameState.local_profiles[selected_crew_profile()].get("name", "Player")]
	crew_control_button.text = "Seat: %s (tap to change)" % {"empty": "Empty", "local": "Local rider", "assist": "Assistant", "peer": "Peer"}[slot.control]

func persist_crew() -> void:
	refresh_crew()
	if GameState.save_progress(GameState.persistence_path) != OK:
		crew_status.text = "Could not save. Check storage and retry."

func cycle_crew_profile(direction: int) -> void:
	var slot: Dictionary = GameState.crew_slots[selected_seat]
	for offset: int in range(1, CrewData.MAX_RIDERS + 1):
		var candidate: int = posmod(selected_crew_profile() + offset * direction, CrewData.MAX_RIDERS)
		if GameState.assign_slot(selected_seat, slot.control if slot.control != "empty" else "assist", candidate):
			persist_crew()
			return
	crew_status.text = "Each profile can occupy only one seat."

func cycle_control() -> void:
	var slot: Dictionary = GameState.crew_slots[selected_seat]
	var next: String = {"empty": "assist", "assist": "local", "local": "empty", "peer": "empty"}[slot.control]
	if GameState.assign_slot(selected_seat, next, selected_crew_profile()):
		persist_crew()
	else:
		crew_status.text = "Choose an unused profile with the arrows."

func edit_crew_profile() -> void:
	GameState.selected_profile = selected_crew_profile()
	GameState.creator_return = "CrewSetup"
	go("AvatarCreator")

func make_leader() -> void:
	if GameState.crew_slots[selected_seat].control == "empty":
		crew_status.text = "Assign a rider before choosing the leader."
		return
	GameState.leader_profile = selected_crew_profile()
	persist_crew()

func build_preview(minimum_height: float) -> void:
	var preview: SubViewportContainer = SubViewportContainer.new()
	preview.stretch = true
	preview.custom_minimum_size.y = minimum_height
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(preview)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(656, 480)
	viewport.own_world_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview.add_child(viewport)
	model = SharedRingPreview.new()
	viewport.add_child(model)
	var water: MeshInstance3D = MeshInstance3D.new()
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = 3.6
	disc.bottom_radius = 3.6
	disc.height = 0.16
	disc.radial_segments = 32
	water.mesh = disc
	water.position.y = -0.36
	water.material_override = SkyEnvironment.water()
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	viewport.add_child(water)
	var camera: Camera3D = Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(4.2, 6.7, 7.5)
	camera.look_at(Vector3(0, 0.0, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.8
	SkyEnvironment.install(viewport)
	var island: MeshInstance3D = MeshInstance3D.new()
	var underside: CylinderMesh = CylinderMesh.new()
	underside.top_radius = 3.8
	underside.bottom_radius = 0.2
	underside.height = 1.6
	underside.radial_segments = 16
	island.mesh = underside
	island.material_override = SkyEnvironment.cliff()
	island.position.y = -1.25
	island.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	viewport.add_child(island)
	var rim: MeshInstance3D = MeshInstance3D.new()
	var rim_mesh: TorusMesh = TorusMesh.new()
	rim_mesh.inner_radius = 3.55
	rim_mesh.outer_radius = 3.9
	rim_mesh.rings = 24
	rim_mesh.ring_segments = 8
	rim.mesh = rim_mesh
	rim.material_override = AvatarModel.material(Color("7acb3b"))
	rim.position.y = -0.35
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	viewport.add_child(rim)
