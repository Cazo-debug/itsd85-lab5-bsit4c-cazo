extends GutHookScript

# Test fixtures can leave music queued in the real audio server. Retire those
# commands before GUT exits; do not modify assertions, results or exit codes.
func run() -> void:
	var tree: SceneTree = gut.get_tree()
	await tree.process_frame
	tree.root.get_node("Audio").stop_all()
	await tree.create_timer(0.12, true, false, true).timeout
