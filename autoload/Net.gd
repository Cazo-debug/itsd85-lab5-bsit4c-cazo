extends Node

# Transport and session application layer. No Controls and no persistent crew writes.
signal lobby_changed
signal session_closed(message: String)
const PORT: int = 7777
const MAX_CLIENTS: int = 3
const CONNECT_TIMEOUT_MS: int = 5000 # lab PDF p. 18: 5-second join timer
const SILENCE_TIMEOUT_MS: int = 8000
const LOAD_TIMEOUT_MS: int = 15000
var active: bool = false
var hosting: bool = false
var phase: String = "idle"
var status_message: String = ""
var owners: Array[int] = [0, 0, 0, 0]
var profiles: Array[Dictionary] = CrewData.default_profiles()
var ready_peers: Dictionary = {}
var loaded: Dictionary = {}
var pending: Dictionary = {}
var course_number: int = 1
var round_id: int = 0
var run_ready: bool = false
var level: Node3D
var gate: NetInputGate = NetInputGate.new()
var replication: RingReplication = RingReplication.new()
var navigating: bool = true
var local_avatar: Dictionary = {}
var previous_mode: String = "offline"
var previous_result: Dictionary = {}
var deadline: int = 0
var last_snapshot_at: int = 0
var tick: int = 0
var snapshot_elapsed: float = 0
var send_elapsed: float = 0
var sequence: int = 0
var desired: Dictionary = {}
var last_held: bool = false
var input_enabled: bool = true
var accepted_inputs: int = 0
var last_host_at: int = 0
var last_heartbeat_at: int = 0
var discovery: LanDiscovery = LanDiscovery.new()

func _ready() -> void:
	process_physics_priority = 100
	add_child(discovery)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_lost)
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_left)

func host(avatar: Dictionary, port: int = PORT) -> Error:
	close_session()
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, MAX_CLIENTS, 3)
	if error != OK:
		status_message = "Could not host. Port %d may already be in use." % port
		return error
	begin_session(true, avatar)
	multiplayer.multiplayer_peer = peer
	owners[0] = 1
	profiles[0] = local_avatar
	ready_peers[1] = true
	discovery.start_announcing(str(local_avatar.get("name", "Player")))
	lobby_changed.emit()
	return OK

func join(address: String, avatar: Dictionary, port: int = PORT) -> Error:
	close_session()
	if not address.strip_edges().is_valid_ip_address():
		status_message = "Enter the host's Wi-Fi IP address."
		return ERR_INVALID_PARAMETER
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address.strip_edges(), port, 3)
	if error != OK:
		status_message = "Could not connect. Check the host IP and Wi-Fi."
		return error
	begin_session(false, avatar)
	phase = "connecting"
	multiplayer.multiplayer_peer = peer
	deadline = Time.get_ticks_msec() + CONNECT_TIMEOUT_MS
	return OK

func begin_session(is_host: bool, avatar: Dictionary) -> void:
	active = true
	hosting = is_host
	phase = "lobby"
	status_message = ""
	local_avatar = AvatarData.sanitize(avatar)
	previous_mode = GameState.mode
	previous_result = GameState.last_result.duplicate(true)
	GameState.mode = "online"
	input_enabled = true
	accepted_inputs = 0
	course_number = 1
	round_id = 0
	last_host_at = Time.get_ticks_msec()
	last_heartbeat_at = 0

func close_session(message: String = "") -> void:
	discovery.stop_announcing()
	if is_instance_valid(level):
		level.player.release_all_inputs()
		level.player.simulate = false
		level.player.freeze = true
		level.hud.controls.enabled = false
	level = null
	if active:
		GameState.mode = previous_mode
		GameState.last_result = previous_result.duplicate(true)
	active = false
	hosting = false
	phase = "idle"
	run_ready = false
	deadline = 0
	owners.assign([0, 0, 0, 0])
	profiles = CrewData.default_profiles()
	ready_peers.clear()
	loaded.clear()
	pending.clear()
	desired.clear()
	gate.reset()
	replication.reset()
	sequence = 0
	last_held = false
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	status_message = message

