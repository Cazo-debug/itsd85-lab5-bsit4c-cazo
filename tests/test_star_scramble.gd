extends GutTest

# Star Scramble: collectible stars, scoring modes (co-op / versus / teams 2v2) and winner rules.
const PATH: String = "user://star_scramble_test.cfg"
var saved_path: String
var saved_mode: String

func before_each() -> void:
	saved_path = GameState.persistence_path
	saved_mode = GameState.match_mode
	GameState.persistence_path = PATH

func after_each() -> void:
	GameState.persistence_path = saved_path
	GameState.match_mode = saved_mode
	for suffix: String in ["", ".tmp", ".pre-v2.bak"]:
		DirAccess.remove_absolute(PATH + suffix)

func seats(a: bool, b: bool, c: bool, d: bool) -> Array[bool]:
	return [a, b, c, d]

func scores(a: int, b: int, c: int, d: int) -> Array[int]:
	return [a, b, c, d]

func names() -> Array[String]:
	return ["Ann", "Ben", "Cy", "Di"]

# ---- MatchRules

func test_modes_sanitize_and_cycle() -> void:
	assert_eq(MatchRules.sanitize_mode("versus"), "versus")
	for junk: Variant in ["", "race", 5, null, "TEAMS"]:
		assert_eq(MatchRules.sanitize_mode(junk), "coop", "Unknown modes from a peer fall back to co-op")
	assert_eq(MatchRules.next_mode("coop"), "versus")
	assert_eq(MatchRules.next_mode("versus"), "teams")
	assert_eq(MatchRules.next_mode("teams"), "coop")

func test_modes_fall_back_when_there_are_not_enough_riders() -> void:
	assert_eq(MatchRules.effective_mode("versus", seats(true, false, false, false)), "coop")
	assert_eq(MatchRules.effective_mode("versus", seats(true, true, false, false)), "versus")
	assert_eq(MatchRules.effective_mode("teams", seats(true, false, true, false)), "versus", "Seats 1 and 3 are the same team")
	assert_eq(MatchRules.effective_mode("teams", seats(true, true, false, false)), "teams")
	assert_eq(MatchRules.effective_mode("teams", seats(true, true, true, true)), "teams")
	assert_eq(MatchRules.effective_mode("coop", seats(true, true, true, true)), "coop")

func test_teams_are_seats_one_three_against_two_four() -> void:
	assert_eq(MatchRules.team_of("teams", 0), MatchRules.team_of("teams", 2))
	assert_eq(MatchRules.team_of("teams", 1), MatchRules.team_of("teams", 3))
	assert_ne(MatchRules.team_of("teams", 0), MatchRules.team_of("teams", 1))
	assert_ne(MatchRules.team_of("versus", 0), MatchRules.team_of("versus", 2))
	assert_eq(MatchRules.team_of("coop", 3), 0)

func test_versus_winner_is_the_rider_with_most_stars() -> void:
	var result: Dictionary = MatchRules.tally("versus", scores(3, 7, 2, 0), seats(true, true, true, false), names(), 12)
	assert_eq(result.mode, "versus")
	assert_eq(result.headline, "Ben wins!")
	assert_false(result.tie)
	assert_eq(result.stars_collected, 12)
	assert_eq(result.lines[0], "Ben: 7 stars")
	assert_eq(result.lines.size(), 3, "The empty seat is not listed")

func test_ties_are_called_a_tie() -> void:
	var result: Dictionary = MatchRules.tally("versus", scores(4, 4, 1, 0), seats(true, true, true, false), names(), 12)
	assert_true(result.tie)
	assert_eq(result.headline, "It's a tie!")
	var none: Dictionary = MatchRules.tally("versus", scores(0, 0, 0, 0), seats(true, true, false, false), names(), 12)
	assert_true(none.tie, "Nobody got a star")

func test_team_totals_add_up_across_both_seats() -> void:
	var result: Dictionary = MatchRules.tally("teams", scores(2, 5, 4, 0), seats(true, true, true, true), names(), 12)
	assert_eq(result.mode, "teams")
	assert_eq(result.headline, "Team A wins!", "Seats 1 + 3 = 6 stars against 5")
	assert_true(str(result.lines[0]).begins_with("Team A (Ann + Cy): 6 star"))
	assert_true(str(result.lines[1]).begins_with("Team B (Ben + Di): 5 star"))
	var other: Dictionary = MatchRules.tally("teams", scores(1, 5, 1, 1), seats(true, true, true, true), names(), 12)
	assert_eq(other.headline, "Team B wins!")

