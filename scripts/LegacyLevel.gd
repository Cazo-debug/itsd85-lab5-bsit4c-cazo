class_name RaceLevel
extends Node3D

enum State { INTRO, COUNTDOWN, RACING, FINISHED }
@export var level_number: int = 1
@export var auto_return: bool = true
var state: State = State.INTRO
var intro_time: float = 0.0
var race_time: float = 0.0
var countdown_time: float = 0.0
var finish_elapsed: float = 0.0
var time_left: float = 75.0
var time_limit: float = 75.0
var last_checkpoint_d: float = 0.0
var definition: Dictionary = {}
var player: FloatPlayer
var course: LevelBuilder
var camera: RaceCamera
var tap_input: TapInput
var hud: RaceHUD
var show_hint: bool = true

func _ready() -> void:
	definition = LevelDefs.LEGACY_LEVELS[clampi(level_number - 1, 0, LevelDefs.LEGACY_LEVELS.size() - 1)]
	time_limit = definition.time_limit
	time_left = time_limit
	course = LevelBuilder.new()
	add_child(course)
	course.build(definition)
	player = preload("res://scenes/actors/FloatPlayer.tscn").instantiate() as FloatPlayer
	player.position = course.start.position
	player.avatar = AvatarData.sanitize(GameState.avatar)
	player.freeze = true
	player.controls_enabled = false
	add_child(player)
	player.checkpoint = player.position
	player.reset_physics_interpolation()
	player.tooted.connect(_on_tooted)
	camera = RaceCamera.new()
	add_child(camera)
	camera.target = player
	camera.snap_to_player()
	var last_segment: Dictionary = definition.segments[-1]
	camera.show_overview(last_segment.d + last_segment.length)
	player.bumped.connect(camera.shake)
	player.popped.connect(camera.shake)
	player.fell.connect(camera.shake)
	SkyEnvironment.install(self)
	tap_input = TapInput.new()
	tap_input.player = player
	tap_input.camera = camera
	add_child(tap_input)
	hud = preload("res://scenes/ui/HUD.tscn").instantiate() as RaceHUD
	add_child(hud)
	hud.big_goal.text = "Lazy River above the clouds"
	hud.countdown_label.hide()
	hud.hint_label.hide()
	hud.goal_label.text = definition.name
	hud.back_requested.connect(return_to_menu)
	show_hint = not GameState.seen_tutorial
	hud.hint_label.hide()
	course.finish.finish_crossed.connect(_on_finish_crossed)
	for checkpoint: CoursePiece in course.checkpoints:
		checkpoint.checkpoint_reached.connect(_on_checkpoint)
	for bean: CoursePiece in course.beans:
		bean.bean_collected.connect(_on_bean)
	hud.update_race(time_left, player.gas, 0.0, false)

func _physics_process(delta: float) -> void:
	if state == State.INTRO:
		intro_time += delta
		if intro_time >= 2.0:
			state = State.COUNTDOWN
			camera.overview = false
			hud.big_goal.text = definition.goal_text
			hud.countdown_label.show()
	elif state == State.COUNTDOWN:
		countdown_time += delta
		hud.countdown_label.text = str(maxi(1, 3 - int(countdown_time)))
		if countdown_time >= 3.0:
			begin_race()
	elif state == State.RACING:
		race_time = minf(race_time + delta, time_limit)
		time_left = maxf(0.0, time_limit - race_time)
		hud.big_goal.visible = race_time < 3.0
		hud.countdown_label.visible = race_time < 0.65
		hud.hint_arrow.visible = show_hint and race_time >= 0.65
		if time_left <= 0.0:
			end_level(false)
		else:
			check_holes()
	elif auto_return:
		finish_elapsed += delta
		if finish_elapsed >= 2.0:
			return_to_menu()
	var start_d: float = float(definition.start[1])
	var ratio: float = (-player.position.z - start_d) / (float(definition.finish_d) - start_d)
	hud.update_race(time_left, player.gas, ratio, state == State.RACING)

func begin_race() -> void:
	if state != State.COUNTDOWN:
		return
	state = State.RACING
	race_time = 0.0
	player.freeze = false
	player.sleeping = false
	player.controls_enabled = true
	tap_input.enabled = true
	hud.countdown_label.text = "TOOT!"
	hud.hint_label.visible = show_hint

func _on_tooted(_direction: Vector3) -> void:
	show_hint = false
	hud.hint_label.hide()
	hud.hint_arrow.hide()
	if not GameState.seen_tutorial:
		GameState.seen_tutorial = true
		GameState.save_progress(GameState.persistence_path)

func _on_checkpoint(body: FloatPlayer, distance: float) -> void:
	if state == State.RACING and body == player and distance > last_checkpoint_d:
		last_checkpoint_d = distance
		player.checkpoint = Vector3(course.center_at(distance), 0, -distance)

func _on_bean(_body: FloatPlayer) -> void:
	pass

func _on_finish_crossed(body: FloatPlayer) -> void:
	if body == player and state == State.RACING and not player.falling:
		end_level(time_left > 0.0)

func check_holes() -> void:
	if player.falling or not player.controls_enabled:
		return
	for hole: CourseHole in course.holes:
		if hole.contains_center(player.global_position):
			player.fall_into_hole()
			break

func end_level(won: bool) -> void:
	if state != State.RACING:
		return
	state = State.FINISHED
	player.cancel_fall()
	tap_input.enabled = false
	player.controls_enabled = false
	player.freeze = true
	player.linear_velocity = Vector3.ZERO
	var stars: int = GameState.calc_stars(time_left, time_limit) if won else 0
	GameState.last_result = {"won": won, "stars": stars, "level": level_number, "time": race_time, "place": 1 if won else 0}
	if won:
		GameState.complete_level(level_number, stars, race_time)
	print("Level %d: %s (%d stars, %.2f seconds)" % [level_number, "cleared" if won else "time up", stars, race_time])
	hud.big_goal.show()
	hud.big_goal.text = "Finish! %d stars" % stars if won else "Time's up! Try again."
	hud.countdown_label.hide()
	hud.hint_label.hide()
	hud.hint_arrow.hide()
	if won:
		player.finished.emit()

func return_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/ModeSelect.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		return_to_menu()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		return_to_menu()