func leave(message: String = "") -> void:
	close_session(message)
	session_closed.emit(message)
	if navigating:
		get_tree().change_scene_to_file.call_deferred("res://scenes/ui/ModeSelect.tscn")

func local_seat() -> int:
	return owners.find(multiplayer.get_unique_id()) if active and phase != "connecting" else -1

func crew_slots() -> Array[Dictionary]:
	var crew: Array[Dictionary] = []
	for seat: int in range(4):
		crew.append(CrewData.empty_slot() if owners[seat] == 0 else CrewData.make_slot("local" if owners[seat] == 1 else "peer", seat, str(owners[seat])))
	return crew

func can_start() -> bool:
	if not active or not hosting or phase != "lobby" or owners.count(0) > 2 or not pending.is_empty():
		return false
	for owner: int in owners:
		if owner != 0 and not ready_peers.get(owner, false):
			return false
	return true

func choose_course(number: int) -> void:
	if hosting and phase == "lobby" and number >= 1 and number <= LevelDefs.LEVELS.size() and GameState.is_unlocked(number):
		course_number = number
		broadcast_lobby()

func set_ready(value: bool) -> void:
	if not active or phase != "lobby":
		return
	if hosting:
		ready_peers[1] = value
		broadcast_lobby()
	else:
		_ready_request.rpc_id(1, value)

func start_run() -> void:
	if can_start():
		launch_round()

func launch_round() -> void:
	# Called only by the host after all current lobby members are ready.
	discovery.stop_announcing()
	round_id += 1
	_launch.rpc(round_id, course_number)
	prepare_round(round_id, course_number)

func prepare_round(number: int, course_id: int) -> void:
	round_id = number
	course_number = course_id
	phase = "loading"
	run_ready = false
	loaded.clear()
	desired.clear()
	gate.reset()
	replication.reset()
	sequence = 0
	tick = 0
	snapshot_elapsed = 0
	send_elapsed = 0
	last_held = false
	deadline = Time.get_ticks_msec() + LOAD_TIMEOUT_MS
	level = null
	if navigating:
		get_tree().change_scene_to_file.call_deferred(GameState.level_scene_path(course_number))

func attach_level(value: Node3D) -> void:
	level = value
	if hosting:
		loaded[1] = true
		try_begin()
	else:
		_loaded.rpc_id(1, round_id)

func try_begin() -> void:
	for owner: int in owners:
		if owner != 0 and not loaded.get(owner, false):
			return
	_begin.rpc(round_id)
	begin_round()

func begin_round() -> void:
	run_ready = true
	phase = "run"
	deadline = 0
	last_snapshot_at = Time.get_ticks_msec()

func submit_input(seat: int, direction: Vector3, strength: float, held: bool) -> void:
	if not active or seat != local_seat() or not input_enabled:
		return
	desired = {"seat": seat, "direction": direction, "strength": strength, "held": held}
	if last_held and not held:
		send_input(true)
	last_held = held

func release_local() -> void:
	var seat: int = local_seat()
	if seat < 0:
		return
	desired = {"seat": seat, "direction": Vector3.ZERO, "strength": 0.0, "held": false}
	last_held = false
	send_input(true)

func send_input(reliable: bool = false) -> void:
	if desired.is_empty() or phase != "run":
		return
	sequence += 1
	var packet: Dictionary = desired.duplicate()
	packet.merge({"round": round_id, "seq": sequence})
	if hosting:
		receive_input(1, packet)
	elif reliable:
		_release.rpc_id(1, packet)
	else:
		_input_state.rpc_id(1, packet)

func receive_input(peer: int, packet: Dictionary) -> bool:
	if not hosting or not is_instance_valid(level) or not run_ready:
		return false
	var clean: Dictionary = gate.accept(peer, packet, owners, round_id, Time.get_ticks_msec(), level.player.gas, level.state == level.State.RACING and not level.player.falling)
	if clean.is_empty():
		return false
	accepted_inputs += 1
	return level.player.set_thrust_input(clean.seat, clean.direction, clean.strength, clean.held)

func request_action(action: String) -> void:
	if not active:
		return
	if action == "leave":
		leave("You left the crew.")
	elif hosting:
		apply_action(1, action)
	else:
		_action.rpc_id(1, round_id, action)

