extends "res://scripts/Screen.gd"

# Presentation and user intent only. Net owns membership, permissions and lifecycle.
var message: Label
var ip_field: LineEdit
var slot_labels: Array[Label] = []
var ready_button: Button
var start_button: Button
var course_button: Button
var connection_button: Button
var nearby_box: VBoxContainer

func build_menu() -> void:
	content.add_child(label("Crew lobby" if screen == "Lobby" else "How do you want to play?", 0, "heading"))
	message = label("", 0, "caption")
	content.add_child(message)
	if screen == "Lobby":
		build_lobby()
	else:
		build_modes()

func build_modes() -> void:
	message.text = Net.status_message
	spacer(content, 12)
	# R8: two clearly separated choices, Offline and Online.
	content.add_child(section_title("OFFLINE - no internet needed"))
	button("Play offline", go.bind("CrewSetup"), content, "primary")
	content.add_child(label("Solo, or with computer helper riders", 0, "caption"))
	spacer(content, 24)
	content.add_child(section_title("ONLINE - phones on the same Wi-Fi"))
	button("Host a game", host_crew)
	spacer(content, 12)
	content.add_child(label("Games nearby (tap one to join)", 0, "caption"))
	nearby_box = VBoxContainer.new()
	nearby_box.add_theme_constant_override("separation", 12)
	content.add_child(nearby_box)
	Net.discovery.hosts_changed.connect(refresh_nearby)
	Net.discovery.start_listening()
	refresh_nearby()
	spacer(content, 12)
	content.add_child(label("Nothing showing? Type the host's IP instead:", 0, "caption"))
	var join_row: HBoxContainer = row()
	ip_field = LineEdit.new()
	ip_field.placeholder_text = "Host IP, e.g. 192.168.1.10"
	ip_field.custom_minimum_size.y = 120
	ip_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ip_field.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
	join_row.add_child(ip_field)
	connection_button = button("Join", join_crew, join_row)
	connection_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	connection_button.custom_minimum_size.x = 170
	# Connection feedback sits right under the Join row, where the player is looking.
	content.remove_child(message)
	content.add_child(message)
	message.add_theme_color_override("font_color", Color("b23a33"))
	spacer()
	back_button()
	set_process(true)

func build_lobby() -> void:
	build_preview(220)
	var slots: GridContainer = GridContainer.new()
	slots.columns = 2
	content.add_child(slots)
	for seat: int in range(4):
		var item: Label = label("", 28)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.custom_minimum_size = Vector2(280, 80)
		item.clip_text = true
		slots.add_child(item)
		slot_labels.append(item)
	course_button = button("", cycle_course)
	ready_button = button("", toggle_ready)
	start_button = button("Start together", Net.start_run, content, "primary")
	button("Back / leave crew", back, content, "ghost")
	Net.lobby_changed.connect(refresh_lobby)
	refresh_lobby()

func section_title(text: String) -> Label:
	var title: Label = label(text, 0, "caption")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return title

func refresh_nearby() -> void:
	if not is_instance_valid(nearby_box):
		return
	for child: Node in nearby_box.get_children():
		nearby_box.remove_child(child)
		child.queue_free()
	var found: Array[Dictionary] = Net.discovery.sorted_hosts()
	if found.is_empty():
		nearby_box.add_child(label("Searching... ask a friend to tap Host a game.", 0, "caption"))
		return
	for host_info: Dictionary in found:
		button("Join %s's game" % host_info.name, join_address.bind(host_info.ip), nearby_box, "primary")

func join_address(address: String) -> void:
	if Net.join(address, GameState.avatar) != OK:
		message.text = Net.status_message

func _exit_tree() -> void:
	if Net.discovery.hosts_changed.is_connected(refresh_nearby):
		Net.discovery.hosts_changed.disconnect(refresh_nearby)
	if screen == "ModeSelect":
		Net.discovery.stop_listening()

func host_crew() -> void:
	if Net.host(GameState.avatar) == OK:
		go("Lobby")
	else:
		message.text = Net.status_message

func join_crew() -> void:
	join_address(ip_field.text)

func refresh_lobby() -> void:
	if not Net.active:
		return
	var crew: Array[Dictionary] = Net.crew_slots()
	model.configure(Net.profiles, crew, 0)
	for seat: int in range(4):
		var owner: int = Net.owners[seat]
		slot_labels[seat].text = "%d. Vacant" % (seat + 1) if owner == 0 else "%d. %s\n%s%s" % [seat + 1, Net.profiles[seat].name, "Ready" if Net.ready_peers.get(owner, false) else "Not ready", " (you)" if seat == Net.local_seat() else ""]
	course_button.text = "Course %d: %s%s" % [Net.course_number, LevelDefs.LEVELS[Net.course_number - 1].name, " / change" if Net.hosting else ""]
	course_button.disabled = not Net.hosting
	course_button.add_theme_font_size_override("font_size", 28)
	ready_button.text = "Ready: %s" % ("Yes" if Net.ready_peers.get(Net.multiplayer.get_unique_id(), false) else "No")
	start_button.visible = Net.hosting
	start_button.disabled = not Net.can_start()
	var addresses: Array[String] = []
	if Net.hosting:
		for address: String in IP.get_local_addresses():
			if address.contains(".") and not address.begins_with("127.") and not address.begins_with("169.254."):
				addresses.append(address)
	message.text = ("Host IP: " + ", ".join(addresses) + "\n" if Net.hosting else "Host chooses the course and starts.\n") + "2-4 riders / lost guest seat becomes vacant"

func toggle_ready() -> void:
	Net.set_ready(not Net.ready_peers.get(Net.multiplayer.get_unique_id(), false))

func cycle_course() -> void:
	Net.choose_course(Net.course_number % clampi(GameState.unlocked_level, 1, 5) + 1)

func _process(_delta: float) -> void:
	if screen != "ModeSelect" or not is_instance_valid(connection_button):
		return
	var connecting: bool = Net.active and Net.phase == "connecting"
	connection_button.disabled = connecting
	connection_button.text = "..." if connecting else "Join"
	if connecting:
		message.text = "Connecting to the host... Back cancels."

func back() -> void:
	if Net.active:
		Net.leave("You left the crew.")
	else:
		go("MainMenu")
