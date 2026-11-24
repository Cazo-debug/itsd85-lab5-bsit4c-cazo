class_name RingReplication
extends RefCounted

var previous: Dictionary = {}
var latest: Dictionary = {}
var arrival: float = 0.0
var interval: float = 0.05

func reset() -> void:
	previous.clear()
	latest.clear()
	arrival = 0

static func capture(level: Node3D, round_id: int, tick: int) -> Dictionary:
	var ring: SwimRing = level.player
	return {"round": round_id, "tick": tick, "pose": ring.global_transform,
		"linear": ring.linear_velocity, "angular": ring.angular_velocity,
		"gas": ring.gas.duplicate(), "aim": ring.aim.duplicate(), "held": ring.held.duplicate(),
		"firing": ring.firing.duplicate(), "depleted": ring.depleted.duplicate(),
		"angles": ring.orbit.angles.duplicate(), "motion": ring.orbit_motion.duplicate(),
		"s": ring.route_s, "falling": ring.falling, "recoveries": ring.recoveries,
		"contacts": ring.contact_count, "pickups_collected": level.pickups_collected,
		"star_scores": level.star_scores.duplicate(), "stars_taken": level.course.stars.map(func(item: Dictionary) -> int: return item.taken_by),
		"checkpoint": level.checkpoint_index, "state": int(level.state), "state_time": level.state_time,
		"race_time": level.race_time, "time_left": level.time_left, "result": level.result.duplicate(true),
		"pickups": level.course.pickups.map(func(item: Dictionary) -> float: return item.ready_at)}

func push(snapshot: Dictionary, now: float) -> bool:
	if not latest.is_empty() and int(snapshot.tick) <= int(latest.tick):
		return false
	if not latest.is_empty():
		interval = clampf(now - arrival, 0.016, 0.2)
	previous = latest if not latest.is_empty() else snapshot
	latest = snapshot.duplicate(true)
	arrival = now
	return true

func apply(level: Node3D, now: float) -> void:
	if latest.is_empty():
		return
	var ring: SwimRing = level.player
	var amount: float = clampf((now - arrival) / interval, 0, 1)
	var snap: bool = previous.recoveries != latest.recoveries or previous.state != latest.state
	var recovered: bool = ring.recoveries != latest.recoveries
	var state_changed: bool = level.state != latest.state
	if state_changed or recovered or (not ring.falling and latest.falling):
		level.hud.controls.clear()
	ring.global_transform = latest.pose if snap else (previous.pose as Transform3D).interpolate_with(latest.pose, amount)
	ring.linear_velocity = latest.linear
	ring.angular_velocity = latest.angular
	for seat: int in range(4):
		ring.gas[seat] = latest.gas[seat]
		ring.aim[seat] = latest.aim[seat]
		ring.held[seat] = latest.held[seat]
		ring.firing[seat] = latest.firing[seat]
		ring.depleted[seat] = latest.depleted[seat]
		ring.orbit.angles[seat] = lerp_angle(previous.angles[seat], latest.angles[seat], amount)
		ring.orbit_motion[seat] = latest.motion[seat]
	ring.visual.place_riders(ring.orbit)
	ring.route_s = latest.s
	ring.falling = latest.falling
	ring.recoveries = latest.recoveries
	ring.contact_count = latest.contacts
	level.pickups_collected = latest.pickups_collected
	level.star_scores.assign(latest.star_scores)
	for index: int in range(mini(level.course.stars.size(), latest.stars_taken.size())):
		level.course.stars[index].taken_by = latest.stars_taken[index]
	level.course.update_stars(latest.race_time)
	level.checkpoint_index = latest.checkpoint
	level.state = latest.state
	level.state_time = latest.state_time
	level.race_time = latest.race_time
	level.time_left = latest.time_left
	level.result = latest.result.duplicate(true)
	level.won = level.result.get("won", false)
	for index: int in range(level.course.pickups.size()):
		level.course.pickups[index].node.visible = latest.race_time >= latest.pickups[index]
	level.course.update_water(level.race_time, ring)
	for hazard: CourseHazard in level.course.hazards:
		hazard.update_time(level.race_time)
	ring.remote_playing = level.state == level.State.RACING
	level.camera.overview = level.state == level.State.INTRO
	level.hud.controls.enabled = ring.remote_playing
	if recovered or state_changed:
		ring.reset_physics_interpolation()
		level.camera.snap()
