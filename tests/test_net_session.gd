extends GutTest

const SAVE: String = "user://phase4_session_test.cfg"
var saved: Dictionary

func before_each() -> void:
	saved = {}
	for key: String in ["persistence_path", "local_profiles", "crew_slots", "mode", "last_result", "unlocked_level", "best_stars", "best_times", "leader_profile", "last_save_error", "seen_tutorial"]:
		var value: Variant = GameState.get(key)
		saved[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	GameState.persistence_path = SAVE
	GameState.local_profiles = CrewData.default_profiles()
	GameState.set_profile(0, AvatarData.default_avatar())
	GameState.crew_slots = CrewData.default_slots()
	GameState.mode = "offline"
	GameState.last_result = {"prior": true}
	Net.navigating = false

func after_each() -> void:
	Net.close_session()
	Net.navigating = true
	for key: String in saved:
		GameState.set(key, saved[key])
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(SAVE + suffix)

func test_lobby_host_sanitizes_and_cannot_start_alone_or_write_offline_progress() -> void:
	assert_eq(GameState.save_progress(SAVE), OK)
	var original: String = FileAccess.get_file_as_string(SAVE)
	var profiles: Array = GameState.local_profiles.duplicate(true)
	var slots: Array = GameState.crew_slots.duplicate(true)
	assert_eq(Net.host({"name": "\nUntrusted name beyond limit", "skin": 999, "extra": "discard"}, 17777), OK)
	assert_eq(Net.MAX_CLIENTS, 3)
	assert_eq(Net.PORT, 7777)
	assert_eq(Net.local_seat(), 0)
	assert_eq(Net.profiles[0].name.length(), 12)
	assert_eq(Net.profiles[0].skin, 5)
	assert_false(Net.profiles[0].has("extra"))
	assert_false(Net.can_start())
	Net.start_run()
	assert_eq(Net.phase, "lobby")
	assert_eq(GameState.mode, "online")
	assert_false(CampaignFlow.finish(GameState, 1, 12, 180, true, 0, false).saved)
	assert_eq(FileAccess.get_file_as_string(SAVE), original)
	assert_eq(GameState.local_profiles, profiles)
	assert_eq(GameState.crew_slots, slots)
	Net.close_session("Closed")
	assert_eq(GameState.mode, "offline")
	assert_eq(GameState.last_result, {"prior": true})
	assert_eq(Net.status_message, "Closed")
	assert_false(Net.active)
	assert_true(Net.multiplayer.multiplayer_peer is OfflineMultiplayerPeer)

func test_invalid_address_is_a_recoverable_in_game_error() -> void:
	assert_ne(Net.join("not an IP", {}), OK)
	assert_false(Net.active)
	assert_eq(GameState.mode, "offline")
	assert_false(Net.status_message.is_empty())
	assert_false(FileAccess.file_exists(SAVE))

func test_network_pad_adapter_submits_only_owned_seat_and_releases_on_clear() -> void:
	assert_eq(Net.host(AvatarData.default_avatar(), 17777), OK)
	Net.phase = "loading"
	var level: SkyLevel = SkyLevel.new()
	add_child_autofree(level)
	assert_true(Net.run_ready)
	level.begin_run()
	level.hud.controls.apply_thrust(0, Vector3.FORWARD, 1.0, true)
	Net.send_input()
	assert_true(level.player.held[0])
	level.hud.controls.apply_thrust(1, Vector3.RIGHT, 1.0, true)
	assert_eq(Net.desired.seat, 0, "Adapter cannot submit another seat")
	assert_false(level.player.held[1])
	level.hud.controls.clear()
	assert_false(level.player.held[0])
	assert_false(Net.desired.held)
	level.player.simulate = false
	level.hud.controls.enabled = true
	assert_true(level.hud.controls.input_available(), "Frozen guest can still provide input through the network adapter")
	level.player.falling = true
	assert_false(level.hud.controls.input_available())

func test_replication_copies_state_interpolates_and_ignores_older_ticks() -> void:
	var level: SkyLevel = SkyLevel.new()
	add_child_autofree(level)
	var replication: RingReplication = RingReplication.new()
	var first: Dictionary = RingReplication.capture(level, 2, 10)
	assert_true(replication.push(first, 1.0))
	var second: Dictionary = first.duplicate(true)
	second.tick = 11
	second.pose.origin += Vector3(4, 2, -3)
	second.pose.basis = Basis(Vector3.UP, 0.4)
	second.gas[2] = 0.3
	second.linear = Vector3(2, 1, 3)
	second.angular = Vector3(0, 0.5, 0)
	assert_true(replication.push(second, 1.1))
	replication.apply(level, 1.15)
	assert_true(level.player.position.is_equal_approx(first.pose.origin.lerp(second.pose.origin, 0.5)))
	assert_almost_eq(level.player.gas[2], 0.3, 0.0001)
	assert_eq(level.player.linear_velocity, second.linear)
	assert_eq(level.player.angular_velocity, second.angular)
	assert_false(replication.push(first, 1.16))
	second.gas[2] = 0
	assert_eq(replication.latest.gas[2], 0.3)
	assert_false(level.player.simulate)
