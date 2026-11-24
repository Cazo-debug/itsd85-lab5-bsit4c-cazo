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
var mode_button: Button
var save_status: Label
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
const OUTFIT_NAMES: Array[String] = ["Red", "Yellow", "Green", "Teal", "Blue", "Purple", "Pink", "White"]

func _ready() -> void:
	Audio.play_music()
	rng.randomize()
	theme = UiTheme.get_theme()
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
	content.add_theme_constant_override("separation", 18)
	margins.add_child(content)
	if screen == "AvatarCreator":
		build_creator()
	elif screen == "CrewSetup":
		build_crew()
	else:
		build_menu()

## role: "" body · "title" · "heading" · "caption" (see UiTheme). size > 0 overrides the role size.
func label(text: String, size: int = 0, role: String = "") -> Label:
	var item: Label = Label.new()
	item.text = text
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.theme_type_variation = {"title": &"TitleLabel", "heading": &"HeadingLabel", "caption": &"CaptionLabel"}.get(role, &"")
	if size > 0:
		item.add_theme_font_size_override("font_size", size)
	return item

## kind: "primary" (one per screen) · "" secondary · "ghost" (Back, minor) · "danger" (quit/leave).
func button(text: String, action: Callable, parent: Node = content, kind: String = "") -> Button:
	var item: Button = Button.new()
	item.text = text
	item.custom_minimum_size = Vector2(120, 136 if kind == "primary" else 120)
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.theme_type_variation = {"primary": &"PrimaryButton", "ghost": &"GhostButton", "danger": &"DangerButton"}.get(kind, &"")
	item.pressed.connect(action)
	item.pressed.connect(Audio.play_sfx.bind("ui"))
	parent.add_child(item)
	return item

func row(parent: Node = content) -> HBoxContainer:
	var line: HBoxContainer = HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	parent.add_child(line)
	return line

func spacer(parent: Node = content, height: float = 0.0) -> Control:
	var gap: Control = Control.new()
	if height > 0.0:
		gap.custom_minimum_size.y = height
	else:
		gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(gap)
	return gap

func back_button() -> Button:
	return button("Back", back, content, "ghost")

func go(destination: String) -> void:
	get_tree().change_scene_to_file("res://scenes/ui/%s.tscn" % destination)

## Course select remembers where it was opened from, so Back returns there.
func open_courses(from: String) -> void:
	GameState.course_return = from
	go("LevelSelect")

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
	if screen == "MainMenu":
		build_main_menu()
		return
	var top_gap: Control = Control.new()
	top_gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(top_gap)
	content.add_child(label("TOOT\nTUBES" if screen == "Title" else screen.capitalize(), 76 if screen == "Title" else 52))
	match screen:
		"Title":
			content.add_child(label("A little float. A sky-high adventure."))
			button("Tap to start", start)
		"MainMenu":
			content.add_child(label("Ahoy, %s!" % GameState.avatar.get("name", "Player")))
			for entry: Array in [["Play", "ModeSelect"], ["Courses", "LevelSelect"], ["Avatar", "AvatarCreator"], ["Settings", "Settings"], ["Credits", "Credits"]]:
				button(entry[0], open_avatar if entry[1] == "AvatarCreator" else go.bind(entry[1]))
		"ModeSelect":
			content.add_child(label("Sky Garden\nOne ring. Reach the summit together!"))
			button("Start Sky Garden", launch_sky.bind(false))
			button("Practice", launch_sky.bind(true))
			button("Crew setup", go.bind("CrewSetup"))
			if not GameState.last_result.is_empty():
				var result: Dictionary = GameState.last_result
				content.add_child(label("Last race: %d stars · %.1f s" % [result.stars, result.time] if result.won else "Time's up! Give it another go.", 28))
		"Settings": content.add_child(label("Settings controls arrive in Phase 5."))
		"Credits": content.add_child(label("Original primitive-mesh artwork\nFredoka — OFL\nGodot & GUT — MIT\nFull credits: docs/CREDITS.md"))
	var bottom_space: Control = Control.new()
	bottom_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(bottom_space)
	button("Exit" if screen == "Title" else "Back", back, content, "ghost")

func build_main_menu() -> void:
	content.add_child(label("TOOT TUBES", 0, "title"))
	content.add_child(label("Ahoy, %s!" % GameState.avatar.get("name", "Player")))
	build_preview(260)
	model.configure(GameState.local_profiles, GameState.crew_slots, GameState.leader_profile)
	button("Play", go.bind("ModeSelect"), content, "primary")
	var middle: HBoxContainer = row()
	button("Courses", open_courses.bind("MainMenu"), middle)
	button("Avatar", open_avatar, middle)
	var minor: HBoxContainer = row()
	button("Settings", go.bind("Settings"), minor, "ghost")
	button("Credits", go.bind("Credits"), minor, "ghost")
	back_button()

func play_level_one() -> void:
	GameState.mode = "offline"
	GameState.current_level = 1
	get_tree().change_scene_to_file(GameState.level_scene_path(1))

