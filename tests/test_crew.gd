extends GutTest

const StateScript: Script = preload("res://autoload/GameState.gd")
const PATH: String = "user://v3_crew_test.cfg"
var state: Node

func before_each() -> void:
	clean_files()
	state = StateScript.new()
	state.persistence_path = PATH
	add_child_autofree(state)

func after_each() -> void:
	clean_files()

func clean_files() -> void:
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(PATH + suffix)

func test_legacy_migration_preserves_original_and_is_idempotent() -> void:
	var config: ConfigFile = ConfigFile.new()
	var legacy: Dictionary = AvatarData.sanitize({"name": "Captain", "hat": 4, "float_style": 3})
	var old: Dictionary = {"avatar": legacy, "unlocked_level": 4, "best_stars": {1: 3, 2: 2}, "best_times": {1: 27.5, 2: 34.0}, "settings": {"sound": false, "music_volume": 0.23, "vibration": false, "quality": "low", "show_fps": true}, "seen_tutorial": true}
	for key: String in old:
		config.set_value("game", key, old[key])
	assert_eq(config.save(PATH), OK)
	var original: PackedByteArray = FileAccess.get_file_as_bytes(PATH)
	state.load_progress(PATH)
	assert_false(FileAccess.file_exists(PATH + ".pre-v2.bak"), "Loading alone never writes")
	assert_eq(state.avatar, legacy)
	assert_eq(state.local_profiles[0], legacy)
	for pass_index: int in range(2):
		assert_eq(state.save_progress(PATH), OK)
		state.load_progress(PATH)
		assert_eq(state.local_profiles.size(), 4)
		for key: String in old:
			assert_eq(state.get(key), old[key], "%s survives pass %d" % [key, pass_index])
		assert_eq(FileAccess.get_file_as_bytes(PATH + ".pre-v2.bak"), original)
	assert_eq(state.crew_slots[0].control, "local")
	assert_eq(state.crew_slots[1].control, "empty")
	assert_eq(config.load(PATH), OK)
	assert_eq(config.get_value("game", "save_version"), 2)

func test_four_profiles_roundtrip_and_compatibility_alias() -> void:
	for index: int in range(4):
		assert_true(state.set_profile(index, {"name": "Crew%d" % index, "skin": index, "outfit": index + 1, "hat": index, "float_style": index, "toot": index}))
		assert_true(state.assign_slot(index, "local" if index == 0 else "assist", index))
	state.avatar.name = "Alias edit"
	assert_eq(state.local_profiles[0].name, "Alias edit")
	state.local_profiles[0].hat = 4
	assert_eq(state.avatar.hat, 4)
	state.leader_profile = 3
	var expected_profiles: Array = state.local_profiles.duplicate(true)
	var expected_slots: Array = state.crew_slots.duplicate(true)
	assert_eq(state.save_progress(PATH), OK)
	var restored: Node = StateScript.new()
	restored.persistence_path = PATH
	add_child_autofree(restored)
	assert_eq(restored.local_profiles, expected_profiles)
	assert_eq(restored.crew_slots, expected_slots)
	assert_eq(restored.leader_profile, 3)
	assert_false(state.set_profile(4, {}))
	assert_false(FileAccess.file_exists(PATH + ".pre-v2.bak"), "Fresh saves need no migration backup")

func test_invalid_assignment_and_peer_ownership() -> void:
	state.set_profile(0, AvatarData.default_avatar())
	assert_true(state.assign_slot(1, "peer", 1, "peer:37"))
	var original: Array = state.crew_slots.duplicate(true)
	assert_false(state.assign_slot(4, "assist", 2))
	assert_false(state.assign_slot(-1, "assist", 2))
	assert_false(state.assign_slot(2, "assist", 4))
	assert_false(state.assign_slot(2, "assist", -1))
	assert_false(state.assign_slot(2, "rival", 2))
	assert_false(state.assign_slot(2, "assist", 1), "Profile already occupies another seat")
	assert_false(state.assign_slot(2, "peer", 2, "peer:37"), "Owner already occupies another seat")
	assert_false(state.assign_slot(2, "peer", 2), "Peer must have a runtime owner")
	assert_eq(state.crew_slots, original, "Rejected assignments leave crew untouched")
	state.save_progress(PATH)
	var saved: ConfigFile = ConfigFile.new()
	saved.load(PATH)
	assert_false(saved.encode_to_text().contains("peer:37"))
	assert_eq(state.crew_slots[1].control, "peer", "Saving does not disconnect runtime peers")
	state.load_progress(PATH)
	assert_eq(state.crew_slots[1], CrewData.empty_slot())

