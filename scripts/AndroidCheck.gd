extends Node

# Explicit --android-check developer session. The runner drives the real Android
# input path; this probe only reports state and selects an isolated save.
const SAVE: String = "user://phase5_android_qa.cfg"
const REPORT: String = "user://phase5_android_state.json"
const FLAG: String = "user://phase5_android_check.flag"
var elapsed: float = 0.0
var sequence: int = 0
var focus_out: int = 0
var focus_in: int = 0
var back_requests: int = 0
var normal_hash: String = ""
var solve: bool = false

static func requested() -> bool:
	return "--android-check" in OS.get_cmdline_user_args() or (OS.has_feature("android") and OS.has_feature("debug") and FileAccess.file_exists(FLAG))

func _ready() -> void:
	var options: Dictionary = {}
	if OS.has_feature("android") and OS.has_feature("debug") and FileAccess.file_exists(FLAG):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAG))
		if parsed is Dictionary:
			options = parsed
	normal_hash = FileAccess.get_sha256(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else "absent"
	GameState.persistence_path = SAVE
	if FileAccess.file_exists(SAVE) and "--android-reset-check" not in OS.get_cmdline_user_args() and options.get("reset") != true:
		GameState.load_progress(SAVE)
	else:
		GameState.local_profiles = CrewData.default_profiles()
		GameState.crew_slots = CrewData.default_slots()
		for seat: int in range(4):
			GameState.set_profile(seat, AvatarData.default_avatar())
			GameState.assign_slot(seat, "local", seat)
		GameState.settings = GameState.DEFAULT_SETTINGS.duplicate()
		GameState.mode = "offline"
		GameState.unlocked_level = 1
		GameState.best_stars = {}
		GameState.best_times = {}
		GameState.leader_profile = 0
		GameState.active_local_seat = 0
		GameState.seen_tutorial = true
		GameState.save_progress(SAVE)
	solve = "--android-solve-check" in OS.get_cmdline_user_args() or options.get("solve") == true
	if solve:
		Engine.time_scale = 3.0
	print("ANDROID_CHECK_READY ", JSON.stringify({"solve": solve, "args": OS.get_cmdline_user_args()}))

func rect(value: Rect2) -> Array[float]:
	return [value.position.x, value.position.y, value.size.x, value.size.y]

func buttons(node: Node, result: Array[Dictionary]) -> void:
	if node is Button and node.is_visible_in_tree():
		var point: Vector2 = node.get_global_rect().get_center()
		var visible: bool = get_tree().root.get_visible_rect().has_point(point)
		var parent: Node = node.get_parent()
		while parent:
			if parent is Control and parent.clip_contents and not parent.get_global_rect().has_point(point):
				visible = false
			parent = parent.get_parent()
		result.append({"text": node.text, "rect": rect(node.get_global_rect()), "visible": visible, "disabled": node.disabled})
	for child: Node in node.get_children():
		buttons(child, result)

func snapshot() -> Dictionary:
	var scene: Node = get_tree().current_scene
	var actions: Array[Dictionary] = []
	if scene:
		buttons(scene, actions)
	var size: Vector2 = get_tree().root.get_visible_rect().size
	var result: Dictionary = {"sequence": sequence, "ticks": Time.get_ticks_msec(), "scene": str(scene.name) if scene else "",
		"viewport": [size.x, size.y], "buttons": actions, "settings": GameState.settings.duplicate(),
		"unlocked": GameState.unlocked_level, "best_stars": GameState.best_stars.duplicate(), "best_times": GameState.best_times.duplicate(),
		"focus_out": focus_out, "focus_in": focus_in, "back_requests": back_requests, "net_phase": Net.phase,
		"audio_targets": Audio.targets.duplicate(), "music_playing": Audio.music.playing,
		"normal_save_unchanged": normal_hash == (FileAccess.get_sha256(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else "absent"),
		"solve": solve, "time_scale": Engine.time_scale}
	if scene is SkyLevel:
		var level: SkyLevel = scene
		result["level"] = {"instance": level.get_instance_id(), "number": level.level_number, "state": SkyLevel.State.keys()[level.state],
			"race_time": level.race_time, "held": level.player.held.duplicate(), "firing": level.player.firing.duplicate(),
			"gas": level.player.gas.duplicate(), "force_seconds": level.player.force_seconds.duplicate(),
			"riders": level.player.visual.riders.size(), "speed": level.player.linear_velocity.length(), "s": level.player.route_s,
			"angles": level.player.orbit.angles.duplicate(), "falling": level.player.falling, "recoveries": level.player.recoveries,
			"checkpoint": level.checkpoint_index, "result": level.result.duplicate(true),
			"stick_id": level.hud.controls.stick_id, "gas_id": level.hud.controls.gas_id,
			"stick_rect": rect(level.hud.controls.stick_rect()), "gas_rect": rect(level.hud.controls.gas_rect())}
	return result

func _process(delta: float) -> void:
	var scene: Node = get_tree().current_scene
	if solve and scene is SkyLevel:
		# Separate scripted solvability mode: same sustained input/gas/physics,
		# never mixed with the native-input acceptance run.
		scene.brain.all_seats = true
		scene.hud.controls.enabled = false
	elapsed += delta
	if elapsed < 0.15:
		return
	elapsed = 0.0
	sequence += 1
	var file: FileAccess = FileAccess.open(REPORT + ".tmp", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(snapshot()))
		file.close()
		DirAccess.rename_absolute(REPORT + ".tmp", REPORT)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		focus_out += 1
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		focus_in += 1
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back_requests += 1
