class_name VisualShowcase
extends Node

# Developer evidence only. tools/capture_visual_pass.gd and the debug-only Android
# check attach it to a running SkyLevel; normal play never creates it.
# It drives one fixed sequence with the ordinary seat inputs (idle, all four riders
# farting, a tight bend, a fall into a hole, a shared finish) and briefly freezes
# time at each capture moment, so before/after images show the same beat.
signal step_ready(step: String)

const STEPS: Array[String] = ["idle", "farting", "turn", "fall", "finish"]
var level: SkyLevel
var step: String = ""
var frozen: bool = false
var finished: bool = false
## Real seconds each capture moment stays frozen (the phone needs time for screencap).
var hold_seconds: float = 2.5
var steering: bool = false
var measuring: bool = false
var frame_ms: PackedFloat32Array = PackedFloat32Array()
var last_usec: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_usec()
	if measuring and not frozen and last_usec > 0:
		frame_ms.append(float(now - last_usec) / 1000.0)
	last_usec = now

func _physics_process(_delta: float) -> void:
	if not steering or level.state != SkyLevel.State.RACING or level.player.falling:
		return
	# Aim every seat at the route a little ahead, so the crew follows the bends.
	var ahead: Vector3 = level.course.path.sample(level.player.route_s + 9.0).position
	var aim: Vector3 = (ahead - level.player.global_position).slide(Vector3.UP)
	for seat: int in range(SwimRing.MAX_RIDERS):
		level.player.set_thrust_input(seat, aim, 1.0, true)

## Frame-time summary while all four riders were farting (real frames, not frozen ones).
func summary() -> Dictionary:
	if frame_ms.is_empty():
		return {}
	var sorted: Array = Array(frame_ms)
	sorted.sort()
	var total: float = 0.0
	for value: float in sorted:
		total += value
	return {"frames": sorted.size(), "mean_fps": 1000.0 * sorted.size() / maxf(total, 0.001),
		"median_ms": sorted[sorted.size() / 2], "p95_ms": sorted[int(sorted.size() * 0.95)],
		"worst_ms": sorted[-1]}

func run() -> void:
	level.brain.enabled = false
	level.hud.controls.enabled = false
	level.hud.controls.clear()
	var path: CoursePath = level.course.path
	await ticks(1.6)
	await capture("idle")
	steering = true
	measuring = true
	await ticks(1.5)
	await capture("farting")
	await ticks(3.5)
	measuring = false
	steering = false
	place(turn_distance() - 13.0)
	await ticks(0.3)
	steering = true
	await ticks(1.7)
	await capture("turn")
	steering = false
	var hole: Dictionary = path.holes[0]
	place(hole.s - 7.0, hole.lateral)
	await ticks(0.3)
	var into: Vector3 = path.sample(hole.s).tangent
	for seat: int in range(SwimRing.MAX_RIDERS):
		level.player.set_thrust_input(seat, into, 1.0, true)
	await until(func() -> bool: return level.player.falling, 6.0)
	await ticks(0.5)
	await capture("fall")
	await until(func() -> bool: return not level.player.falling, 4.0)
	place(level.course.finish_s - 7.0)
	level.checkpoint_index = level.course.checkpoints.size()
	steering = true
	await until(func() -> bool: return level.state == SkyLevel.State.FINISHED, 8.0)
	steering = false
	await ticks(1.2)
	await capture("finish")
	finished = true

## Performance probe: the same all-four-firing scene with one presentation layer
## switched off at a time. Developer evidence only.
var probe_results: Dictionary = {}

func probe(variants: Array) -> void:
	level.brain.enabled = false
	level.hud.controls.enabled = false
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	await ticks(1.0)
	probe_results["idle"] = await measure_window(2.0, false)
	for variant: String in ["firing"] + variants:
		set_variant(variant, true)
		probe_results[variant] = await measure_window(2.0, true)
		set_variant(variant, false)
	finished = true