func build_creator() -> void:
	GameState.selected_profile = clampi(GameState.selected_profile, 0, CrewData.MAX_RIDERS - 1)
	draft = AvatarData.sanitize(GameState.local_profiles[GameState.selected_profile])
	content.add_child(label("YOUR RIDER", 0, "heading"))
	content.add_child(label("Profile %d · %s" % [GameState.selected_profile + 1, creator_seat_label()], 0, "caption"))
	build_preview(260)
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
	var name_title: Label = label("Name", 0, "caption")
	name_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	options.add_child(name_title)
	name_field = LineEdit.new()
	name_field.placeholder_text = "Your name"
	name_field.max_length = 12
	name_field.text = draft.name
	name_field.custom_minimum_size.y = 120
	name_field.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	options.add_child(name_field)
	for key: String in AvatarData.LIMITS:
		var line: HBoxContainer = row(options)
		button("◀", cycle.bind(key, -1), line).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var value_label: Label = label("")
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(value_label)
		option_labels[key] = value_label
		button("▶", cycle.bind(key, 1), line).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	refresh_labels()
	var actions: HBoxContainer = row()
	button("Randomize", randomize_avatar, actions)
	button("Save", save_avatar, actions, "primary").size_flags_stretch_ratio = 1.4
	save_status = label("", 0, "caption")
	save_status.visible = false
	content.add_child(save_status)
	back_button()

func refresh_labels() -> void:
	for key: String in option_labels:
		var value: String = str(int(draft[key]) + 1)
		var title: String = key.replace("_", " ").capitalize()
		match key:
			"skin":
				title = "Animal"
				value = AvatarData.ANIMALS[draft[key]].capitalize()
			"outfit": value = OUTFIT_NAMES[draft[key]]
			"float_style": value = AvatarData.FLOAT_STYLES[draft[key]].capitalize()
			"hat": value = AvatarData.HATS[draft[key]].capitalize()
			"toot": value = AvatarData.TOOT_COLORS[draft[key]].capitalize()
		option_labels[key].text = "%s\n%s" % [title, value]

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
	content.add_theme_constant_override("separation", 14)
	content.add_child(label("YOUR CREW", 0, "heading"))
	content.add_child(label("Tap a seat to choose who rides", 0, "caption"))
	build_preview(200)
	var seats: GridContainer = GridContainer.new()
	seats.columns = 2
	seats.add_theme_constant_override("h_separation", 14)
	seats.add_theme_constant_override("v_separation", 12)
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
	options.add_theme_constant_override("separation", 14)
	scroll.add_child(options)
	crew_status = label("", 0, "caption")
	options.add_child(crew_status)
	mode_button = button("", cycle_match_mode, options)
	refresh_mode_button()
	var profile_row: HBoxContainer = row(options)
	button("◀", cycle_crew_profile.bind(-1), profile_row).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	crew_profile_label = label("")
	crew_profile_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_row.add_child(crew_profile_label)
	button("▶", cycle_crew_profile.bind(1), profile_row).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	crew_control_button = button("", cycle_control, options)
	var actions: HBoxContainer = row(options)
	button("Edit rider", edit_crew_profile, actions)
	button("Make leader", make_leader, actions)
	button("Control this seat", control_selected_seat, options, "ghost")
	button("Choose course", open_courses.bind("CrewSetup"), options, "ghost")
	options.add_child(label("Assistants are computer riders that push with you.
The leader picks the ring's look.", 0, "caption"))
	# Main action pinned in the thumb zone: one big Start, Practice beside it.
	var play_row: HBoxContainer = row()
	button("Practice", launch_sky.bind(true), play_row)
	button("Start Sky Garden", launch_sky.bind(false), play_row, "primary").size_flags_stretch_ratio = 1.7
	back_button()
	refresh_crew()

func cycle_match_mode() -> void:
	GameState.match_mode = MatchRules.next_mode(GameState.match_mode)
	refresh_mode_button()

func refresh_mode_button() -> void:
	var riders: int = 0
	for slot: Dictionary in GameState.crew_slots:
		if slot.control != "empty":
			riders += 1
	mode_button.text = "Mode: %s" % MatchRules.label(GameState.match_mode)
	if crew_status != null and GameState.match_mode != "coop" and riders < 2:
		crew_status.text = "Add a second rider (or an assistant) to play %s." % MatchRules.label(GameState.match_mode)

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
		if index == selected_seat:
			var picked: StyleBoxFlat = UiTheme.box(Color("fff7d6"), Color("ffb627"), 6, 5)
			crew_buttons[index].add_theme_stylebox_override("normal", picked)
			crew_buttons[index].add_theme_stylebox_override("hover", picked)
		else:
			crew_buttons[index].remove_theme_stylebox_override("normal")
			crew_buttons[index].remove_theme_stylebox_override("hover")
	var slot: Dictionary = GameState.crew_slots[selected_seat]
	crew_status.text = "Seat %d selected" % (selected_seat + 1)
	crew_profile_label.text = "Profile %d\n%s" % [selected_crew_profile() + 1, GameState.local_profiles[selected_crew_profile()].get("name", "Player")]
	crew_control_button.text = "Seat: %s  ▸" % {"empty": "Empty", "local": "Local rider", "assist": "Assistant", "peer": "Peer"}[slot.control]
	if mode_button != null:
		refresh_mode_button()

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

func control_selected_seat() -> void:
	if GameState.crew_slots[selected_seat].control != "local":
		crew_status.text = "Set this seat to Local rider first."
		return
	GameState.active_local_seat = selected_seat
	crew_status.text = "You control seat %d with aim + hold." % (selected_seat + 1)

func launch_sky(practice: bool) -> void:
	var error: String = CampaignFlow.launch_error(GameState, 1, practice)
	if not error.is_empty():
		if crew_status:
			crew_status.text = error
		return
	get_tree().change_scene_to_file(CampaignFlow.prepare_launch(GameState, 1, practice))
