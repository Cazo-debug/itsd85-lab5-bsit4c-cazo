extends SceneTree

# Separate-process ENet checks. Drivers submit normal seat input; no race teleports.
var net: Node
var game: Node
var role: String = "host"
var index: int = 0
var players: int = 2
var output: String = ".bin/net-smoke"
var scenario: String = "crew"
var match_mode: String = "coop"
var port: int = 7777
var failures: Array[String] = []
var checks: int = 0
var reports: Array[Dictionary] = []
var save_path: String
var original: String
var resting: bool = false
var last_round: int = 0
var first_result: Dictionary = {}
var first_finish_at: int = 0
var forged: bool = false
var expiry_checked: bool = false
var saw_pause: bool = false
var pause_at: int = 0
var resumed: bool = false
var guest_left: bool = false
var host_left_at: int = 0
var disconnected_at: int = 0
var release_checked: bool = false
var gas_used: bool = false
var movement_seen: bool = false
var shared_height_seen: bool = false
var round_started_at: int = 0
var diagnostic_at: int = 0
var loss_hold_seen: bool = false
var explicit_hold_seen: bool = false
var loss_seat: int = 1
var departing_seat: int = 1
var explicit_received_at: int = 0
var release_race_time: float = -1.0
var loss_started_at: int = 0

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--role="): role = argument.trim_prefix("--role=")
		if argument.begins_with("--index="): index = int(argument.trim_prefix("--index="))
		if argument.begins_with("--players="): players = int(argument.trim_prefix("--players="))
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		if argument.begins_with("--scenario="): scenario = argument.trim_prefix("--scenario=")
		if argument.begins_with("--mode="): match_mode = argument.trim_prefix("--mode=")
		if argument.begins_with("--port="): port = int(argument.trim_prefix("--port="))
	call_deferred("verify")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func verify() -> void:
	net = root.get_node("Net")
	game = root.get_node("GameState")
	save_path = "user://phase4_smoke_%s_%d_%d.cfg" % [scenario, players, index]
	game.persistence_path = save_path
	game.local_profiles = CrewData.default_profiles()
	game.set_profile(0, AvatarData.default_avatar())
	game.crew_slots = CrewData.default_slots()
	game.unlocked_level = 1
	game.best_times = {}
	game.best_stars = {}
	game.seen_tutorial = true
	game.last_result = {"offline": true}
	check(game.save_progress(save_path) == OK, "Disposable save created")
	original = FileAccess.get_file_as_string(save_path)
	var avatar: Dictionary = {"name": "\nCrew %d" % index, "skin": 999, "outfit": index, "extra": 99}
	if scenario == "unreachable":
		check(net.join("127.0.0.1", avatar, port) == OK, "Unreachable client starts without OS dialog")
	else:
		check((net.host(avatar, port) if role == "host" else net.join("127.0.0.1", avatar, port)) == OK, "ENet starts")
	var deadline: int = Time.get_ticks_msec() + 160000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if Time.get_ticks_msec() > diagnostic_at + 5000:
			diagnostic_at = Time.get_ticks_msec()
			print("%s %d: %s owners=%s ready=%s" % [role, index, net.phase, net.owners, net.ready_peers])
			if is_instance_valid(net.level):
				print("  state=%d race=%.2f s=%.2f held=%s gas=%s" % [net.level.state, net.level.race_time, net.level.player.route_s, net.level.player.held, net.level.player.gas])
		if scenario == "unreachable":
			if not net.active:
				await process_frame
				check(not net.status_message.is_empty(), "Connection failure has an in-game explanation")
				check(current_scene != null and current_scene.name == "ModeSelect", "Unreachable IP returns to Mode Select")
				finish()
				return
			continue
		if not net.active:
			if scenario == "host_loss":
				check(role == "guest" and net.status_message.to_lower().contains("host"), "Abrupt host loss ends with a clear in-game error")
			elif role == "host":
				check(host_left_at > 0, "Host exits deliberately")
			elif index == players - 1:
				check(disconnected_at > 0, "Guest exits deliberately")
			else:
				check(not net.status_message.is_empty(), "Host loss is explained")
			await process_frame
			check(current_scene != null and current_scene.name == "ModeSelect", "Leave/host loss reaches Mode Select")
			finish()
			return
		if net.phase == "lobby":
			if scenario == "host_loss":
				if role == "host" and net.owners.count(0) == 2:
					check(FileAccess.get_file_as_string(save_path) == original, "Host crash fixture preserved save")
					DirAccess.remove_absolute(save_path)
					var marker: FileAccess = FileAccess.open(output + "/ready.flag", FileAccess.WRITE)
					marker.store_string("ready")
					marker.close()
					# Parent kills this process without sending an ENet close packet.
					await create_timer(20.0, true, false, true).timeout
				continue
			if role == "host" and net.owners.count(0) == 4 - players and net.can_start():
				check(net.profiles[1].skin == 5 and not net.profiles[1].has("extra"), "Host sanitized remote avatar")
				net.choose_mode(match_mode)
				net.start_run()
				print("Host starts shared run with %d peers" % players)
			elif role != "host" and net.local_seat() >= 0:
				if not net.ready_peers.get(net.multiplayer.get_unique_id(), false): net.set_ready(true)
			continue
		if not is_instance_valid(net.level) or not net.run_ready:
			continue
		var level: Node3D = net.level
		level.hud.controls.enabled = false
		# Snapshots restore the gameplay enabled flag. This fixture owns the
		# input stream, so the idle UI must not publish competing releases.
		level.hud.controls.set_physics_process(false)
		if last_round != net.round_id:
			last_round = net.round_id
			print("%s %d loaded round %d" % [role, index, last_round])
			round_started_at = Time.get_ticks_msec()
			check(count_rings(level) == 1, "Exactly one shared body per process")
			check(level.checkpoint_index == 0 and level.race_time < 1, "Round starts with reset clock/checkpoints")
			if role == "host":
				for seat: int in range(4):
					if net.profiles[seat].get("name") == "Crew 1": loss_seat = seat
					if net.profiles[seat].get("name") == "Crew %d" % (players - 1): departing_seat = seat
			if role != "host":
				check(not level.player.simulate and level.player.freeze and level.player.collision_layer == 0, "Guest never simulates collision authority")
		if level.state == level.State.PAUSED:
			saw_pause = true
			if role == "host" and Time.get_ticks_msec() - pause_at > 500:
				net.request_action("pause")
				resumed = true
			continue
		if level.state == level.State.FINISHED:
			if first_result.is_empty():
				first_result = level.result.duplicate(true)
				print("%s %d result: %s" % [role, index, first_result])
				first_finish_at = Time.get_ticks_msec()
				check(first_result.get("won", false), "Crew completes course using sustained network inputs")
				check(not first_result.get("saved", true) and not first_result.has("place"), "Cooperative online result has no place or progress write")
				check(first_result.get("mode", "") == match_mode, "Every phone shows the mode the host chose (%s)" % match_mode)
				check(first_result.get("stars_collected", -1) == int(first_result.get("scores", [0]).reduce(func(a: int, b: int) -> int: return a + b, 0)), "Result star total matches the per-seat scores")
				check(not str(first_result.get("headline", "")).is_empty() and first_result.get("lines", []).size() >= 1, "Result carries the host headline and standings")
				check(level.checkpoint_index == 2, "Both ordered checkpoints reached")
				check(movement_seen and shared_height_seen and gas_used, "3D motion and per-seat gas replicated")
				if role == "host":
					check(expiry_checked, "Lost-release fixture reached the real expiry deadline")
					check(net.gate.rejected >= players - 1, "Forged guest-owned-seat requests rejected")
					for seat: int in range(players):
						check(level.player.force_seconds[seat] > 1, "Each human seat contributes physical force")
			if role == "host" and Time.get_ticks_msec() - first_finish_at > 800:
				net.request_action("rematch")
			continue
		if level.state != level.State.RACING:
			continue
		movement_seen = movement_seen or level.player.linear_velocity.length() > 1
		shared_height_seen = shared_height_seen or level.player.position.y > 9
		gas_used = gas_used or level.player.gas[net.local_seat()] < 0.9
		if role != "host" and not forged:
			forged = true
			net.rpc_id(1, "_input_state", {"seat": 0, "round": net.round_id, "seq": 10000, "direction": Vector3.FORWARD, "strength": 1.0, "held": true})
			# Also deliver an unowned release reliably. The one-shot unreliable
			# thrust packet can be superseded by a newer ordinary input packet;
			# neither forged packet may acquire the host's seat or sequence.
			net.rpc_id(1, "_release", {"seat": 0, "round": net.round_id, "seq": 10001, "direction": Vector3.FORWARD, "strength": 1.0, "held": false})
		if net.round_id == 1:
			# Synchronize on observed packets, not narrow race-clock windows. Guest
			# interpolation and process scheduling can legitimately lag the host.
			if role == "host" and not release_checked:
				if not explicit_hold_seen and level.player.held[loss_seat]:
					explicit_hold_seen = true
					explicit_received_at = int(net.gate.received_at[loss_seat])
					write_marker("explicit-held.flag", "held")
				if explicit_hold_seen and FileAccess.file_exists(output + "/explicit-sent.flag") and not level.player.held[loss_seat] and int(net.gate.received_at[loss_seat]) > explicit_received_at:
					release_checked = true
					check(not net.gate.expired(loss_seat, Time.get_ticks_msec()), "Explicit release stops held thrust before expiry")
					release_race_time = level.race_time
					loss_started_at = Time.get_ticks_msec()
					write_marker("explicit-received.flag", str(release_race_time))
				elif Time.get_ticks_msec() - round_started_at > 8000:
					check(false, "Explicit held/release packet handshake timed out")
					await finish()
					return
			if role != "host" and index == 1 and release_race_time < 0:
				if FileAccess.file_exists(output + "/explicit-received.flag"):
					release_race_time = float(FileAccess.get_file_as_string(output + "/explicit-received.flag"))
					net.input_enabled = true
				elif FileAccess.file_exists(output + "/explicit-held.flag"):
					if net.input_enabled:
						net.release_local()
						net.input_enabled = false
						write_marker("explicit-sent.flag", "sent")
					continue
				else:
					net.submit_input(net.local_seat(), level.course.path.sample(level.player.route_s + 5).tangent, 1.0, true)
					continue
			# The host must observe this new hold before the guest stops refreshing.
			# A race-clock window could expire the preceding explicit release while
			# a slower guest had not yet delivered the lost-release test's hold.
			if role != "host" and index == 1 and release_race_time >= 0 and not FileAccess.file_exists(output + "/loss-expired.flag"):
				if not FileAccess.file_exists(output + "/loss-held.flag"):
					net.submit_input(net.local_seat(), level.course.path.sample(level.player.route_s + 5).tangent, 1.0, true)
				elif net.input_enabled:
					net.send_input()
					net.input_enabled = false # Deliberately lose the release and all refresh packets.
					write_marker("loss-muted.flag", "muted")
				continue
			if role != "host" and index == 1 and FileAccess.file_exists(output + "/loss-expired.flag"):
				net.input_enabled = true
			if role == "host" and release_checked and not expiry_checked:
				if not loss_hold_seen and level.player.held[loss_seat]:
					loss_hold_seen = true
					write_marker("loss-held.flag", "held")
				if loss_hold_seen and FileAccess.file_exists(output + "/loss-muted.flag") and net.gate.expired(loss_seat, Time.get_ticks_msec() - 80):
					expiry_checked = true
					check(loss_hold_seen and not level.player.held[loss_seat], "Lost release expires on host without sticking thrust")
					write_marker("loss-expired.flag", "expired")
				elif Time.get_ticks_msec() - loss_started_at > 8000:
					check(false, "Lost held/expiry packet handshake timed out")
					await finish()
					return
		else:
			if role == "host" and pause_at == 0 and level.race_time > 1:
				pause_at = Time.get_ticks_msec()
				net.request_action("pause")
			if role != "host" and index == players - 1 and level.race_time > 3:
				check(saw_pause, "Shared pause reached guest before resume")
				disconnected_at = Time.get_ticks_msec()
				net.request_action("leave")
				continue
			if role == "host" and net.owners.count(0) == 5 - players:
				if not guest_left:
					guest_left = true
					host_left_at = Time.get_ticks_msec()
					check(not level.player.held[departing_seat] and level.player.seat_control[departing_seat] == "empty", "Disconnected guest becomes vacant and releases force")
					check(level.player.visual.riders.size() == players - 1, "Disconnected rider removed from shared visual")
					check(saw_pause and resumed, "Host pause/resume synchronizes the shared clock")
				if Time.get_ticks_msec() - host_left_at > 1000:
					net.request_action("leave")
					continue
		drive(level)
	check(false, "Smoke peer timed out in %s / round %d" % [net.phase, net.round_id])
	finish()