func apply_action(sender: int, action: String) -> void:
	if not hosting or sender not in owners or not is_instance_valid(level):
		return
	match action:
		"pause":
			# Any rider can stop the shared clock; only the host resumes it.
			if level.state == level.State.RACING:
				level.toggle_pause_authority()
			elif sender == 1 and level.state == level.State.PAUSED:
				level.toggle_pause_authority()
		"recover":
			if sender == 1:
				level.recover_authority()
		"rematch":
			if sender == 1 and level.state in [level.State.PAUSED, level.State.FINISHED]:
				launch_round()
		"lobby":
			if sender == 1 and level.state == level.State.FINISHED:
				_to_lobby.rpc()
				return_to_lobby()
	if phase == "run":
		publish(true)

func return_to_lobby() -> void:
	release_local()
	if is_instance_valid(level):
		level.player.release_all_inputs()
		level.player.simulate = false
		level.player.freeze = true
	level = null
	phase = "lobby"
	run_ready = false
	ready_peers.clear()
	ready_peers[1] = true
	if hosting:
		discovery.start_announcing(str(local_avatar.get("name", "Player")))
	if navigating:
		get_tree().change_scene_to_file.call_deferred("res://scenes/ui/Lobby.tscn")
	lobby_changed.emit()

func publish(reliable: bool = false) -> void:
	if not hosting or not is_instance_valid(level) or phase != "run":
		return
	tick += 1
	var snapshot: Dictionary = RingReplication.capture(level, round_id, tick)
	if reliable:
		_important_snapshot.rpc(snapshot)
	else:
		_snapshot.rpc(snapshot)

func broadcast_lobby() -> void:
	_lobby.rpc(owners, profiles, ready_peers, course_number)
	lobby_changed.emit()

func _process(delta: float) -> void:
	if not active:
		return
	var now: int = Time.get_ticks_msec()
	if deadline > 0 and now > deadline:
		leave("Connection timed out. Check Wi-Fi and the host IP, then try again.")
		return
	if hosting:
		if now - last_heartbeat_at > 1000:
			last_heartbeat_at = now
			_heartbeat.rpc()
		for peer: int in pending.keys():
			if now > int(pending[peer]):
				multiplayer.multiplayer_peer.disconnect_peer(peer)
	elif phase != "connecting" and now - last_host_at > SILENCE_TIMEOUT_MS:
		leave("The host stopped responding. Please reconnect from Mode Select.")
		return
	if phase != "run" or not is_instance_valid(level):
		return
	send_elapsed += delta
	if input_enabled and send_elapsed >= 1.0 / 30.0:
		send_elapsed = 0
		send_input()
	if not hosting:
		replication.apply(level, now / 1000.0)
		level.hud.present(level.run_snapshot())

func _physics_process(delta: float) -> void:
	if not active or not hosting or phase != "run" or not is_instance_valid(level):
		return
	var now: int = Time.get_ticks_msec()
	for seat: int in range(4):
		if owners[seat] != 0 and gate.expired(seat, now):
			level.player.set_thrust_input(seat, Vector3.ZERO, 0, false)
	snapshot_elapsed += delta
	if snapshot_elapsed >= 0.05:
		snapshot_elapsed = 0
		publish()

func _connected() -> void:
	_hello.rpc_id(1, local_avatar)

func _connection_failed() -> void:
	if active:
		leave("Could not reach the host. Check its IP, Wi-Fi and port 7777.")

func _server_lost() -> void:
	if active and not hosting:
		leave("Host disconnected. Your offline progress is safe.")

func _peer_connected(peer: int) -> void:
	if hosting:
		if phase != "lobby":
			multiplayer.multiplayer_peer.disconnect_peer(peer)
		else:
			pending[peer] = Time.get_ticks_msec() + CONNECT_TIMEOUT_MS

