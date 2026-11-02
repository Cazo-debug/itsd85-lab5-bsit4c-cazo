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

func _ready() -> void:
	definition = LevelDefs.LEVELS[0]
	time_limit = definition.time_limit
	time_left = time_limit
	course = CurvedCourse.new()
	add_child(course)
	course.build(definition)
	SkyEnvironment.install(self)
	var profiles: Array[Dictionary] = GameState.local_profiles.duplicate(true)
	var crew: Array[Dictionary] = CrewData.sanitize_slots(GameState.crew_slots, profiles)
	if not GameState.has_crew():
		profiles[0] = AvatarData.default_avatar()
		crew = CrewData.default_slots()
	player = preload("res://scenes/actors/SwimRing.tscn").instantiate() as SwimRing
	player.setup(course.path, profiles, crew, GameState.leader_profile)
	add_child(player)
	camera = RouteCamera.new()
	camera.ring = player
	camera.path = course.path
	add_child(camera)
	hud = CrewHUD.new()
	add_child(hud)
	hud.controls.ring = player
	hud.controls.camera = camera
	hud.controls.active_seat = GameState.active_local_seat
	hud.hint.text = "Seat %d: aim + hold to fart\nWASD + Space on desktop" % (GameState.active_local_seat + 1)
	hud.back_requested.connect(return_to_menu)
	hud.pause_requested.connect(toggle_pause)
	hud.reset_requested.connect(recover)
	brain = CrewBrain.new()
	brain.ring = player
	add_child(brain)
	player.fell.connect(hud.controls.clear)
	player.recovered.connect(hud.controls.clear)
	if practice:
		hud.reset_button.text = "Next area"

func _physics_process(delta: float) -> void:
	state_time += delta
	match state:
		State.INTRO:
			if state_time >= 2.0:
				state = State.COUNTDOWN
				state_time = 0
				camera.overview = false
		State.COUNTDOWN:
			hud.banner.text = "READY, CREW?\n%d" % maxi(1, 3 - int(state_time))
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
				hud.banner.show()
				hud.banner.text = "CREW OVERBOARD!\nReturning to checkpoint"
				if player.fall_time >= 1.5:
					player.respawn_at_checkpoint()
					previous_s = player.route_s
			else:
				hud.banner.visible = race_time < 0.8
				check_progress()
				check_pickups()
	var section: String = "Cloud launch"
	for item: Array in definition.sections:
		if player.route_s / course.path.length >= item[0]:
			section = item[1]
	hud.update_status(player, time_left, section, practice)

func begin_run() -> void:
	state = State.RACING
	state_time = 0
	player.simulate = true
	player.freeze = false
	player.sleeping = false
	hud.controls.enabled = true
	hud.controls.clear()
	hud.banner.text = "LET'S TOOT!"

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
	var stars: int = GameState.calc_stars(time_left, time_limit) if success else 0
	if not practice:
		GameState.last_result = {"won": success, "stars": stars, "level": 1, "time": race_time, "recoveries": player.recoveries}
		if success:
			GameState.complete_level(1, stars, race_time)
	hud.banner.show()
	hud.banner.text = "CREW COMPLETE!\n%d stars / %d recoveries" % [stars, player.recoveries] if success else "TIME'S UP\nTry again together"
	hud.pause_button.text = "Again"

func toggle_pause() -> void:
	if state == State.FINISHED:
		get_tree().reload_current_scene()
		return
	if state not in [State.RACING, State.PAUSED]:
		return
	var paused: bool = state == State.RACING
	state = State.PAUSED if paused else State.RACING
	player.simulate = not paused
	player.freeze = paused
	hud.controls.enabled = not paused
	hud.controls.clear()
	brain.enabled = not paused
	hud.banner.visible = paused
	hud.banner.text = "PAUSED"
	hud.pause_button.text = "Resume" if paused else "Pause"

func recover() -> void:
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
	player.simulate = false
	player.release_all_inputs()
	hud.controls.clear()
	get_tree().change_scene_to_file("res://scenes/ui/CrewSetup.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		return_to_menu()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(player):
		return_to_menu()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.RACING:
		toggle_pause()
