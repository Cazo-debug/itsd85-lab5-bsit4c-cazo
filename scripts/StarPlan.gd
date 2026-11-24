class_name StarPlan
extends RefCounted

# Where the collectible stars sit. Deterministic: no random numbers, so the host and every
# guest build exactly the same stars from the same course.
const COUNT: int = 12
const FIRST: float = 0.09
const LAST: float = 0.90
# Lateral pattern (fraction of the reach): left, right, middle, ... so riders must rotate
# around the rim to reach different banks instead of one rider taking everything.
const PATTERN: Array[float] = [-1.0, 1.0, 0.0, 1.0, -1.0, 0.0]
const MAX_REACH: float = 2.3
const MIN_REACH: float = 1.1

## Returns [{"s": distance, "lateral": offset}] for a built path.
static func build(path: CoursePath) -> Array[Dictionary]:
	var stars: Array[Dictionary] = []
	for index: int in range(COUNT):
		var fraction: float = lerpf(FIRST, LAST, float(index) / float(COUNT - 1))
		var s: float = fraction * path.length
		var width: float = path.sample(s).width
		var reach: float = clampf(width * 0.2, MIN_REACH, MAX_REACH)
		var lateral: float = PATTERN[index % PATTERN.size()] * reach
		if over_hole(path, s, lateral):
			lateral = -lateral
		if over_hole(path, s, lateral):
			lateral = 0.0
		stars.append({"s": s, "lateral": lateral})
	return stars

## Which seat wins a star. seat_positions: world position per seat; occupied: who is riding.
## The nearest rider within reach wins; an exact tie goes to the lower seat. -1 = nobody.
const REACH: float = 1.9
const MAX_HEIGHT_GAP: float = 2.2

static func claimant(seat_positions: Array[Vector3], occupied: Array[bool], star: Vector3) -> int:
	var winner: int = -1
	var best: float = REACH
	for seat: int in range(seat_positions.size()):
		if not occupied[seat]:
			continue
		var gap: Vector3 = seat_positions[seat] - star
		if absf(gap.y) > MAX_HEIGHT_GAP:
			continue
		var distance: float = Vector2(gap.x, gap.z).length()
		if distance < best:
			best = distance
			winner = seat
	return winner

static func over_hole(path: CoursePath, s: float, lateral: float) -> bool:
	for hole: Dictionary in path.holes:
		var margin: float = hole.radius + 1.3
		if absf(hole.s - s) < margin and absf(hole.lateral - lateral) < margin:
			return true
	return false