func _peer_left(peer: int) -> void:
	if not active or not hosting:
		return
	pending.erase(peer)
	ready_peers.erase(peer)
	loaded.erase(peer)
	var seat: int = owners.find(peer)
	if seat >= 0:
		owners[seat] = 0
		if is_instance_valid(level):
			level.player.set_thrust_input(seat, Vector3.ZERO, 0, false)
			level.player.seat_control[seat] = "empty"
			level.player.slots[seat] = CrewData.empty_slot()
			level.player.visual.configure(profiles, crew_slots(), 0)
			level.player.visual.bake_moving_parts()
		broadcast_lobby()
	if phase == "loading" and is_instance_valid(level):
		try_begin()

@rpc("any_peer", "call_remote", "reliable", 0)
func _hello(avatar: Variant) -> void:
	var peer: int = multiplayer.get_remote_sender_id()
	if not hosting or phase != "lobby" or peer not in pending or peer in owners:
		return
	var seat: int = owners.find(0)
	if seat < 0:
		return
	owners[seat] = peer
	profiles[seat] = AvatarData.sanitize(avatar)
	ready_peers[peer] = false
	pending.erase(peer)
	broadcast_lobby()

@rpc("authority", "call_remote", "reliable", 0)
func _lobby(new_owners: Array, avatars: Array, readiness: Dictionary, number: int) -> void:
	if not active or hosting:
		return
	owners.assign(new_owners)
	profiles = CrewData.sanitize_profiles(avatars)
	ready_peers = readiness.duplicate()
	last_host_at = Time.get_ticks_msec()
	course_number = number
	if phase == "connecting":
		phase = "lobby"
		deadline = 0
		if navigating:
			get_tree().change_scene_to_file.call_deferred("res://scenes/ui/Lobby.tscn")
	if is_instance_valid(level):
		var crew: Array[Dictionary] = crew_slots()
		for seat: int in range(4):
			level.player.seat_control[seat] = crew[seat].control
		level.player.slots = crew
		level.player.visual.configure(profiles, crew, 0)
		level.player.visual.bake_moving_parts()
	lobby_changed.emit()

@rpc("any_peer", "call_remote", "reliable", 0)
func _ready_request(value: bool) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if hosting and phase == "lobby" and sender in owners:
		ready_peers[sender] = value
		broadcast_lobby()

@rpc("authority", "call_remote", "reliable", 0)
func _launch(number: int, course_id: int) -> void:
	if active and not hosting:
		prepare_round(number, course_id)

@rpc("any_peer", "call_remote", "reliable", 0)
func _loaded(number: int) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if hosting and phase == "loading" and number == round_id and sender in owners:
		loaded[sender] = true
		if is_instance_valid(level):
			try_begin()

@rpc("authority", "call_remote", "reliable", 0)
func _begin(number: int) -> void:
	if active and not hosting and number == round_id and is_instance_valid(level):
		begin_round()

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _input_state(packet: Dictionary) -> void:
	receive_input(multiplayer.get_remote_sender_id(), packet)

@rpc("any_peer", "call_remote", "reliable", 0)
func _release(packet: Dictionary) -> void:
	if not packet.get("held", true):
		receive_input(multiplayer.get_remote_sender_id(), packet)

@rpc("any_peer", "call_remote", "reliable", 0)
func _action(number: int, action: String) -> void:
	if number == round_id:
		apply_action(multiplayer.get_remote_sender_id(), action)

@rpc("authority", "call_remote", "unreliable_ordered", 2)
func _snapshot(snapshot: Dictionary) -> void:
	receive_snapshot(snapshot)

@rpc("authority", "call_remote", "reliable", 0)
func _important_snapshot(snapshot: Dictionary) -> void:
	receive_snapshot(snapshot)

func receive_snapshot(snapshot: Dictionary) -> void:
	if active and not hosting and snapshot.get("round", -1) == round_id and is_instance_valid(level):
		if replication.push(snapshot, Time.get_ticks_msec() / 1000.0):
			last_snapshot_at = Time.get_ticks_msec()
			last_host_at = last_snapshot_at
			replication.apply(level, last_snapshot_at / 1000.0)

@rpc("authority", "call_remote", "unreliable", 2)
func _heartbeat() -> void:
	if active and not hosting:
		last_host_at = Time.get_ticks_msec()

@rpc("authority", "call_remote", "reliable", 0)
func _to_lobby() -> void:
	if active and not hosting:
		return_to_lobby()
