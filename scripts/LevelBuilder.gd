class_name LevelBuilder
extends Node3D

var definition: Dictionary = {}
var banks: Array[CoursePiece] = []
var beans: Array[CoursePiece] = []
var checkpoints: Array[CoursePiece] = []
var start: Marker3D
var finish: CoursePiece

func piece(scene_name: String, at: Vector3) -> CoursePiece:
	var packed: PackedScene = load("res://scenes/course/%s.tscn" % scene_name)
	var instance: CoursePiece = packed.instantiate() as CoursePiece
	instance.position = at
	return instance

func build(data: Dictionary) -> void:
	for child: Node in get_children():
		child.free()
	banks.clear()
	beans.clear()
	checkpoints.clear()
	definition = data.duplicate(true)
	var finish_d: float = data.finish_d
	var water: CoursePiece = piece("Water", Vector3(0, -0.03, -finish_d / 2.0))
	water.dimensions = Vector3(60, 0, finish_d + 40)
	add_child(water)
	var segments: Array = data.segments
	for index: int in range(segments.size()):
		var segment: Dictionary = segments[index]
		for side: float in [-1.0, 1.0]:
			var bank: CoursePiece = piece("Bank", Vector3(segment.x + side * (segment.width / 2.0 + 1.5), 0, -segment.d - segment.length / 2.0))
			bank.dimensions = Vector3(3.0, 1.2, segment.length + 0.08)
			banks.append(bank)
			add_child(bank)
		# Bridge offset joints with transverse banks; no gaps or escape route.
		if index > 0:
			var previous: Dictionary = segments[index - 1]
			for side: float in [-1.0, 1.0]:
				var left: float = previous.x + side * (previous.width / 2.0 + 1.5)
				var right: float = segment.x + side * (segment.width / 2.0 + 1.5)
				var connector: CoursePiece = piece("Bank", Vector3((left + right) / 2.0, 0, -segment.d))
				connector.dimensions = Vector3(absf(right - left) + 3.0, 1.2, 1.0)
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
	for distance: float in [-2.0, float(segments[-1].d + segments[-1].length)]:
		var cap: CoursePiece = piece("Bank", Vector3(center_at(maxf(0, distance)), 0, -distance))
		cap.dimensions = Vector3(width_at(maxf(0, distance)) + 6, 1.2, 3)
		add_child(cap)

func center_at(distance: float) -> float:
	for segment: Dictionary in definition.get("segments", []):
		if distance >= segment.d and distance < segment.d + segment.length:
			return float(segment.x)
	return float(definition.segments[-1].x)

func width_at(distance: float) -> float:
	for segment: Dictionary in definition.get("segments", []):
		if distance >= segment.d and distance < segment.d + segment.length:
			return float(segment.width)
	return float(definition.segments[-1].width)