func drive(level: Node3D) -> void:
	var seat: int = net.local_seat()
	if seat < 0:
		return
	var ring: Node3D = level.player
	var target: Dictionary = ring.path.sample(ring.route_s + 5.5)
	var correction: Vector3 = (target.position - ring.position).normalized() * 7.2 - ring.linear_velocity
	if ring.gas[seat] < 0.15 or ring.depleted[seat]: resting = true
	if ring.gas[seat] >= 0.65: resting = false
	var pulse: bool = fmod(level.race_time + seat * 0.11, 2.0) < 1.65
	net.submit_input(seat, correction.normalized(), clampf(correction.length() / 7, 0, 1), not resting and pulse)

func count_rings(node: Node) -> int:
	var count: int = 1 if node.get_script() == load("res://scripts/SwimRing.gd") else 0
	for child: Node in node.get_children(): count += count_rings(child)
	return count

func write_marker(filename: String, value: String) -> void:
	var file: FileAccess = FileAccess.open(output + "/" + filename, FileAccess.WRITE)
	if file:
		file.store_string(value)
		file.close()

func finish() -> void:
	check(FileAccess.get_file_as_string(save_path) == original, "Offline save remains byte-for-byte unchanged")
	if net.active: net.close_session()
	check(game.mode == "offline" and game.last_result == {"offline": true}, "Leaving restores offline mode and prior result")
	var report: Dictionary = {"passed": failures.is_empty(), "role": role, "index": index, "players": players,
		"scenario": scenario, "checks": checks, "failures": failures, "result": first_result,
		"observed": {"movement": movement_seen, "height": shared_height_seen, "gas": gas_used}}
	var file: FileAccess = FileAccess.open(output + "/%s-%d.json" % [role, index], FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report, "\t")); file.close()
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]: DirAccess.remove_absolute(save_path + suffix)
	print(JSON.stringify(report))
	# Let queued mixer stop commands retire before tearing down the audio server.
	root.get_node("Audio").stop_all()
	await create_timer(0.12, true, false, true).timeout
	quit(0 if failures.is_empty() else 1)
