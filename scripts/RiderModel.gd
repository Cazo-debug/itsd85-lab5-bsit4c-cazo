class_name RiderModel
extends Node3D

# Chunky cartoon animal rider. Rider-local: +Z is the face, -Z the rear, y = 0 is
# the top of the tube it sits on. The preview turns each rider to face the hub.
#
# The body is one sculpted pear shape with the butt built into the silhouette
# (RiderSculpt.pear_body), in the animal's own colour. Tails and back markings keep
# each animal readable from behind, where the chase camera mostly sees them.
# Secondary motion (lean springs, butt/belly jiggle, arm flail, tail wag, blink,
# panic, cheer) is presentation only. It runs in the toon shader through baked
# masks, so a rider stays three visible meshes: body, head and one face.
#
# Imported models: drop res://assets/riders/<animal>.glb (or .gltf/.fbx/.tscn) and
# it replaces the sculpted body (see assets/riders/README.md). The sculpted
# animals below are the built-in fallback.
const DARK: Color = Color("1b1f27")
const HOT: Color = Color("ff384c")
const LEAN: float = 0.26 # forward lean toward the float centre
const IMPORTED_HEIGHT: float = 1.9
const IMPORT_EXTENSIONS: Array[String] = ["glb", "gltf", "fbx", "tscn"]
# Pear profile (radius, height) in Upper space: wide seat, soft waist, narrow shoulders.
const BODY: PackedVector2Array = [Vector2(0.0, -0.10), Vector2(0.34, -0.09), Vector2(0.55, -0.03), Vector2(0.67, 0.07),
	Vector2(0.73, 0.20), Vector2(0.73, 0.34), Vector2(0.69, 0.48), Vector2(0.63, 0.62), Vector2(0.58, 0.76),
	Vector2(0.54, 0.88), Vector2(0.48, 0.99), Vector2(0.37, 1.08), Vector2(0.22, 1.14), Vector2(0.0, 1.16)]
const SHOULDER: Vector3 = Vector3(0.52, 0.92, 0.04) # right shoulder, Upper space
static var toon_material: ShaderMaterial

var appearance: Dictionary = {}
var pose_root: Node3D
var body_root: Node3D
var upper: Node3D
var head_root: Node3D
var eyes_root: Node3D
var squint_root: Node3D
var happy_root: Node3D
## The animal's own colour with zero glow; the butt cools back to it.
var cheek_color: Color = Color(1, 1, 1, 0)
## Butt colour sent to the toon shader: rgb = tint, a = glow amount (follows thrust_heat).
var charge_color: Color = Color(1, 1, 1, 0)
var body_material: ShaderMaterial
var imported: Node3D
var glow_overlay: StandardMaterial3D
var thrust_heat: float = 0.0
var pose_clock: float = 0.0
var head_top: float = 0.74
var baked: bool = false
var burst_clock: float = 10.0
var idle_clock: float = 0.0
var phase: float = 0.0
var look: Vector2 = Vector2.ZERO
var look_target: Vector2 = Vector2.ZERO
var look_timer: float = 0.0
## Direction this rider leans toward, in its own frame (x: forward, y: right), m/s^2.
var float_lean: Vector2 = Vector2.ZERO
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var target: Node3D
## "ride", "panic" (falling) or "cheer" (shared finish).
var mood: String = "ride"
var mood_clock: float = 0.0
var flail_clock: float = 10.0
var flail_strength: float = 0.0
var lean: Vector2 = Vector2.ZERO
var lean_velocity: Vector2 = Vector2.ZERO
var jiggle: Vector3 = Vector3.ZERO
var jiggle_velocity: Vector3 = Vector3.ZERO
var arms: Vector4 = Vector4.ZERO # left raise, left swing, right raise, right swing
var blink_timer: float = 2.0
var blink_clock: float = 1.0
var tail_root: Vector3 = Vector3(0, 0.55, -0.7)

static func material(color: Color) -> StandardMaterial3D:
	return AvatarModel.material(color)

static func toon() -> ShaderMaterial:
	if toon_material == null:
		toon_material = ShaderMaterial.new()
		toon_material.shader = preload("res://shaders/toon.gdshader")
	return toon_material

