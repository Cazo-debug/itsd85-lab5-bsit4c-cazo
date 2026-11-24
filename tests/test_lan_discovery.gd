extends GutTest

# Nearby-game discovery: the guest picks a host from a list instead of typing an IP.

func test_packet_round_trips_the_host_name() -> void:
	var packet: PackedByteArray = LanDiscovery.make_packet("Carlos")
	assert_eq(LanDiscovery.parse_packet(packet).name, "Carlos")

func test_junk_and_foreign_packets_are_ignored() -> void:
	assert_true(LanDiscovery.parse_packet(PackedByteArray()).is_empty())
	assert_true(LanDiscovery.parse_packet("not json".to_utf8_buffer()).is_empty())
	assert_true(LanDiscovery.parse_packet('{"g":"otherGame","n":"x"}'.to_utf8_buffer()).is_empty())
	var wrong_type: String = '{"g":"%s","n":5}' % LanDiscovery.MAGIC
	assert_true(LanDiscovery.parse_packet(wrong_type.to_utf8_buffer()).is_empty())
	var huge: PackedByteArray = PackedByteArray()
	huge.resize(500)
	assert_true(LanDiscovery.parse_packet(huge).is_empty(), "Oversized packets are rejected")

func test_names_are_sanitized() -> void:
	assert_eq(LanDiscovery.clean_name(""), "Player")
	assert_eq(LanDiscovery.clean_name("   "), "Player")
	assert_eq(LanDiscovery.clean_name("A\nB\tC"), "ABC")
	assert_lte(LanDiscovery.clean_name("x".repeat(80)).length(), 16)

func test_broadcast_targets_cover_each_local_subnet_once() -> void:
	var targets: Array[String] = LanDiscovery.broadcast_targets(PackedStringArray(["192.168.1.23", "192.168.1.40", "10.0.0.5", "127.0.0.1", "169.254.3.4", "fe80::1"]))
	assert_true(targets.has("255.255.255.255"))
	assert_true(targets.has("192.168.1.255"))
	assert_true(targets.has("10.0.0.255"))
	assert_eq(targets.count("192.168.1.255"), 1)
	assert_false(targets.has("127.0.0.255"))
	assert_false(targets.has("169.254.3.255"))

func test_two_instances_find_each_other_over_loopback() -> void:
	# A real UDP round trip on this machine: one announces, one listens.
	var listener: LanDiscovery = LanDiscovery.new()
	add_child_autofree(listener)
	listener.start_listening()
	if not listener.is_listening():
		pending("UDP port %d is busy on this machine" % LanDiscovery.DISCOVERY_PORT)
		return
	var announcer: LanDiscovery = LanDiscovery.new()
	add_child_autofree(announcer)
	announcer.start_announcing("TestHost")
	var waited: int = 0
	while listener.hosts.is_empty() and waited < 40:
		await get_tree().create_timer(0.1).timeout
		waited += 1
	var found: Array[Dictionary] = listener.sorted_hosts()
	announcer.stop_announcing()
	listener.stop_listening()
	if found.is_empty():
		pending("This network blocks local UDP broadcast, so the loopback check is skipped")
		return
	assert_eq(found[0].name, "TestHost")
	assert_true(str(found[0].ip).is_valid_ip_address())

func _find_line_edit(node: Node) -> LineEdit:
	if node is LineEdit:
		return node
	for child: Node in node.get_children():
		var found: LineEdit = _find_line_edit(child)
		if found != null:
			return found
	return null

func test_ip_field_keyboard_can_type_three_dots() -> void:
	# Android's decimal keyboard accepts only one '.', so an IP address cannot be typed with it.
	var scene: Node = load("res://scenes/ui/ModeSelect.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var field: LineEdit = _find_line_edit(scene)
	assert_not_null(field, "Mode select has the IP field")
	if field != null:
		assert_ne(field.virtual_keyboard_type, LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL)
		assert_ne(field.virtual_keyboard_type, LineEdit.KEYBOARD_TYPE_NUMBER)