func test_coop_shares_one_crew_total() -> void:
	var result: Dictionary = MatchRules.tally("coop", scores(3, 2, 1, 0), seats(true, true, true, false), names(), 12)
	assert_eq(result.mode, "coop")
	assert_eq(result.headline, "Crew complete!")
	assert_eq(result.stars_collected, 6)
	assert_eq(result.lines.size(), 1)

func test_tally_cannot_be_forced_into_an_unplayable_mode() -> void:
	# One rider cannot play Versus, even if a peer or a stale setting asks for it.
	var result: Dictionary = MatchRules.tally("versus", scores(5, 0, 0, 0), seats(true, false, false, false), names(), 12)
	assert_eq(result.mode, "coop")

# ---- StarPlan and the courses

func test_every_course_has_the_same_twelve_stars_every_time() -> void:
	for definition: Dictionary in LevelDefs.LEVELS:
		var path: CoursePath = CoursePath.new()
		path.build(definition)
		var first: Array[Dictionary] = StarPlan.build(path)
		var second: Array[Dictionary] = StarPlan.build(path)
		assert_eq(first.size(), StarPlan.COUNT, definition.name)
		assert_eq(first, second, "%s: no randomness, so host and guests agree" % definition.name)
		var last_s: float = -1.0
		for star: Dictionary in first:
			assert_gt(star.s, last_s, "Stars are in route order")
			assert_lt(star.s, path.length - 8.0, "No star past the finish gate")
			last_s = star.s
			var width: float = path.sample(star.s).width
			assert_lt(absf(star.lateral), width * 0.5 - 1.5, "%s: star stays on the water" % definition.name)
			assert_false(StarPlan.over_hole(path, star.s, star.lateral), "%s: no star floats over a hole" % definition.name)

func test_the_nearest_rider_in_reach_wins_a_star() -> void:
	var star: Vector3 = Vector3(10, 1, 10)
	var all: Array[bool] = seats(true, true, true, true)
	var positions: Array[Vector3] = [Vector3(10.5, 1, 10), Vector3(12.5, 1, 10), Vector3(10, 1, 30), Vector3(0, 1, 0)]
	assert_eq(StarPlan.claimant(positions, all, star), 0)
	positions[0] = Vector3(11.8, 1, 10)
	positions[1] = Vector3(10.2, 1, 10)
	assert_eq(StarPlan.claimant(positions, all, star), 1, "Closer rider beats a lower seat number")
	positions = [Vector3(40, 1, 40), Vector3(40, 1, 40), Vector3(40, 1, 40), Vector3(40, 1, 40)]
	assert_eq(StarPlan.claimant(positions, all, star), -1, "Nobody in reach")

func test_empty_seats_and_wrong_heights_never_win() -> void:
	var star: Vector3 = Vector3(0, 5, 0)
	var positions: Array[Vector3] = [Vector3(0.2, 5, 0), Vector3(0.4, 5, 0), Vector3(0, 12, 0), Vector3(30, 5, 0)]
	assert_eq(StarPlan.claimant(positions, seats(false, true, true, false), star), 1, "Seat 1 is empty; seat 3 is on another level")
	assert_eq(StarPlan.claimant(positions, seats(false, false, true, false), star), -1)

