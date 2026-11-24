class_name MatchRules
extends RefCounted

# Star Scramble scoring. Pure functions only: no nodes, no network, no saves.
# Every run is still one shared ring. Stars add a score on top of finishing the course:
#   coop   - the whole crew shares one star total
#   versus - every rider for themselves; most stars wins
#   teams  - 2 v 2; seats 1 + 3 (Team A) against seats 2 + 4 (Team B)
# The host awards stars and calls the winner; guests only display what the host sends.
const MODES: Array[String] = ["coop", "versus", "teams"]
const LABELS: Dictionary = {"coop": "Co-op", "versus": "Versus", "teams": "Teams 2v2"}
const TEAM_NAMES: Array[String] = ["Team A", "Team B"]

static func sanitize_mode(value: Variant) -> String:
	return value if value is String and value in MODES else "coop"

static func next_mode(mode: String) -> String:
	return MODES[(MODES.find(sanitize_mode(mode)) + 1) % MODES.size()]

static func label(mode: String) -> String:
	return LABELS[sanitize_mode(mode)]

static func rules_text(mode: String) -> String:
	match sanitize_mode(mode):
		"versus":
			return "Versus: grab the most stars to win!"
		"teams":
			return "Teams: seats 1+3 vs 2+4. Most stars wins!"
	return "Co-op: collect stars together."

## Team of a seat. Co-op is one team, versus is one team per seat, teams alternates seats.
static func team_of(mode: String, seat: int) -> int:
	match sanitize_mode(mode):
		"versus":
			return seat
		"teams":
			return seat % 2
	return 0

## The mode that can really be played with these seats: Teams needs a rider on both teams,
## Versus needs at least two riders, otherwise it falls back to Co-op.
static func effective_mode(mode: String, occupied: Array[bool]) -> String:
	mode = sanitize_mode(mode)
	var riders: int = occupied.count(true)
	if mode == "teams":
		var has_a: bool = occupied[0] or occupied[2]
		var has_b: bool = occupied[1] or occupied[3]
		return "teams" if has_a and has_b and riders >= 2 else ("versus" if riders >= 2 else "coop")
	if mode == "versus":
		return "versus" if riders >= 2 else "coop"
	return "coop"

## Riders who share a name get their seat number added ("Player P1", "Player P2") so the
## result screen never says "Player wins!" when two riders are called Player.
static func unique_names(names: Array[String], occupied: Array[bool]) -> Array[String]:
	var result: Array[String] = names.duplicate()
	for seat: int in range(result.size()):
		if not occupied[seat]:
			continue
		for other: int in range(result.size()):
			if other != seat and occupied[other] and names[other] == names[seat]:
				result[seat] = "%s P%d" % [names[seat], seat + 1]
				break
	return result

## Standings for a finished (or timed-out) run.
## scores: stars per seat. occupied: which seats have a rider. names: display names per seat.
static func tally(mode: String, scores: Array[int], occupied: Array[bool], names: Array[String], stars_total: int) -> Dictionary:
	mode = effective_mode(mode, occupied)
	names = unique_names(names, occupied)
	var teams: Array[Dictionary] = []
	for seat: int in range(4):
		if not occupied[seat]:
			continue
		var team: int = team_of(mode, seat)
		var entry: Dictionary = {}
		for item: Dictionary in teams:
			if item.team == team:
				entry = item
		if entry.is_empty():
			entry = {"team": team, "seats": [], "stars": 0, "label": ""}
			teams.append(entry)
		entry.seats.append(seat)
		entry.stars += scores[seat]
	for entry: Dictionary in teams:
		if mode == "teams":
			entry.label = "%s (%s)" % [TEAM_NAMES[entry.team], " + ".join(entry.seats.map(func(s: int) -> String: return names[s]))]
		elif mode == "versus":
			entry.label = names[entry.seats[0]]
		else:
			entry.label = "Crew"
	var best: int = -1
	for entry: Dictionary in teams:
		best = maxi(best, entry.stars)
	var winners: Array[int] = []
	for entry: Dictionary in teams:
		if entry.stars == best:
			winners.append(entry.team)
	var lines: Array[String] = []
	var sorted: Array[Dictionary] = teams.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.stars > b.stars)
	for entry: Dictionary in sorted:
		lines.append("%s: %d star%s" % [entry.label, entry.stars, "" if entry.stars == 1 else "s"])
	var headline: String = "Crew complete!"
	if mode != "coop":
		if winners.size() > 1:
			headline = "It's a tie!"
		else:
			var winner: Dictionary = {}
			for entry: Dictionary in teams:
				if entry.team == winners[0]:
					winner = entry
			headline = "%s wins!" % winner.label.split(" (")[0]
	return {"mode": mode, "scores": scores.duplicate(), "stars_total": stars_total,
		"stars_collected": scores.reduce(func(a: int, b: int) -> int: return a + b, 0),
		"winner_teams": winners, "tie": winners.size() > 1, "headline": headline, "lines": lines}