func test_corrupt_fields_are_sanitized_without_losing_valid_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("game", "save_version", "broken")
	config.set_value("game", "unlocked_level", 3)
	config.set_value("game", "avatar", {"name": "Old", "float_style": 2})
	config.set_value("game", "local_profiles", [null, {"name": "\n", "hat": 99}, "bad", {}, {"name": "fifth"}])
	config.set_value("game", "crew_slots", [{"control": "local", "profile": 0, "owner": "local:0"}, {"control": "assist", "profile": 0, "owner": "assist:0"}, {"control": "peer", "profile": 2, "owner": "peer:45"}, {"control": "assist", "profile": 900, "owner": []}, {}])
	config.set_value("game", "leader_profile", 900)
	config.save(PATH)
	state.load_progress(PATH)
	assert_eq(state.unlocked_level, 3)
	assert_eq(state.local_profiles.size(), 4)
	assert_eq(state.avatar.name, "Old")
	assert_eq(state.avatar.float_style, 2)
	assert_eq(state.local_profiles[1].hat, 4)
	assert_eq(state.local_profiles[1].name, "Player")
	assert_eq(state.crew_slots.size(), 4)
	for index: int in range(1, 4):
		assert_eq(state.crew_slots[index], CrewData.empty_slot())
	assert_eq(state.leader_profile, 0)
	assert_eq(state.save_progress(PATH), OK)

func test_preview_one_through_four_has_one_ring_and_separate_seats() -> void:
	var model: SharedRingPreview = SharedRingPreview.new()
	add_child_autofree(model)
	var profiles: Array[Dictionary] = CrewData.default_profiles()
	profiles[0] = AvatarData.default_avatar()
	var slots: Array[Dictionary] = [CrewData.empty_slot(), CrewData.empty_slot(), CrewData.empty_slot(), CrewData.empty_slot()]
	for count: int in range(1, 5):
		slots[count - 1] = CrewData.make_slot("local", count - 1)
		model.configure(profiles, slots, count - 1)
		assert_eq(model.riders.size(), count)
		assert_eq(model.get_child_count(), 5, "One ring assembly and four anchors")
		assert_eq(model.ring.name, &"SharedRing")
		for a: int in range(4):
			assert_eq(model.anchors[a].get_child_count(), 2 if a < count else 1, "Empty seats render no rider")
			for b: int in range(a + 1, 4):
				assert_gt(model.anchors[a].position.distance_to(model.anchors[b].position), 2.5)
	for key: String in AvatarData.LIMITS:
		for option: int in range(AvatarData.LIMITS[key]):
			profiles[2][key] = option
			model.configure(profiles, slots, 2)
			assert_eq(model.riders[2].appearance[key], option)
			assert_eq(model.appearance[key], option)
			assert_eq(model.get_child_count(), 5, "Rebuilding frees previous assemblies")

func test_wrong_field_types_and_missing_schema_use_safe_defaults() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("game", "avatar", {"name": "Survivor"})
	config.set_value("game", "local_profiles", "broken")
	config.set_value("game", "crew_slots", [{"control": 123}, {"control": []}, {"control": "local", "profile": "one"}, {"control": "assist", "profile": 3, "owner": 44}])
	config.set_value("game", "leader_profile", {})
	config.set_value("game", "seen_tutorial", "yes")
	config.save(PATH)
	state.load_progress(PATH)
	assert_eq(state.avatar.name, "Survivor")
	assert_false(state.seen_tutorial)
	for slot: Dictionary in state.crew_slots:
		assert_eq(slot, CrewData.empty_slot())
	assert_eq(state.save_progress(PATH), OK)
	config.erase_section_key("game", "crew_slots")
	config.save(PATH)
	state.load_progress(PATH)
	assert_eq(state.crew_slots[0], CrewData.default_slots()[0], "Missing crew defaults to one local rider")
