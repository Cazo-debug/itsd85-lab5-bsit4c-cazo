class_name SkyLevel
extends Node3D

enum State { INTRO, COUNTDOWN, RACING, PAUSED, FINISHED }
@export var level_number: int = 1
@export var practice: bool = false
var state: State = State.INTRO
var race_time: float = 0.0
var state_time: float = 0.0
var time_limit: float = 180.0
var time_left: float = 180.0
var course: CurvedCourse
var player: SwimRing
var camera: RouteCamera
var hud: CrewHUD
var brain: CrewBrain
var definition: Dictionary
var checkpoint_index: int = 0
var previous_s: float = 3.0
var won: bool = false
var pickups_collected: int = 0
var practice_index: int = 0
var result: Dictionary = {}
var settings_save_error: Error = OK
var online: bool = false

func _ready() -> void:
	online = Net.active and Net.phase == "loading"
	if practice:
		level_number = clampi(GameState.current_level, 1, LevelDefs.LEVELS.size())
	definition = LevelDefs.LEVELS[clampi(level_number, 1, LevelDefs.LEVELS.size()) - 1]
	time_limit = definition.time_limit
	time_left = time_limit
	course = CurvedCourse.new()
	add_child(course)
	course.build(definition)
	SkyEnvironment.install(self)
	var profiles: Array[Dictionary] = GameState.local_profiles.duplicate(true)
	var crew: Array[Dictionary] = CrewData.sanitize_slots(GameState.crew_slots, profiles)
	if online:
		profiles = Net.profiles.duplicate(true)
		crew = Net.crew_slots()
	elif not GameState.has_crew():
		profiles[0] = AvatarData.default_avatar()
		crew = CrewData.default_slots()
	player = preload("res://scenes/actors/SwimRing.tscn").instantiate() as SwimRing
	player.setup(course.path, profiles, crew, 0 if online else GameState.leader_profile)
	add_child(player)
	camera = RouteCamera.new()
	camera.ring = player
	camera.path = course.path
	add_child(camera)
	hud = CrewHUD.new()
	add_child(hud)
	hud.controls.ring = player
	hud.controls.camera = camera
	hud.controls.active_seat = Net.local_seat() if online else GameState.active_local_seat
	hud.controls.networked = online
	hud.back_requested.connect(return_to_menu)
	hud.pause_requested.connect(toggle_pause)
	hud.reset_requested.connect(recover)
	hud.action_requested.connect(handle_action)
	brain = CrewBrain.new()
	brain.ring = player
	add_child(brain)
	player.fell.connect(hud.controls.clear)
	player.recovered.connect(hud.controls.clear)
	player.recovered.connect(camera.snap)
	player.thrust_started.connect(mark_tutorial_seen)
	if online:
		brain.enabled = false
		if not Net.hosting:
			player.remote_replica = true
			player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			player.collision_layer = 0
			player.collision_mask = 0
		Net.attach_level(self)
	hud.present(run_snapshot())

func _physics_process(delta: float) -> void:
	if online and (not Net.run_ready or not Net.hosting):
		hud.present(run_snapshot())
		return
	state_time += delta
	match state:
		State.INTRO:
			if state_time >= 2.0:
				state = State.COUNTDOWN
				state_time = 0
				camera.overview = false
		State.COUNTDOWN:
			if state_time >= 3.0:
				begin_run()
		State.RACING:
			race_time += delta
			course.update_water(race_time, player)
			time_left = maxf(0, time_limit - race_time)
			for hazard: CourseHazard in course.hazards:
				hazard.update_time(race_time)
			if not practice and time_left <= 0:
				end_run(false)
			elif player.falling:
				if player.fall_time >= 1.5:
					player.respawn_at_checkpoint()
					previous_s = player.route_s
			else:
				check_progress()
				check_pickups()
	hud.present(run_snapshot())

func run_snapshot() -> Dictionary:
	var local_seat: int = Net.local_seat() if online else GameState.active_local_seat
	var section: String = definition.sections[0][1]
	for item: Array in definition.sections:
		if player.route_s / course.path.length >= item[0]:
			section = item[1]
	var crew: Array[Dictionary] = []
	for seat: int in range(4):
		crew.append({"occupied": player.seat_control[seat] != "empty", "gas": player.gas[seat],
			"firing": player.firing[seat], "name": player.avatars[player.slots[seat].profile].get("name", "Player") if player.seat_control[seat] != "empty" else "Empty"})
	return {"state": State.keys()[state], "course": definition.name, "section": section,
		"time_left": time_left, "race_time": race_time, "countdown": maxi(1, 3 - int(state_time)),
		"progress": player.route_s / course.path.length, "crew": crew, "practice": practice,
		"falling": player.falling, "sound": GameState.settings.sound, "result": result.duplicate(),
		"settings_save_error": settings_save_error,
		"next_available": CampaignFlow.next_level(GameState, result) > 0,
		"online": online, "host": Net.hosting if online else true,
		"waiting": online and not Net.run_ready,
		"hint": CourseHints.for_run(course.path, player.route_s, player.gas[clampi(local_seat, 0, 3)], player.falling)}