static func imported_scene(animal: String) -> PackedScene:
	for extension: String in IMPORT_EXTENSIONS:
		var path: String = "res://assets/riders/%s.%s" % [animal, extension]
		if ResourceLoader.exists(path):
			return load(path) as PackedScene
	return null

func _ready() -> void:
	if get_child_count() == 0:
		apply(AvatarData.default_avatar())

# ---------- shape helpers ----------

func part(mesh: Mesh, color: Color, at: Vector3, stretch: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material(color)
	instance.position = at
	instance.scale = stretch
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(target if target != null else body_root).add_child(instance)
	return instance

func ball(color: Color, at: Vector3, stretch: Vector3) -> MeshInstance3D:
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radial_segments = 16
	mesh.rings = 8
	return part(mesh, color, at, stretch)

func cylinder(color: Color, at: Vector3, bottom: float, top: float, height: float) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.radial_segments = 14
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	return part(mesh, color, at)

func cone(color: Color, at: Vector3, radius: float, height: float, tilt: Vector3) -> MeshInstance3D:
	var instance: MeshInstance3D = cylinder(color, at, radius, 0.0, height)
	instance.rotation = tilt
	return instance

func limb(color: Color, from: Vector3, to: Vector3, r0: float, r1: float) -> MeshInstance3D:
	var instance: MeshInstance3D = part(RiderSculpt.limb_mesh(from.distance_to(to), r0, r1), color, Vector3.ZERO)
	instance.transform = RiderSculpt.limb_transform(from, to)
	return instance

func box(color: Color, at: Vector3, size: Vector3, tilt: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var instance: MeshInstance3D = part(BoxMesh.new(), color, at, size)
	instance.rotation = tilt
	return instance

## Shader mask baked with this part: x = arm side (-1/+1), y = tail weight, z = butt, w = belly.
func mark(instance: MeshInstance3D, mask: Vector4) -> MeshInstance3D:
	instance.set_meta("mask", mask)
	return instance

## Point on the sculpted body surface in Body space (angle 0 = front, PI = rear).
func body_point(y: float, angle: float = PI, inset: float = 0.0) -> Vector3:
	return RiderSculpt.pear_point(BODY, Transform3D(Basis.IDENTITY, upper.position), upper.transform, y, angle, inset)

# Open eyes, the strained "> <" squint and the happy "^ ^" each get their own root,
# centred on the eyes so a blink can squash them in place.
func eyes(at: Vector3, size: float) -> void:
	for root: Node3D in [eyes_root, squint_root, happy_root]:
		root.position = Vector3(0, at.y, at.z)
	for side: float in [-1.0, 1.0]:
		var spot: Vector3 = Vector3(at.x * side, 0, 0)
		target = eyes_root
		ball(Color.WHITE, spot, Vector3.ONE * size * 1.08)
		ball(DARK, spot + Vector3(0, -size * 0.08, size * 0.32), Vector3(0.64, 0.74, 0.46) * size)
		ball(Color.WHITE, spot + Vector3(size * 0.14, size * 0.12, size * 0.52), Vector3.ONE * size * 0.26)
		target = squint_root
		for slant: float in [-1.0, 1.0]:
			box(DARK, spot + Vector3(0, slant * size * 0.12, size * 0.42), Vector3(size * 0.62, size * 0.13, 0.05), Vector3(0, 0, slant * side * 0.42))
		target = happy_root
		for stroke: float in [-1.0, 1.0]:
			box(DARK, spot + Vector3(stroke * size * 0.15, size * 0.02, size * 0.44), Vector3(size * 0.40, size * 0.13, 0.05), Vector3(0, 0, -stroke * 0.65))
	target = head_root

# Seated pear body: knees tucked, chest leaning in, both hands gripping the tube handles.
func build_body(main: Color, belly: Color, limb_color: Color, foot: Color, shoulder_color: Color = main) -> void:
	cheek_color = Color(main, 0.0)
	target = body_root
	for side: float in [-1.0, 1.0]:
		limb(limb_color, Vector3(side * 0.30, 0.18, 0.10), Vector3(side * 0.42, 0.44, 0.64), 0.23, 0.19)
		limb(limb_color, Vector3(side * 0.42, 0.44, 0.64), Vector3(side * 0.38, -0.12, 0.76), 0.18, 0.14)
		ball(foot, Vector3(side * 0.38, -0.16, 0.86), Vector3(0.32, 0.17, 0.40))
	part(RiderSculpt.pear_body(BODY, Transform3D(Basis.IDENTITY, upper.position), upper.transform), main, Vector3.ZERO)
	target = upper
	mark(ball(belly, Vector3(0, 0.50, 0.32), Vector3(0.84, 0.80, 0.52)), Vector4(0, 0, 0, 0.8))
	for side: float in [-1.0, 1.0]:
		var shoulder: Vector3 = Vector3(side * SHOULDER.x, SHOULDER.y, SHOULDER.z)
		var elbow: Vector3 = Vector3(side * 0.80, 0.52, 0.20)
		var hand: Vector3 = upper.transform.affine_inverse() * Vector3(side * 0.74, 0.08, 0.34)
		mark(ball(shoulder_color, shoulder, Vector3.ONE * 0.42), Vector4(side, 0, 0, 0))
		mark(limb(shoulder_color, shoulder, elbow, 0.21, 0.17), Vector4(side, 0, 0, 0))
		mark(limb(limb_color, elbow, hand, 0.17, 0.14), Vector4(side, 0, 0, 0))
		mark(ball(limb_color, hand, Vector3(0.32, 0.28, 0.32)), Vector4(side, 0, 0, 0))
	tail_root = body_point(0.50, PI, 0.06)
	target = body_root

func build_hippo() -> void:
	var main: Color = Color("7b69b9")
	var pink: Color = Color("e98aac")
	build_body(main, pink, main, pink)
	mark(limb(main, tail_root, tail_root + Vector3(0, -0.14, -0.20), 0.07, 0.04), Vector4(0, 0.6, 0, 0))
	mark(ball(main.darkened(0.35), tail_root + Vector3(0, -0.17, -0.26), Vector3.ONE * 0.12), Vector4(0, 1.0, 0, 0))
	target = head_root
	ball(main, Vector3(0, 0.36, 0.02), Vector3(1.00, 0.80, 0.92))
	ball(main.lightened(0.12), Vector3(0, 0.20, 0.40), Vector3(1.06, 0.66, 0.74))
	ball(DARK, Vector3(0, 0.06, 0.725), Vector3(0.26, 0.05, 0.05))
	for side: float in [-1.0, 1.0]:
		ball(DARK, Vector3(side * 0.18, 0.40, 0.72), Vector3(0.12, 0.07, 0.09))
		box(Color.WHITE, Vector3(side * 0.16, -0.08, 0.66), Vector3(0.10, 0.12, 0.06))
		ball(main, Vector3(side * 0.36, 0.74, -0.10), Vector3(0.22, 0.26, 0.13))
		ball(pink, Vector3(side * 0.36, 0.74, -0.05), Vector3(0.12, 0.15, 0.06))
	eyes(Vector3(0.22, 0.62, 0.22), 0.27)
	head_top = 0.78

func build_pig() -> void:
	var main: Color = Color("ea7891")
	var snout: Color = Color("d45c78")
	build_body(main, Color("f7a9b9"), main, snout)
	var curl: Vector3 = tail_root + Vector3(0, 0.05, -0.16)
	for index: int in range(6):
		var angle: float = index * 1.15
		mark(ball(snout, curl + Vector3(cos(angle) * 0.08, sin(angle) * 0.08, -index * 0.022), Vector3.ONE * 0.085), Vector4(0, 0.4 + index * 0.12, 0, 0))
	target = head_root
	ball(main, Vector3(0, 0.36, 0.04), Vector3(0.98, 0.90, 0.92))
	var nose: MeshInstance3D = cylinder(snout, Vector3(0, 0.26, 0.48), 0.24, 0.24, 0.20)
	nose.rotation.x = PI / 2.0
	ball(DARK, Vector3(0, 0.07, 0.40), Vector3(0.22, 0.045, 0.05))
	for side: float in [-1.0, 1.0]:
		ball(Color("7a2f45"), Vector3(side * 0.09, 0.26, 0.58), Vector3(0.08, 0.11, 0.04))
		ball(Color("ff7f9e"), Vector3(side * 0.32, 0.24, 0.34), Vector3(0.16, 0.10, 0.07))
		cone(main, Vector3(side * 0.32, 0.74, 0.08), 0.19, 0.38, Vector3(0.85, 0, -side * 0.5))
	eyes(Vector3(0.21, 0.46, 0.38), 0.20)
	head_top = 0.80

func build_panda() -> void:
	var white: Color = Color("eeeee9")
	var black: Color = Color("202128")
	# Black shoulders and arms, black ears and tail: reads as a panda from behind.
	build_body(white, white, black, black, black)
	mark(ball(black, tail_root + Vector3(0, 0, -0.05), Vector3.ONE * 0.16), Vector4(0, 0.6, 0, 0))
	target = head_root
	ball(white, Vector3(0, 0.38, 0.04), Vector3(1.04, 0.92, 0.94))
	ball(black, Vector3(0, 0.26, 0.48), Vector3(0.17, 0.11, 0.09))
	ball(DARK, Vector3(0, 0.13, 0.44), Vector3(0.16, 0.04, 0.04))
	for side: float in [-1.0, 1.0]:
		var patch: MeshInstance3D = ball(black, Vector3(side * 0.20, 0.42, 0.36), Vector3(0.27, 0.34, 0.15))
		patch.rotation.z = side * 0.45
		ball(black, Vector3(side * 0.36, 0.80, -0.02), Vector3(0.32, 0.32, 0.20))
	eyes(Vector3(0.20, 0.44, 0.43), 0.15)
	head_top = 0.84

func build_penguin() -> void:
	var navy: Color = Color("1f2e52")
	var orange: Color = Color("ff8a1e")
	build_body(navy, Color("f5f3ea"), navy, orange)
	var feathers: MeshInstance3D = cone(navy.darkened(0.25), tail_root + Vector3(0, -0.16, -0.12), 0.17, 0.32, Vector3(-2.3, 0, 0))
	feathers.scale = Vector3(1.4, 1.0, 0.5)
	mark(feathers, Vector4(0, 0.7, 0, 0))
	target = head_root
	ball(navy, Vector3(0, 0.34, 0.02), Vector3(0.92, 0.88, 0.90))
	ball(Color("f5f3ea"), Vector3(0, 0.30, 0.24), Vector3(0.70, 0.60, 0.54))
	var beak: MeshInstance3D = cone(orange, Vector3(0, 0.25, 0.58), 0.13, 0.30, Vector3(PI / 2.0, 0, 0))
	beak.scale = Vector3(1.25, 1.0, 0.7)
	cone(navy, Vector3(0, 0.80, -0.02), 0.10, 0.22, Vector3(-0.4, 0, 0))
	for side: float in [-1.0, 1.0]:
		ball(Color("ff9fb8"), Vector3(side * 0.28, 0.24, 0.38), Vector3(0.13, 0.08, 0.05))
	eyes(Vector3(0.16, 0.42, 0.46), 0.17)
	head_top = 0.78

func build_bunny() -> void:
	var main: Color = Color("c9b8a4")
	var cream: Color = Color("f6eee4")
	var pink: Color = Color("f08aa6")
	build_body(main, cream, main, cream)
	mark(ball(Color("fbf8f2"), tail_root + Vector3(0, 0.02, -0.10), Vector3.ONE * 0.32), Vector4(0, 0.5, 0, 0))
	target = head_root
	ball(main, Vector3(0, 0.34, 0.04), Vector3(0.94, 0.86, 0.88))
	ball(pink, Vector3(0, 0.32, 0.46), Vector3(0.12, 0.08, 0.06))
	box(Color.WHITE, Vector3(0, 0.14, 0.42), Vector3(0.14, 0.11, 0.04))
	for side: float in [-1.0, 1.0]:
		ball(cream, Vector3(side * 0.12, 0.24, 0.38), Vector3(0.28, 0.22, 0.18))
		limb(main, Vector3(side * 0.16, 0.66, -0.04), Vector3(side * 0.30, 1.36, -0.18), 0.15, 0.11)
		limb(pink, Vector3(side * 0.165, 0.72, 0.05), Vector3(side * 0.29, 1.28, -0.07), 0.08, 0.06)
	eyes(Vector3(0.21, 0.44, 0.36), 0.19)
	head_top = 0.76

func build_cat() -> void:
	var main: Color = Color("ef8a1f")
	var stripe: Color = Color("b8560a")
	var cream: Color = Color("ffe2bd")
	build_body(main, cream, main, cream)
	var bend: Vector3 = tail_root + Vector3(0.10, 0.04, -0.30)
	var rise: Vector3 = tail_root + Vector3(0.22, 0.42, -0.46)
	var tip: Vector3 = tail_root + Vector3(0.20, 0.74, -0.36)
	mark(limb(main, tail_root, bend, 0.10, 0.09), Vector4(0, 0.35, 0, 0))
	mark(limb(main, bend, rise, 0.09, 0.08), Vector4(0, 0.7, 0, 0))
	mark(limb(stripe, rise, tip, 0.08, 0.07), Vector4(0, 1.0, 0, 0))
	for height: float in [0.62, 0.78, 0.92]:
		ball(stripe, body_point(height, PI, 0.03), Vector3(0.40, 0.07, 0.12))
	target = head_root
	ball(main, Vector3(0, 0.35, 0.04), Vector3(1.00, 0.84, 0.90))
	ball(Color("ff8fa8"), Vector3(0, 0.30, 0.47), Vector3(0.11, 0.07, 0.05))
	ball(DARK, Vector3(0, 0.17, 0.46), Vector3(0.14, 0.035, 0.04))
	for index: int in range(3):
		ball(stripe, Vector3((index - 1) * 0.16, 0.72, 0.10), Vector3(0.09, 0.07, 0.34))
	for side: float in [-1.0, 1.0]:
		ball(cream, Vector3(side * 0.11, 0.22, 0.40), Vector3(0.25, 0.18, 0.16))
		cone(main, Vector3(side * 0.29, 0.74, 0.0), 0.18, 0.36, Vector3(0, 0, -side * 0.35))
		cone(Color("ffb3c1"), Vector3(side * 0.29, 0.73, 0.07), 0.09, 0.22, Vector3(0, 0, -side * 0.35))
	eyes(Vector3(0.22, 0.44, 0.38), 0.20)
	head_top = 0.80

# ---------- assembly ----------

func apply(avatar: Dictionary) -> void:
	appearance = AvatarData.sanitize(avatar)
	for child: Node in get_children():
		child.free()
	baked = false
	imported = null
	pose_root = Node3D.new()
	pose_root.name = "Pose"
	add_child(pose_root)
	body_root = Node3D.new()
	body_root.name = "Body"
	pose_root.add_child(body_root)
	upper = Node3D.new()
	upper.name = "Upper"
	upper.position = Vector3(0, 0.08, 0)
	upper.rotation.x = LEAN
	body_root.add_child(upper)
	head_root = Node3D.new()
	head_root.name = "Head"
	head_root.position = Vector3(0, 1.08, 0.10)
	upper.add_child(head_root)
	eyes_root = Node3D.new()
	head_root.add_child(eyes_root)
	squint_root = Node3D.new()
	squint_root.visible = false
	head_root.add_child(squint_root)
	happy_root = Node3D.new()
	happy_root.visible = false
	head_root.add_child(happy_root)
	body_material = toon().duplicate() as ShaderMaterial
	var outfit: Color = AvatarData.OUTFIT_COLORS[appearance.outfit]
	var animal: String = AvatarData.ANIMALS[appearance.skin]
	var scene: PackedScene = imported_scene(animal)
	if scene != null:
		attach_imported(scene)
		return
	match animal:
		"pig": build_pig()
		"panda": build_panda()
		"penguin": build_penguin()
		"bunny": build_bunny()
		"cat": build_cat()
		_: build_hippo()
	add_hat(outfit)
	charge_color = cheek_color
	body_material.set_shader_parameter("butt_tint", charge_color)
	body_material.set_shader_parameter("shoulder", upper.transform * SHOULDER)
	body_material.set_shader_parameter("tail_root", tail_root)
	target = null

func add_hat(outfit: Color) -> void:
	target = head_root
	var lift: float = head_top - 1.72
	match AvatarData.HATS[appearance.hat]:
		"cap", "propeller":
			ball(outfit, Vector3(0, 1.77 + lift, 0), Vector3(1.0, 0.22, 0.95))
			ball(outfit.lightened(0.2), Vector3(0, 1.70 + lift, 0.35), Vector3(1.0, 0.05, 0.75))
			if appearance.hat == 3:
				cylinder(Color.WHITE, Vector3(0, 2.02 + lift, 0), 0.04, 0.04, 0.3)
				box(Color("ffcf50"), Vector3(0, 2.18 + lift, 0), Vector3(1.15, 0.06, 0.18))
		"crown":
			cylinder(Color("ffcf50"), Vector3(0, 1.85 + lift, 0), 0.42, 0.42, 0.25)
			for index: int in range(5):
				var angle: float = TAU * index / 5.0
				cylinder(Color("ffcf50"), Vector3(cos(angle) * 0.34, 2.08 + lift, sin(angle) * 0.34), 0.13, 0, 0.35)
		"bucket":
			cylinder(outfit, Vector3(0, 1.87 + lift, 0), 0.48, 0.35, 0.44)
			cylinder(outfit.lightened(0.2), Vector3(0, 1.67 + lift, 0), 0.58, 0.58, 0.08)

func attach_imported(scene: PackedScene) -> void:
	imported = scene.instantiate() as Node3D
	if imported == null:
		return
	body_root.add_child(imported)
	var bounds: AABB = visual_bounds(imported, Transform3D.IDENTITY)
	if bounds.size.y > 0.001:
		var fit: float = IMPORTED_HEIGHT / bounds.size.y
		imported.scale = Vector3.ONE * fit
		imported.position.y = -bounds.position.y * fit
	glow_overlay = StandardMaterial3D.new()
	glow_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_overlay.albedo_color = Color(1, 0.22, 0.28, 0)
	for mesh: MeshInstance3D in find_meshes(imported):
		mesh.material_overlay = glow_overlay
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var player: AnimationPlayer = find_animation_player(imported)
	if player != null:
		var clips: PackedStringArray = player.get_animation_list()
		var chosen: String = clips[0] if not clips.is_empty() else ""
		for wanted: String in ["Sit", "Sitting", "sit", "Idle", "idle"]:
			if wanted in clips:
				chosen = wanted
				break
		if not chosen.is_empty():
			player.get_animation(chosen).loop_mode = Animation.LOOP_LINEAR
			player.play(chosen)

func visual_bounds(node: Node, xform: Transform3D) -> AABB:
	var result: AABB = AABB()
	var found: bool = false
	var local: Transform3D = xform * (node.transform if node is Node3D else Transform3D.IDENTITY)
	if node is VisualInstance3D:
		result = local * (node as VisualInstance3D).get_aabb()
		found = true
	for child: Node in node.get_children():
		var inner: AABB = visual_bounds(child, local)
		if inner.size != Vector3.ZERO:
			result = inner if not found else result.merge(inner)
			found = true
	return result

func find_meshes(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		meshes.append(node)
	for child: Node in node.get_children():
		meshes.append_array(find_meshes(child))
	return meshes

func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child: Node in node.get_children():
		var found: AnimationPlayer = find_animation_player(child)
		if found != null:
			return found
	return null

## Merge the static parts into a few toon-shaded meshes: the body (with motion masks and
## its own material), the head, and the open / squint / happy faces (one shown at a time).
func bake() -> void:
	if baked or imported != null or not is_inside_tree():
		return
	baked = true
	var body_skip: Array[Node] = [head_root]
	MeshBatch.bake(body_root, body_skip, true, true).material_override = body_material
	var head_skip: Array[Node] = [eyes_root, squint_root, happy_root]
	MeshBatch.bake(head_root, head_skip, true).material_override = toon()
	for face: Node3D in [eyes_root, squint_root, happy_root]:
		MeshBatch.bake(face).material_override = toon()

# ---------- animation (presentation only) ----------

func setup_motion(seat: int) -> void:
	rng.seed = 7919 * (seat + 1)
	phase = seat * 1.7
	blink_timer = 1.0 + seat * 0.9

## Where this rider should lean, in its own frame (x: forward, y: right). The float
## reports it from its own motion: back against surges, into turns.
func set_float_motion(lean_toward: Vector2) -> void:
	float_lean = lean_toward

func set_mood(value: String) -> void:
	if value != mood:
		mood = value
		mood_clock = 0.0

## Hit by an obstacle: arms flail, soft parts wobble.
func flail(strength: float = 1.0) -> void:
	flail_clock = 0.0
	flail_strength = clampf(strength, 0.4, 1.3)
	jiggle_velocity += Vector3(0.6, 0.9, -0.5) * flail_strength

## Vertical jolt (landing, squash of the float): the butt and belly bounce.
func bump(strength: float) -> void:
	jiggle_velocity.y -= 1.4 * clampf(strength, 0.0, 1.5)

func burst() -> void:
	burst_clock = 0.0
	jiggle_velocity += Vector3(0, -0.55, -0.45)

static func spring(value: Variant, velocity: Variant, goal: Variant, stiffness: float, damping: float, delta: float) -> Array:
	velocity += (goal - value) * stiffness * delta - velocity * damping * delta
	return [value + velocity * delta, velocity]

func animate_activity(delta: float, thrusting: bool, stepping: float) -> void:
	thrust_heat = move_toward(thrust_heat, 1.0 if thrusting else 0.0, delta * (5.5 if thrusting else 2.8))
	pose_clock += delta * 12.0
	idle_clock += delta
	burst_clock += delta
	mood_clock += delta
	flail_clock += delta
	var step: float = minf(delta, 1.0 / 30.0)
	charge_color = cheek_color.lerp(HOT, thrust_heat)
	if glow_overlay != null:
		glow_overlay.albedo_color.a = thrust_heat * 0.35
	var walk: float = minf(stepping, 1.0)
	var cheer: bool = mood == "cheer"
	var panic: bool = mood == "panic"
	# Squash and stretch per burst: quick crouch, then a springy lift.
	var length: float = maxf(FartConfig.current.squash_time, 0.05)
	var squash: float = 0.0
	if burst_clock < length * 1.6:
		squash = exp(-burst_clock / length * 3.0) * cos(burst_clock / length * PI * 1.6)
	var hop: float = absf(sin(mood_clock * 6.5 + phase)) if cheer else 0.0
	var stretch_y: float = 1.0 - 0.20 * squash - 0.04 * thrust_heat + 0.05 * hop
	var stretch_xz: float = 1.0 / sqrt(maxf(stretch_y, 0.5))
	pose_root.scale = Vector3(stretch_xz, stretch_y, stretch_xz)
	# Lean spring (slightly under-damped, so the body overshoots and settles).
	var lean_goal: Vector2 = Vector2(clampf(float_lean.x * 0.045, -0.34, 0.34), clampf(-float_lean.y * 0.045, -0.34, 0.34))
	if panic:
		lean_goal += Vector2(sin(mood_clock * 13.0 + phase) * 0.14, sin(mood_clock * 17.0) * 0.16)
	var previous_velocity: Vector2 = lean_velocity
	var lean_state: Array = spring(lean, lean_velocity, lean_goal, 75.0, 8.5, step)
	lean = lean_state[0]
	lean_velocity = lean_state[1]
	# Soft parts lag behind: a loose spring fed by lean changes, bursts, bumps and flails.
	var lean_kick: Vector2 = (lean_velocity - previous_velocity) * 0.06
	jiggle_velocity += Vector3(lean_kick.y, 0.0, -lean_kick.x)
	var jiggle_state: Array = spring(jiggle, jiggle_velocity, Vector3.ZERO, 260.0, 4.6, step)
	jiggle = (jiggle_state[0] as Vector3).limit_length(0.14)
	jiggle_velocity = jiggle_state[1]
	pose_root.position.y = sin(idle_clock * 2.3 + phase) * 0.025 + absf(sin(pose_clock)) * walk * 0.05 + hop * 0.30
	pose_root.rotation.x = lean.x + sin(idle_clock * 1.7 + phase) * 0.025
	pose_root.rotation.z = lean.y + sin(pose_clock) * walk * 0.07 + sin(idle_clock * 1.3 + phase) * 0.02
	# Strain: sit up and push while farting; throw the chest back when cheering.
	body_root.rotation.x = -thrust_heat * 0.18 - (0.20 if cheer else 0.0)
	animate_arms(step, cheer, panic)
	animate_face(delta, cheer, panic, length)
	if body_material != null:
		body_material.set_shader_parameter("butt_tint", charge_color)
		body_material.set_shader_parameter("butt_jiggle", jiggle)
		body_material.set_shader_parameter("butt_clench", maxf(squash, 0.0) * 0.14 + thrust_heat * 0.03)
		body_material.set_shader_parameter("belly_jiggle", -jiggle * 0.6 + Vector3(0, 0, sin(idle_clock * 2.2 + phase) * 0.012))
		body_material.set_shader_parameter("arm_left", Vector2(arms.x, arms.y))
		body_material.set_shader_parameter("arm_right", Vector2(arms.z, arms.w))
		var wag: float = sin(idle_clock * 3.0 + phase) * 0.25 + thrust_heat * sin(idle_clock * 14.0) * 0.35
		if cheer or panic:
			wag = sin(mood_clock * (12.0 if cheer else 20.0)) * 0.6
		body_material.set_shader_parameter("tail_wag", wag)

## Arm angles for the shader (raise sideways, swing forward), eased so mood changes never snap.
func animate_arms(step: float, cheer: bool, panic: bool) -> void:
	var goal: Vector4 = Vector4.ZERO
	var t: float = mood_clock
	if cheer:
		goal = Vector4(2.3 + sin(t * 9.0) * 0.25, 0.6 + sin(t * 9.0 + 1.0) * 0.2, 2.3 + sin(t * 9.0 + 2.2) * 0.25, 0.6 + sin(t * 9.0 + 3.0) * 0.2)
	elif panic:
		goal = Vector4(1.5 + sin(t * 19.0) * 0.7, sin(t * 15.0) * 0.8, 1.5 + sin(t * 19.0 + PI) * 0.7, sin(t * 15.0 + PI) * 0.8)
	elif flail_clock < 1.8:
		var decay: float = exp(-flail_clock * 2.6) * flail_strength
		goal = Vector4(decay * (1.3 + sin(flail_clock * 21.0) * 0.6), decay * sin(flail_clock * 17.0) * 0.9,
			decay * (1.3 + sin(flail_clock * 21.0 + 2.0) * 0.6), decay * sin(flail_clock * 17.0 + 2.5) * 0.9)
	else:
		goal = Vector4(-0.05, 0.0, -0.05, 0.0) * thrust_heat
	arms = arms.lerp(goal, 1.0 - exp(-18.0 * step))

func animate_face(delta: float, cheer: bool, panic: bool, length: float) -> void:
	look_timer -= delta
	if look_timer <= 0.0:
		look_timer = rng.randf_range(1.2, 3.4)
		look_target = Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.10, 0.16))
	var straining: bool = (thrust_heat > 0.45 or burst_clock < length) and not cheer and not panic
	var aim: Vector2 = Vector2(0.0, 0.24) if straining else look_target
	if cheer:
		aim = Vector2(sin(mood_clock * 3.0) * 0.2, 0.30)
	elif panic:
		aim = Vector2(sin(mood_clock * 9.0) * 0.5, 0.34)
	look = look.lerp(aim, 1.0 - exp(-6.0 * delta))
	if head_root == null:
		return
	var shake: float = sin(mood_clock * 25.0) * 0.12 if panic else 0.0
	head_root.rotation = Vector3(-look.y, look.x, sin(idle_clock * 1.1 + phase) * 0.04 + shake)
	blink_timer -= delta
	blink_clock += delta
	if blink_timer <= 0.0:
		blink_timer = rng.randf_range(1.8, 4.6)
		blink_clock = 0.0
	var open: float = 0.12 if blink_clock < 0.11 and not panic else 1.0
	var wide: float = 1.28 if panic else 1.0
	eyes_root.scale = Vector3(wide, wide * open, wide)
	eyes_root.visible = not straining and not cheer
	squint_root.visible = straining
	happy_root.visible = cheer
