class_name LevelBuilder
extends Node3D

var definition: Dictionary = {}
var banks: Array[CoursePiece] = []
var beans: Array[CoursePiece] = []
var checkpoints: Array[CoursePiece] = []
var start: Marker3D
var finish: CoursePiece
var water_segments: Array[CoursePiece] = []
var decor: SkyDecor
var holes: Array[CourseHole] = []
var water_material: ShaderMaterial
const BANK_THICKNESS: float = 3.2

func piece(scene_name: String, at: Vector3) -> CoursePiece:
	var packed: PackedScene = load("res://scenes/course/%s.tscn" % scene_name)
	var instance: CoursePiece = packed.instantiate() as CoursePiece
	instance.position = at
	return instance

func build(data: Dictionary) -> void:
	for child: Node in get_children():
		child.free()
	banks.clear()
	water_segments.clear()
	holes.clear()
	beans.clear()
	checkpoints.clear()
	definition = data.duplicate(true)
	# One shared material per course, so preview/test worlds cannot share holes.
	water_material = SkyEnvironment.water().duplicate() as ShaderMaterial
	var cutouts: PackedVector3Array = PackedVector3Array()
	cutouts.resize(8)
	var hole_data: Array = data.get("holes", [])
	assert(hole_data.size() <= 8, "Water supports at most eight holes")
	for index: int in range(hole_data.size()):
		var entry: Dictionary = hole_data[index]
		cutouts[index] = Vector3(entry.pos[0], -entry.pos[1], entry.radius)
		var hole: CourseHole = preload("res://scenes/course/Hole.tscn").instantiate() as CourseHole
		hole.position = LevelDefs.world_point(entry.pos)
		hole.radius = entry.radius
		holes.append(hole)
		add_child(hole)
	water_material.set_shader_parameter("holes", cutouts)
	var finish_d: float = data.finish_d
	var segments: Array = data.segments
	for index: int in range(segments.size()):
		var segment: Dictionary = segments[index]
		var water: CoursePiece = piece("Water", Vector3(segment.x, 0, -segment.d - segment.length / 2.0))
		water.dimensions = Vector3(segment.width + 0.02, 0, segment.length + 0.02)
		water_segments.append(water)
		add_child(water)
		water.visual.material_override = water_material
		for side: float in [-1.0, 1.0]:
			var wall_x: float = segment.x + side * segment.width / 2.0
			var bank: CoursePiece = piece("Bank", Vector3(wall_x + side * BANK_THICKNESS / 2.0, 0, -segment.d - segment.length / 2.0))
			bank.dimensions = Vector3(BANK_THICKNESS, 40.9, segment.length)
			bank.rim_at.x = -side * BANK_THICKNESS / 2.0
			banks.append(bank)
			add_child(bank)
			if index < segments.size() - 1:
				var next: Dictionary = segments[index + 1]
				var next_x: float = next.x + side * next.width / 2.0
				if not is_equal_approx(wall_x, next_x):
					# Put the connector on the outside of the turn, as in the sample.
					var forward: float = 1.0 if (next_x - wall_x) * side < 0.0 else -1.0
					var connector: CoursePiece = piece("Bank", Vector3((wall_x + next_x) / 2.0, 0, -next.d - forward * BANK_THICKNESS / 2.0))
					connector.dimensions = Vector3(absf(next_x - wall_x), 40.9, BANK_THICKNESS)
					connector.rim_size = Vector3(absf(next_x - wall_x) + 0.7, 0.32, 0.7)
					connector.rim_at.z = forward * BANK_THICKNESS / 2.0
					add_child(connector)
	for island_data: Dictionary in data.islands:
		var island: CoursePiece = piece("Island", LevelDefs.world_point(island_data.pos))
		island.radius = island_data.radius
		add_child(island)
	for point: Array in data.beans:
		var bean: CoursePiece = piece("Bean", LevelDefs.world_point(point))
		beans.append(bean)
		add_child(bean)
	for distance: float in data.checkpoints:
		var checkpoint: CoursePiece = piece("Checkpoint", Vector3(center_at(distance), 0, -distance))
		checkpoint.distance = distance
		checkpoint.course_width = width_at(distance)
		checkpoints.append(checkpoint)
		add_child(checkpoint)
	finish = piece("FinishRing", Vector3(center_at(finish_d), 0, -finish_d))
	finish.course_width = width_at(finish_d)
	add_child(finish)
	start = Marker3D.new()
	start.name = "Start"
	start.position = LevelDefs.world_point(data.start)
	add_child(start)
	for index: int in range(2):
		var segment: Dictionary = segments[0] if index == 0 else segments[-1]
		var boundary: float = segment.d if index == 0 else segment.d + segment.length
		var direction: float = -1.0 if index == 0 else 1.0
		var cap: CoursePiece = piece("Bank", Vector3(segment.x, 0, -boundary - direction * BANK_THICKNESS / 2.0))
		cap.dimensions = Vector3(segment.width + BANK_THICKNESS * 2, 40.9, BANK_THICKNESS)
		cap.rim_size = Vector3(segment.width + 0.7, 0.32, 0.7)
		cap.rim_at.z = direction * BANK_THICKNESS / 2.0
		add_child(cap)
	var start_line: CoursePiece = CoursePiece.new()
	start_line.kind = "marker"
	start_line.position = Vector3(center_at(1.2), 0, -1.2)
	add_child(start_line)
	start_line.build_checker(width_at(1.2))
	decor = SkyDecor.new()
	decor.name = "SkyDecor"
	add_child(decor)
	decor.build(segments, float(segments[-1].d + segments[-1].length))

func center_at(distance: float) -> float:
	for segment: Dictionary in definition.get("segments", []):
		if distance >= segment.d and distance < segment.d + segment.length:
			return float(segment.x)
	return float(definition.segments[0 if distance < 0 else -1].x)

func width_at(distance: float) -> float:
	for segment: Dictionary in definition.get("segments", []):
		if distance >= segment.d and distance < segment.d + segment.length:
			return float(segment.width)
	return float(definition.segments[0 if distance < 0 else -1].width)