func test_an_exact_tie_goes_to_the_lower_seat() -> void:
	var star: Vector3 = Vector3.ZERO
	var positions: Array[Vector3] = [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	assert_eq(StarPlan.claimant(positions, seats(true, true, true, true), star), 0)

# ---- Level integration

func make_level() -> SkyLevel:
	var level: SkyLevel = preload("res://scenes/levels/Level01.tscn").instantiate() as SkyLevel
	add_child_autofree(level)
	level.brain.enabled = false
	level.hud.controls.enabled = false
	return level

func test_the_course_builds_its_stars_and_the_hud_reports_them() -> void:
	var level: SkyLevel = make_level()
	assert_eq(level.course.stars.size(), StarPlan.COUNT)
	for star: Dictionary in level.course.stars:
		assert_eq(star.taken_by, -1)
		assert_true(star.node.visible)
	var view: Dictionary = level.run_snapshot()
	assert_eq(view.stars_total, StarPlan.COUNT)
	assert_eq(view.stars_collected, 0)
	assert_eq(view.crew[0].stars, 0)
	assert_eq(view.mode, "coop")

func test_a_rider_on_a_star_takes_it_once_and_it_counts_for_that_seat() -> void:
	var level: SkyLevel = make_level()
	level.begin_run()
	var star: Dictionary = level.course.stars[0]
	level.player.global_position = star.home - level.player.orbit.visual_offset(0, SharedRingPreview.SEAT_RADIUS, 0.5)
	level.player.orbit.angles[0] = 0.0
	level.check_stars()
	var seat: int = star.taken_by
	assert_gte(seat, 0, "A star within reach of a rider is taken")
	assert_eq(level.star_scores[seat], 1)
	assert_false(star.node.visible, "The star disappears")
	level.check_stars()
	assert_eq(level.star_scores[seat], 1, "A star cannot be taken twice")
	assert_eq(level.star_scores.reduce(func(a: int, b: int) -> int: return a + b, 0), 1)

func test_versus_run_ends_with_the_host_naming_a_winner() -> void:
	GameState.match_mode = "versus"
	var level: SkyLevel = make_level()
	# One local rider only: Versus falls back to co-op rather than naming a winner of one.
	assert_eq(level.match_mode, "coop")

func test_two_riders_versus_decides_the_winner_from_the_scores() -> void:
	GameState.match_mode = "versus"
	var level: SkyLevel = preload("res://scenes/levels/Level01.tscn").instantiate() as SkyLevel
	var slots: Array[Dictionary] = GameState.crew_slots.duplicate(true)
	var saved_slots: Array[Dictionary] = GameState.crew_slots.duplicate(true)
	slots[1] = CrewData.make_slot("assist", 1)
	GameState.crew_slots = slots
	add_child_autofree(level)
	level.brain.enabled = false
	level.hud.controls.enabled = false
	GameState.crew_slots = saved_slots
	assert_eq(level.match_mode, "versus")
	level.begin_run()
	level.star_scores.assign([2, 5, 0, 0])
	level.end_run(true)
	assert_eq(level.result.mode, "versus")
	assert_false(level.result.tie)
	assert_eq(level.result.winner_teams, [1])
	assert_true(str(level.result.headline).ends_with("wins!"))
	assert_eq(level.result.stars_collected, 7)

func test_snapshot_carries_scores_and_taken_stars_to_guests() -> void:
	var level: SkyLevel = make_level()
	level.star_scores.assign([1, 2, 0, 0])
	level.course.stars[3].taken_by = 1
	var packet: Dictionary = RingReplication.capture(level, 1, 1)
	assert_eq(packet.star_scores, [1, 2, 0, 0])
	assert_eq(packet.stars_taken.size(), StarPlan.COUNT)
	assert_eq(packet.stars_taken[3], 1)
	assert_eq(packet.stars_taken[0], -1)
	# A guest applies the host's numbers; it never decides anything itself.
	var guest: SkyLevel = make_level()
	var replication: RingReplication = RingReplication.new()
	replication.push(packet, 1.0)
	replication.apply(guest, 1.0)
	assert_eq(guest.star_scores, [1, 2, 0, 0] as Array[int])
	assert_eq(guest.course.stars[3].taken_by, 1)
	assert_false(guest.course.stars[3].node.visible)
	assert_true(guest.course.stars[0].node.visible)

func test_result_panel_names_the_winner_in_competitive_modes() -> void:
	var panels: RunPanels = RunPanels.new()
	add_child_autofree(panels)
	var versus: Dictionary = {"mode": "versus", "headline": "Ben wins!", "won": true}
	assert_eq(panels.result_title(versus), "Ben wins!")
	assert_eq(panels.result_title({"mode": "coop", "won": true}), "Crew complete!")
	assert_eq(panels.result_title({"mode": "coop", "won": false}), "Time's up")
	var text: String = panels.star_lines({"mode": "teams", "stars_total": 12, "stars_collected": 11, "lines": ["Team A: 6 stars", "Team B: 5 stars"], "won": false})
	assert_true(text.contains("Stars: 11 of 12"))
	assert_true(text.contains("Team A: 6 stars"))
	assert_true(text.contains("Time ran out"))