func begin_run() -> void:
	state = State.RACING
	state_time = 0
	player.simulate = not online or Net.hosting
	player.freeze = not player.simulate
	player.sleeping = false
	hud.controls.enabled = true
	hud.controls.clear()

func check_progress() -> void:
	var surface: Dictionary = course.path.surface_at(player.position, player.route_s)
	if surface.valid and absf(player.position.y - surface.height) < 1.5:
		if checkpoint_index < course.checkpoints.size():
			var next: float = course.checkpoints[checkpoint_index]
			if previous_s < next and player.route_s >= next:
				checkpoint_index += 1
				player.checkpoint_s = next + 3
				player.checkpoint = course.path.safe_transform(player.checkpoint_s)
		if checkpoint_index == course.checkpoints.size() and previous_s < course.finish_s + player.profile.radius and player.route_s >= course.finish_s + player.profile.radius:
			end_run(true)
	previous_s = player.route_s

func check_pickups() -> void:
	for pickup: Dictionary in course.pickups:
		pickup.node.visible = race_time >= pickup.ready_at
		if pickup.node.visible and player.position.distance_to(pickup.node.position) < 3:
			player.add_gas_all(0.35)
			pickup.ready_at = race_time + 8.0
			pickup.node.hide()
			pickups_collected += 1

func end_run(success: bool) -> void:
	if state != State.RACING:
		return
	state = State.FINISHED
	won = success
	player.simulate = false
	player.freeze = true
	player.falling = false
	player.fall_time = 0
	player.release_all_inputs()
	hud.controls.enabled = false
	hud.controls.clear()
	brain.enabled = false
	result = CampaignFlow.finish(GameState, level_number, race_time, time_limit, success, player.recoveries, practice)
	if online:
		result.online = true
		Net.publish(true)
	hud.present(run_snapshot())

func toggle_pause() -> void:
	if online:
		Net.request_action("rematch" if state == State.FINISHED else "pause")
		return
	toggle_pause_authority()

func toggle_pause_authority() -> void:
	if state == State.FINISHED:
		restart_run()
		return
	if state not in [State.RACING, State.PAUSED]:
		return
	var paused: bool = state == State.RACING
	state = State.PAUSED if paused else State.RACING
	player.simulate = not paused
	player.freeze = paused
	player.release_all_inputs()
	hud.controls.enabled = not paused
	hud.controls.clear()
	brain.enabled = not paused and not online
	hud.present(run_snapshot())

func mark_tutorial_seen(_seat: int) -> void:
	if not practice and not GameState.seen_tutorial and GameState.mode == "offline":
		GameState.seen_tutorial = true
		GameState.save_progress(GameState.persistence_path)

func handle_action(action: String) -> void:
	if online and action != "sound":
		var intent: String = {"resume": "pause", "retry": "rematch", "menu": "leave"}.get(action, action)
		Net.request_action(intent)
		return
	match action:
		"resume":
			if state == State.PAUSED:
				toggle_pause()
		"retry":
			player.release_all_inputs()
			restart_run()
		"next":
			var number: int = CampaignFlow.next_level(GameState, result)
			if number > 0:
				var destination: String = CampaignFlow.prepare_launch(GameState, number)
				if not destination.is_empty():
					leave_scene(destination)
		"menu": leave_scene("res://scenes/ui/MainMenu.tscn")
		"sound":
			settings_save_error = CampaignFlow.toggle_sound(GameState)
			hud.present(run_snapshot())
		"save":
			if state == State.FINISHED and result.get("save_error", OK) != OK:
				result.save_error = GameState.save_progress(GameState.persistence_path)
				result.saved = result.save_error == OK
				GameState.last_result = result.duplicate()
				hud.invalidate_panels()
				hud.present(run_snapshot())

func restart_run() -> void:
	if online:
		Net.request_action("rematch")
		return
	player.release_all_inputs()
	brain.enabled = false
	get_tree().reload_current_scene()

func recover() -> void:
	if online:
		Net.request_action("recover")
		return
	recover_authority()

func recover_authority() -> void:
	if state != State.RACING:
		return
	if practice:
		practice_index = (practice_index + 1) % definition.sections.size()
		player.checkpoint_s = definition.sections[practice_index][0] * course.path.length + 3
		player.checkpoint = course.path.safe_transform(player.checkpoint_s)
		checkpoint_index = 0
		for distance: float in course.checkpoints:
			if distance < player.checkpoint_s:
				checkpoint_index += 1
	player.respawn_at_checkpoint()
	previous_s = player.route_s

func return_to_menu() -> void:
	if online:
		Net.request_action("leave")
		return
	leave_scene("res://scenes/ui/CrewSetup.tscn")

func leave_scene(destination: String) -> void:
	player.simulate = false
	player.release_all_inputs()
	brain.enabled = false
	hud.controls.clear()
	get_tree().change_scene_to_file(destination)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		return_to_menu()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(player):
		return_to_menu()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.RACING:
		toggle_pause()
