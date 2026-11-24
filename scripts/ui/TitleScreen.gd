extends "res://scripts/Screen.gd"

func _ready() -> void:
	super._ready()
	# Release templates ignore the editor's --script option. This explicit flag
	# runs the same acceptance check from an embedded, standalone release pack.
	if "--build-check" in OS.get_cmdline_user_args() and not get_tree().root.has_node("BuildCheck"):
		var checker: Node = load("res://scripts/BuildCheck.gd").new()
		checker.name = "BuildCheck"
		get_tree().root.add_child.call_deferred(checker)
	if preload("res://scripts/AndroidCheck.gd").requested() and not get_tree().root.has_node("AndroidCheck"):
		var android_check: Node = load("res://scripts/AndroidCheck.gd").new()
		android_check.name = "AndroidCheck"
		get_tree().root.add_child.call_deferred(android_check)

func build_menu() -> void:
	content.add_child(label("TOOT TUBES", 72, "title"))
	content.add_child(label("One ring. Four friends. Reach the summit together."))
	build_preview(360)
	var profiles: Array[Dictionary] = CrewData.sanitize_profiles(GameState.local_profiles)
	var crew: Array[Dictionary] = []
	for seat: int in range(4):
		profiles[seat] = AvatarData.sanitize(profiles[seat])
		crew.append(CrewData.make_slot("local", seat))
	model.configure(profiles, crew, clampi(GameState.leader_profile, 0, 3))
	content.add_child(label("Play solo, or with 2-4 friends on the same Wi-Fi", 0, "caption"))
	button("Tap to start", start, content, "primary")
	button("Exit", back, content, "ghost")