func measure_window(seconds: float, firing: bool) -> Dictionary:
	place(level.course.path.length * 0.02)
	steering = firing
	await ticks(0.7)
	frame_ms.clear()
	last_usec = 0
	measuring = true
	var process: float = 0.0
	var physics: float = 0.0
	var render_cpu: float = 0.0
	var render_gpu: float = 0.0
	var samples: int = 0
	var end: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		await get_tree().process_frame
		var rid: RID = get_viewport().get_viewport_rid()
		process += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		physics += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		render_cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		render_gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		samples += 1
	measuring = false
	steering = false
	level.player.release_all_inputs()
	var result: Dictionary = summary()
	samples = maxi(samples, 1)
	result.merge({"process_ms": process / samples, "physics_ms": physics / samples,
		"render_cpu_ms": render_cpu / samples, "render_gpu_ms": render_gpu / samples,
		"draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	return result

func set_variant(variant: String, on: bool) -> void:
	var player: SwimRing = level.player
	match variant:
		"scale_75": get_viewport().scaling_3d_scale = 0.75 if on else 1.0
		"scale_50": get_viewport().scaling_3d_scale = 0.5 if on else 1.0
		"no_water":
			for chunk: MeshInstance3D in level.course.water_chunks:
				chunk.visible = not on
		"no_cliffs":
			for key: String in ["Cliffs", "Shafts", "Banks", "Rims"]:
				(level.course.get_node(key) as Node3D).visible = not on
		"no_decor": level.course.decor.visible = not on
		"no_puffs":
			for pool: Array in player.burst_pools:
				for burst: CPUParticles3D in pool:
					burst.visible = not on
		"no_water_fx":
			player.ripple.visible = not on
			player.spray.visible = not on
			player.wake.visible = not on
			for splash: CPUParticles3D in player.splashes:
				splash.visible = not on
		"no_riders": player.visual.visible = not on
		"no_tags":
			for tag: Label3D in player.tags:
				tag.visible = not on
		"no_hud": level.hud.visible = not on
		"no_sound": FartConfig.current.burst_sound = not on
		"no_sky": level.get_node("SkyEnvironment").environment.background_mode = Environment.BG_COLOR if on else Environment.BG_SKY
		"no_fog": level.get_node("SkyEnvironment").environment.fog_enabled = not on
		"scale_85": get_viewport().scaling_3d_scale = 0.85 if on else 1.0
		"scale_80": get_viewport().scaling_3d_scale = 0.8 if on else 1.0
		"low": SettingsFlow.apply_quality(level, on)
		"bare":
			for item: String in ["no_water", "no_puffs", "no_water_fx"]:
				set_variant(item, on)

## Start of the sharpest bend in the first third of the route.
func turn_distance() -> float:
	var path: CoursePath = level.course.path
	var best: float = path.length * 0.15
	var sharpest: float = 0.0
	var distance: float = path.length * 0.06
	while distance < path.length * 0.30:
		var bend: float = path.sample(distance).tangent.angle_to(path.sample(distance + 10.0).tangent)
		if bend > sharpest:
			sharpest = bend
			best = distance
		distance += 1.0
	return best

func place(distance: float, lateral: float = 0.0) -> void:
	var player: SwimRing = level.player
	player.release_all_inputs()
	player.add_gas_all(1.0)
	var frame: Dictionary = level.course.path.sample(distance)
	var pose: Transform3D = level.course.path.safe_transform(distance)
	pose.origin += frame.lateral * lateral
	player.global_transform = pose
	player.linear_velocity = Vector3.ZERO
	player.angular_velocity = Vector3.ZERO
	player.route_s = distance
	player.reset_physics_interpolation()
	level.previous_s = distance
	level.camera.snap()

func ticks(seconds: float) -> void:
	for index: int in range(roundi(seconds * Engine.physics_ticks_per_second)):
		await get_tree().physics_frame

func until(condition: Callable, timeout: float) -> void:
	var limit: int = roundi(timeout * Engine.physics_ticks_per_second)
	while not condition.call() and limit > 0:
		limit -= 1
		await get_tree().physics_frame

func capture(name: String) -> void:
	step = name
	frozen = true
	Engine.time_scale = 0.0
	step_ready.emit(name)
	await get_tree().create_timer(hold_seconds, true, false, true).timeout
	Engine.time_scale = 1.0
	frozen = false
